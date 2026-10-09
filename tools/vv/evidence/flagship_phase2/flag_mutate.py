#!/usr/bin/env python3
"""sweep_mutate.py with timeouts reported separately (not counted as kills)
and a per-subprogram breakdown of the detail rows."""
import sys, os, re, subprocess, csv
sys.path.insert(0, '/workspace/aa-flag/tools/vv')
import sweep_mutate as sm
def run_tests(work):
    main = 'tests.adb'
    os.makedirs(os.path.join(work, 'obj'), exist_ok=True)
    b = subprocess.run([sm.GNATMAKE, '-q', '-gnat2022', '-gnata', '-D', 'obj', main, '-o', 'tbin'], cwd=work, capture_output=True, text=True)
    if b.returncode != 0: return 'stillborn'
    try:
        r = subprocess.run(['./tbin'], cwd=work, capture_output=True, text=True, timeout=60)
    except subprocess.TimeoutExpired:
        return 'timeout'
    if r.returncode != 0 or sm.UNHANDLED.search(r.stdout + r.stderr): return 'killed'
    return 'survived'
sm.run_tests = run_tests
if __name__ == '__main__':
    sm.main()
