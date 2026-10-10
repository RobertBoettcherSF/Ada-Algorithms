#!/usr/bin/env python3
"""Control for the per-run test timeout used by tools/vv/score138.py (rule v1 timeouts, H186).

score138.py sets sweep_mutate.TIMEOUT from --timeout. It imports sweep_topup_B, which imports
sweep_mutate_strict, which replaces sweep_mutate.run_tests; the harness must still honour TIMEOUT.
A throw-away folder whose test sleeps 3 s must give 'timeout' at TIMEOUT = 1 and 'survived' at
TIMEOUT = 20; a test that fails at once must give 'killed'.
  python3 tools/vv/test_score138_timeout.py      (exit 0 = all cases as expected)
"""
import os, shutil, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import score138   # noqa: F401  (same import chain as the real run)
import sweep_mutate as sm

SLOW = 'with Ada.Text_IO;\nprocedure Tests is\nbegin\n   delay 3.0;\n   Ada.Text_IO.Put_Line ("PASS");\nend Tests;\n'
FAILS = 'procedure Tests is\nbegin\n   raise Program_Error;\nend Tests;\n'

def case(src, timeout):
    d = tempfile.mkdtemp(prefix='ts138_')
    try:
        open(os.path.join(d, 'tests.adb'), 'w').write(src)
        sm.TIMEOUT = timeout
        return sm.run_tests(d)
    finally:
        shutil.rmtree(d, ignore_errors=True)

def main():
    bad = 0
    for name, src, t, want in (('slow test, timeout 1 s', SLOW, 1, 'timeout'),
                               ('slow test, timeout 20 s', SLOW, 20, 'survived'),
                               ('failing test, timeout 20 s', FAILS, 20, 'killed')):
        got = case(src, t)
        ok = got == want
        bad += not ok
        print(('ok  ' if ok else 'FAIL') + f' {name}: {got}' + ('' if ok else f' (expected {want})'))
    print(f'{3 - bad}/3 timeout control cases pass')
    return 1 if bad else 0

if __name__ == '__main__':
    sys.exit(main())
