#!/usr/bin/env python3
"""Mutation run with the strict scoring rule (docs/VV.md 3i).

Same sites, sampling and output files as tools/vv/sweep_mutate.py (which
this imports and does not change), but a mutant counts as killed ONLY on a
non-zero exit status or a FAIL line in the test output.  A run that hits
the 30 s limit is recorded as `timeout` and is left out of the score (the
90% bar is killed / (killed + survived)); an exception message printed by
a test that still exits 0 does not count.

--control replaces the folder's test main by an always-pass dummy
(`procedure Tests is begin null; end Tests;`).  A sound scorer must give
0 killed there; the run stops with exit status 3 otherwise.

usage: sweep_mutate_strict.py FOLDER... [--max N] [-j N] [--out X.csv] [--control]
"""
import csv, os, re, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sweep_mutate as sm

FAIL = re.compile(r'^\s*FAIL|\b[1-9]\d* FAIL', re.M)
CONTROL = '--control' in sys.argv
if CONTROL:
    sys.argv.remove('--control')

def run_tests(work):
    main = next((m for m in ('tests.adb', 'tests/main.adb', 'src/tests.adb') if os.path.exists(os.path.join(work, m))), None)
    if not main:
        return 'no tests'
    if CONTROL:
        open(os.path.join(work, main), 'w').write('procedure Tests is\nbegin\n   null;\nend Tests;\n')
    os.makedirs(os.path.join(work, 'obj'), exist_ok=True)
    inc = [f'-I{d}' for d in ('src', 'tests') if os.path.isdir(os.path.join(work, d))]
    b = subprocess.run([sm.GNATMAKE, '-q', '-gnat2022', '-gnata', *inc, '-D', 'obj', main, '-o', 'tbin'],
                       cwd=work, capture_output=True, text=True)
    if b.returncode != 0:
        return 'stillborn'
    try:
        r = subprocess.run(['./tbin'], cwd=work, capture_output=True, text=True, timeout=30)
    except subprocess.TimeoutExpired:
        return 'timeout'
    if r.returncode != 0 or FAIL.search(r.stdout + r.stderr):
        return 'killed'
    return 'survived'

sm.run_tests = run_tests

if __name__ == '__main__':
    out = next((sys.argv[i + 1] for i, x in enumerate(sys.argv) if x == '--out'), '/tmp/sweep_mut.csv')
    sm.main()
    det = out.replace('.csv', '_detail.csv')
    killed = 0
    if os.path.exists(det):
        t = {}
        for r in csv.DictReader(open(det)):
            t.setdefault(r['folder'], {}).setdefault(r['result'], 0)
            t[r['folder']][r['result']] += 1
        for f, c in t.items():
            killed += c.get('killed', 0)
            print(f"{f:60s} timeouts={c.get('timeout', 0)} (not counted)")
    if CONTROL:
        print('CONTROL', 'ok (always-pass dummy kills nothing)' if killed == 0 else f'BROKEN: dummy killed {killed}')
        sys.exit(0 if killed == 0 else 3)
