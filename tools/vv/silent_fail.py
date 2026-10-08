#!/usr/bin/env python3
"""Silent-failure scan (docs/VV.md 3j): does a failing test make `make test` fail?

For every folder, in a scratch copy, run the standard `make test` once with GNAT 14
(folders without a Makefile: gnatmake -gnat2022 on the test main, run it) and record
the exit status and every output line with the word FAIL or FAILED (any case; "fails",
"failure" are not hits, and neither are lines that start with PASS/OK, which label a
passing check about failure behaviour). Lines reporting zero failures ("FAIL: 0", "0 failed", "failures: 0") and
lines that are clearly expected-failure labels ("expected to fail", "should fail",
"must fail", "fail-safe", quoted "FAIL" text in a legend) are not hits. A run with
exit status 0 and at least one hit is a silent failure (failure printed, status 0).

Static check, no run needed: the test main (and own_checks) use pragma Assert while the
standard build has no -gnata (Makefile, .gpr, .adc) and no Assertion_Policy (Check):
the asserts are then ignored. assert_only=yes when pragma Assert is the only exit-status
signal in the test main (no Set_Exit_Status, OS_Exit or raise). Printing FAIL is not an
exit-status signal.

no_exit_signal=yes (static): the test main prints FAIL text, but nothing in it can set a
non-zero exit status (no Set_Exit_Status, OS_Exit, raise, Ada.Assertions.Assert, and no
checked pragma Assert). Such a harness passes today, but it would hide a failure.

Reviewed hits: tools/vv/silent_fail_reviewed.csv (folder,line,verdict,reason) lists output
lines that were inspected by hand. A line with verdict 'label' (a section header or a
test description that contains the word, not a failed check) is not a hit.

Columns: folder, make_rc, fail_hits, first_hit, assert_unchecked, assert_only,
silent_fail (yes when status 0 with hits, or assert_only), note.

Runs use mutate.run_limited (a timeout kills the whole process group) and GNAT 14 pinned by
path and checked (mutate.require_version). --from-logs reads the logs that
tools/audit/build_folder.sh keeps (AA_WORK/<folder_with_underscores>/mk14.log, mk12.log, r14.log,
r12.log) with the exit codes and compiler versions from its JSON lines instead of rebuilding;
a folder counts once per compiler (columns make_rc / make_rc_12, fail_hits / fail_hits_12).

usage: silent_fail.py [--from-file ids.txt] [-j N] [--out tools/vv/silent_fail.csv] [--timeout S]
       silent_fail.py --from-logs AA_WORK --jsonl build.jsonl [--out ...]
"""
import argparse, csv, json, os, re, shutil, subprocess, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mutate
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MAINS = ('tests.adb', 'tests/main.adb', 'src/tests.adb')
WORD = re.compile(r'\bFAIL(ED)?\b', re.I)
PASSLINE = re.compile(r'^\W*(PASS(ED)?|OK)\b', re.I)
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

REVIEWED = {}
_rv = os.path.join(ROOT, 'tools/vv/silent_fail_reviewed.csv')
if os.path.exists(_rv):
    for _r in csv.DictReader(open(_rv)):
        if _r['verdict'] == 'label':
            REVIEWED.setdefault(_r['folder'], set()).add(_r['line'].strip())

def hits(out, fid=None):
    h = []
    skip = REVIEWED.get(fid, set())
    for l in out.splitlines():
        if l.strip() in skip:
            continue
        if WORD.search(l) and not PASSLINE.search(l.strip()) and not ZERO.search(l) and not LABEL.search(l) and not TOOL.search(l.strip()):
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
        if f.endswith(MAINS) and n and not re.search(r'Set_Exit_Status|OS_Exit|\braise\b', t, re.I):
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

def no_exit_signal(src):
    """The test main prints FAIL text but nothing in it can make the exit status non-zero:
    no Set_Exit_Status, OS_Exit, raise, Ada.Assertions.Assert, and no pragma Assert that the
    build checks."""
    m = next((os.path.join(src, x) for x in MAINS if os.path.exists(os.path.join(src, x))), None)
    if not m:
        return False
    t = strip_comments(open(m, errors='replace').read())
    if not re.search(r'"[^"]*\bFAIL', t, re.I):
        return False
    if re.search(r'Set_Exit_Status|OS_Exit|\braise\b|Ada\.Assertions\.Assert\b', t, re.I):
        return False
    if (re.search(r'use\s+Ada\.Assertions', t, re.I) and re.search(r'^\s*Assert\s*\(', t, re.M)
            and not re.search(r'procedure\s+Assert\b', t, re.I)):
        return False
    if re.search(r'pragma\s+Assert', t, re.I) and not static(src)[0]:
        return False
    return True

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
                r = mutate.run_limited(['make', 'test'], work, timeout, env=e)
                if r is None:
                    raise subprocess.TimeoutExpired('make test', timeout)
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
                        r = mutate.run_limited(['./sf_test'], work, timeout, env=e)
                        if r is None:
                            raise subprocess.TimeoutExpired('sf_test', timeout)
                        rc, out, note = r.returncode, r.stdout + r.stderr, 'no Makefile: gnatmake test main'
        except subprocess.TimeoutExpired:
            rc, note = 'timeout', 'timeout'
    finally:
        shutil.rmtree(work, ignore_errors=True)
    h = hits(out, fid)
    au, only = static(src)
    nx = no_exit_signal(src)
    silent = (rc == 0 and bool(h)) or only or nx
    return dict(folder=fid, make_rc=rc, fail_hits=len(h), first_hit=(h[0] if h else '')[:160],
                assert_unchecked=au, assert_only='yes' if only else 'no', no_exit_signal='yes' if nx else 'no',
                silent_fail='yes' if silent else 'no', note=note)

def from_logs(fid, logs, rec):
    d = os.path.join(logs, fid.replace('/', '_'))
    def rd(n):
        p = os.path.join(d, n)
        return open(p, errors='replace').read() if os.path.exists(p) else ''
    out = {}
    for v in ('14', '12'):
        if rec.get('mk' + v) not in (None, 'NA'):
            rc, txt = rec['mk' + v], rd('mk%s.log' % v)
        else:
            rc, txt = rec.get('r' + v), rd('r%s.log' % v)
        rc = int(rc) if str(rc).lstrip('-').isdigit() else (rc or '')
        out[v] = (rc, hits(txt, fid))
    au, only = static(os.path.join(ROOT, fid))
    nx = no_exit_signal(os.path.join(ROOT, fid))
    (rc14, h14), (rc12, h12) = out['14'], out['12']
    silent = (rc14 == 0 and bool(h14)) or (rc12 == 0 and bool(h12)) or only or nx
    return dict(folder=fid, make_rc=rc14, fail_hits=len(h14), first_hit=((h14 or h12 or [''])[0])[:160],
                assert_unchecked=au, assert_only='yes' if only else 'no', no_exit_signal='yes' if nx else 'no',
                silent_fail='yes' if silent else 'no', note='from build logs',
                make_rc_12=rc12, fail_hits_12=len(h12), compiler_14=rec.get('ver14', ''), compiler_12=rec.get('ver12', ''))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--from-logs'); ap.add_argument('--jsonl')
    ap.add_argument('--from-file'); ap.add_argument('-j', type=int, default=4)
    ap.add_argument('--out', default=os.path.join(ROOT, 'tools/vv/silent_fail.csv'))
    ap.add_argument('--timeout', type=int, default=300); ap.add_argument('--work')
    a = ap.parse_args()
    if a.from_file:
        ids = [l.strip() for l in open(a.from_file) if l.strip()]
    else:
        ids = sorted(r['folder'] for r in csv.DictReader(open(os.path.join(ROOT, 'PROOFS.csv'))))
    if a.from_logs:
        recs = {}
        for l in open(a.jsonl):
            try:
                d = json.loads(l)
            except ValueError:
                continue
            if 'error' not in d and str(d.get('ver14', '')).startswith('GNATMAKE 14.') and str(d.get('ver12', '')).startswith('GNATMAKE 12.'):
                recs[d['id']] = d
        rows = [from_logs(f, a.from_logs, recs[f]) for f in ids if f in recs]
    else:
        ver = mutate.require_version(14, '/usr/bin/gnatmake')
        wr = a.work or tempfile.mkdtemp(prefix='silent_fail_')
        os.makedirs(wr, exist_ok=True)
        with ThreadPoolExecutor(a.j) as ex:
            rows = list(ex.map(lambda f: run(f, wr, a.timeout), ids))
        for r in rows:
            r['compiler_14'] = ver
    with open(a.out, 'w', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()), lineterminator='\n')
        w.writeheader(); w.writerows(rows)
    print(len(rows), 'folders;', sum(r['silent_fail'] == 'yes' for r in rows), 'silent_fail;',
          sum(r['assert_only'] == 'yes' for r in rows), 'assert_only;',
          sum(r['no_exit_signal'] == 'yes' for r in rows), 'no_exit_signal;',
          sum(r['fail_hits'] > 0 and r['make_rc'] == 0 for r in rows), 'status 0 with FAIL hits')

if __name__ == '__main__':
    main()
