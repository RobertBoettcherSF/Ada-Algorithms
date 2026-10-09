#!/usr/bin/env python3
"""Proof-kill pass for score138.py held survivors (agent-S138).

Each held mutant whose test result is survived or timeout is applied to a cold
copy of the folder (git archive of COMMIT: no obj/, gnatprove/, proof/
session) and proved with the canonical Silver command of
tools/vv/prove_settings.txt, at -j2 (the -j value does not change which VCs
prove within --steps), under nice and RLIMIT_AS 4 GB, wall cap 3600 s:
  gnatprove -P <proof_gpr> -f --mode=silver --level=2 --prover=cvc5,z3,altergo
            --timeout=0 --steps=1000000 --counterexamples=off --report=statistics
            --output=oneline -k -j2
kill_kind=proof: an unproved check (low/medium/high) or an error line.
proved / cap hit / crash: stays a survivor (cap and crash noted).
The unmutated folder is proved first with the same command; if it does not
prove cleanly, no proof kill is counted for that folder.

usage: score138_prove.py HELD_JSON --commit C [--cap 3600]
"""
import argparse, csv, json, os, re, resource, shutil, subprocess, sys, tempfile
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ALR = os.environ.get('AA_ALR_DIR', os.path.expanduser('~/.local/alr'))   # docs/TOOLCHAIN.md
GP = os.path.join(ALR, 'gnatprove_16.1.0_82528bef', 'bin')
GB = next(os.path.join(ALR, d, 'bin') for d in sorted(os.listdir(ALR)) if d.startswith('gprbuild_'))
UNPROVED = re.compile(r':\d+:\d+: (low|medium|high|error)\b|^gnatprove: error', re.M)


def gpr_of(fid):
    for r in csv.DictReader(open(os.path.join(ROOT, 'PROOFS.csv'))):
        if r['folder'] == fid:
            return r['proof_gpr'].replace(' (generated)', '').strip()
    sys.exit('no PROOFS.csv row')


def limit():
    resource.setrlimit(resource.RLIMIT_AS, (4 << 30, 4 << 30))
    os.nice(10)


def prove(fid, commit, edits, cap, tag):
    d = tempfile.mkdtemp(prefix='s138p_')
    subprocess.run(f'git -C {ROOT} archive {commit} {fid} | tar -x -C {d}', shell=True, check=True)
    w = os.path.join(d, fid)
    for rel, ln, c0, c1, rep in edits:
        p = os.path.join(w, rel); L = open(p, errors='replace').read().split('\n')
        L[ln] = L[ln][:c0] + rep + L[ln][c1:]; open(p, 'w').write('\n'.join(L))
    cmd = ['timeout', str(cap), os.path.join(GP, 'gnatprove'), '-P', gpr_of(fid), '-f', '--mode=silver', '--level=2',
           '--prover=cvc5,z3,altergo', '--timeout=0', '--steps=1000000', '--counterexamples=off',
           '--report=statistics', '--output=oneline', '-k', '-j2']
    env = dict(os.environ, PATH=f'{GP}:{GB}:/usr/bin:/bin')
    r = subprocess.run(cmd, cwd=w, env=env, capture_output=True, text=True, errors='replace', preexec_fn=limit)
    out = r.stdout + r.stderr
    shutil.rmtree(d, ignore_errors=True)
    if r.returncode == 124:
        return 'cap', 'wall cap %d s hit' % cap
    if 'GNAT BUG' in out or r.returncode < 0:
        return 'crash', (out.strip().splitlines() or [''])[-1][:200]
    bad = [l for l in out.splitlines() if UNPROVED.search(l)]
    if bad:
        return 'proof_fail', bad[0].strip()[:240]
    if r.returncode != 0:
        return 'crash', (out.strip().splitlines() or [''])[-1][:200]
    m = re.search(r'Total\s*\|?\s*(\d+)', out)
    return 'proved', 'all checks proved'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('held_json'); ap.add_argument('--commit', required=True); ap.add_argument('--cap', type=int, default=3600)
    a = ap.parse_args()
    rec = json.load(open(a.held_json))
    fid = rec['folder']
    v, e = prove(fid, a.commit, [], a.cap, 'base')
    rec['proof_base'] = [v, e]
    print('BASE', v, e, flush=True)
    for m in rec['mutants']:
        if m['result'] not in ('survived', 'timeout'):
            continue
        if v != 'proved':
            m['prove'] = ['not run', 'base does not prove']
            continue
        pv, ev = prove(fid, a.commit, m['edits'], a.cap, '')
        m['prove'] = [pv, ev]
        if pv == 'proof_fail':
            m['result'], m['kill_kind'] = 'killed', 'proof'
        print(m['family'], m['op'], '->', pv, flush=True)
    rec['proof_commit'] = a.commit
    json.dump(rec, open(a.held_json, 'w'), indent=1)


if __name__ == '__main__':
    main()
