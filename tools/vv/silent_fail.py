#!/usr/bin/env python3
"""Silent-failure scan (docs/VV.md 3i): does a failing test make `make test` fail?

For every folder, in a scratch copy, run the standard `make test` once with GNAT 14
(folders without a Makefile: gnatmake -gnat2022 on the test main, run it) and record
the exit status and every output line with the word FAIL / FAILED / FAILS / FAILURE(S)
(any case). Lines reporting zero failures ("FAIL: 0", "0 failed", "failures: 0") and
lines that are clearly expected-failure labels ("expected to fail", "should fail",
"must fail", "fail-safe", quoted "FAIL" text in a legend) are not hits. A run with
exit status 0 and at least one hit is a silent failure (failure printed, status 0).

Static check, no run needed: the test main (and own_checks) use pragma Assert while the
standard build has no -gnata (Makefile, .gpr, .adc) and no Assertion_Policy (Check):
the asserts are then ignored. assert_only=yes when pragma Assert is the only failure
signal in the test main (no Set_Exit_Status, OS_Exit, raise, or FAIL output).

Columns: folder, make_rc, fail_hits, first_hit, assert_unchecked, assert_only,
silent_fail (yes when status 0 with hits, or assert_only), note.

usage: silent_fail.py [--from-file ids.txt] [-j N] [--out tools/vv/silent_fail.csv] [--timeout S]
"""
import argparse, csv, os, re, shutil, subprocess, tempfile
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MAINS = ('tests.adb', 'tests/main.adb', 'src/tests.adb')
WORD = re.compile(r'\bFAIL(ED|S|URES?)?\b', re.I)
ZERO = re.compile(r'FAIL(ED|S|URES?)?\s*[:=]?\s*0\b|\b0\s+(tests?\s+)?FAIL|\bno\s+FAIL|FAILURE DISPROVED'
                  r'|FAIL(ED|S|URES?)?\s*[:=]?\s*none\b', re.I)
LABEL = re.compile(r'expect\w*\s+(to\s+)?fail|should\s+fail|must\s+fail|fail[- ]?safe|fail[- ]?fast'
                   r'|fails?\s+as\s+expected|expected\s+fail|correctly\s+fail|"FAIL"|\'FAIL\'', re.I)
TOOL = re.compile(r'^(gprbuild|gnatmake|gnatbind|gnatlink|make)\b|^\S+\.ad[sb]:\d+:\d+: ', re.I)

def env14():
    e = dict(os.environ)
    alr = os.path.expanduser('~/.local/alr')
    extra = [os.path.join(alr, d, 'bin') for d in sorted(os.listdir(alr)) if d.startswith('gprbuild')] if os.path.isdir(alr) else []
    e['PATH'] = ':'.join(['/usr/bin', '/bin'] + extra)
    return e

def hits(out):
    h = []
    for l in out.splitlines():
        if WORD.search(l) and not ZERO.search(l) and not LABEL.search(l) and not TOOL.search(l.strip()):
            h.append(l.strip())
    return h

def strip_comments(t):
    return '\n'.join(l.split('--')[0] for l in t.splitlines())

def static(src):
    test_files = [os.path.join(src, m) for m in MAINS + ('own_checks.adb',) if os.path.exists(os.path.join(src, m))]
    asserts = 0; only = False
    for f in test_files:
        t = strip_comments(open(f, errors='replace').read())
        n = len(re.findall(r'pragma\s+Assert\b', t, re.I))
        asserts += n
        if f.endswith(MAINS) and n and not re.search(r'Set_Exit_Status|OS_Exit|\braise\b|FAIL', t, re.I):
            only = True
    if not asserts:
        return 0, False
    cfg = ''
    for dp, dn, fn in os.walk(src):
        dn[:] = [d for d in dn if d not in ('obj', 'bin', 'gnatprove')]
        for f in fn:
            p = os.path.join(dp, f)
            if f == 'Makefile' or f.endswith(('.gpr', '.adc')):
                cfg += strip_comments(open(p, errors='replace').read().replace('#', '--')) + '\n'
            elif f.endswith(('.adb', '.ads')):
                t = strip_comments(open(p, errors='replace').read())
                if re.search(r'Assertion_Policy\s*\(\s*(Assert\s*=>\s*)?Check', t, re.I):
                    cfg += ' -gnata '
    if re.search(r'-gnata\b', cfg) or re.search(r'Assertion_Policy\s*\(\s*(Assert\s*=>\s*)?Check', cfg, re.I):
        return 0, False
    return asserts, only

def run(fid, work_root, timeout):
    src = os.path.join(ROOT, fid)
    work = tempfile.mkdtemp(prefix=fid.replace('/', '_') + '_', dir=work_root)
    rc, out, note = '', '', ''
    try:
        shutil.copytree(src, work, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns('obj', 'bin', 'gnatprove', '*.o', '*.ali'))
        e = env14()
        try:
            if os.path.exists(os.path.join(work, 'Makefile')):
                r = subprocess.run(['make', 'test'], cwd=work, env=e, capture_output=True, text=True,
                                   timeout=timeout, errors='replace')
                rc, out = r.returncode, r.stdout + r.stderr
            else:
                m = next((m for m in MAINS if os.path.exists(os.path.join(work, m))), None)
                if not m:
                    note = 'no Makefile and no test main'
                else:
                    inc = [f'-I{d}' for d in ('src', 'tests') if os.path.isdir(os.path.join(work, d))]
                    b = subprocess.run(['gnatmake', '-q', '-gnat2022'] + inc + ['-o', 'sf_test', m], cwd=work, env=e,
                                       capture_output=True, text=True, timeout=timeout, errors='replace')
                    if b.returncode:
                        rc, out, note = b.returncode, b.stdout + b.stderr, 'test main does not build'
                    else:
                        r = subprocess.run(['./sf_test'], cwd=work, env=e, capture_output=True, text=True,
                                           timeout=timeout, errors='replace')
                        rc, out, note = r.returncode, r.stdout + r.stderr, 'no Makefile: gnatmake test main'
        except subprocess.TimeoutExpired:
            rc, note = 'timeout', 'timeout'
    finally:
        shutil.rmtree(work, ignore_errors=True)
    h = hits(out)
    au, only = static(src)
    silent = (rc == 0 and bool(h)) or only
    return dict(folder=fid, make_rc=rc, fail_hits=len(h), first_hit=(h[0] if h else '')[:160],
                assert_unchecked=au, assert_only='yes' if only else 'no',
                silent_fail='yes' if silent else 'no', note=note)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--from-file'); ap.add_argument('-j', type=int, default=4)
    ap.add_argument('--out', default=os.path.join(ROOT, 'tools/vv/silent_fail.csv'))
    ap.add_argument('--timeout', type=int, default=300); ap.add_argument('--work')
    a = ap.parse_args()
    if a.from_file:
        ids = [l.strip() for l in open(a.from_file) if l.strip()]
    else:
        ids = sorted(r['folder'] for r in csv.DictReader(open(os.path.join(ROOT, 'PROOFS.csv'))))
    wr = a.work or tempfile.mkdtemp(prefix='silent_fail_')
    os.makedirs(wr, exist_ok=True)
    with ThreadPoolExecutor(a.j) as ex:
        rows = list(ex.map(lambda f: run(f, wr, a.timeout), ids))
    with open(a.out, 'w', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()), lineterminator='\n')
        w.writeheader(); w.writerows(rows)
    print(len(rows), 'folders;', sum(r['silent_fail'] == 'yes' for r in rows), 'silent_fail;',
          sum(r['assert_only'] == 'yes' for r in rows), 'assert_only;',
          sum(r['fail_hits'] > 0 and r['make_rc'] == 0 for r in rows), 'status 0 with FAIL hits')

if __name__ == '__main__':
    main()
