#!/usr/bin/env python3
"""Checklist pattern 7 (docs/VV.md 3i): a proven fallback hides the named algorithm.

Finds candidate fallback calls in library code: a call statement to a
simpler sort / search / recompute routine (names *_Finish, *_Fallback,
Bubble_*, Insertion_Pass / Insertion_Sort / Insertion_Finish, Linear_*)
that is the last statement of a subprogram body after other work, or a
Linear_* call in a body that also calls Binary_*. Each candidate is tested
by removal: in a scratch copy the call is replaced by `null;` and the
folder's tests are built and run (make test). For sort folders with the
common `procedure Sort (A : in out Element_Array)` interface and no own
checks, the sweep's property check (nondecreasing + occurrence counts, from
sorting/SPARK4/Ada-SPARK-Merge-Sort/own_checks.adb) is added to the scratch
copy, so a weak original test cannot hide a broken phase.

Verdicts:
  phase sorts/works alone   tests still pass without the call: the named
                            phase does the work, but the proof and the tests
                            only ever certified the fallback (masked)
  PHASE BROKEN WITHOUT IT   tests fail without the call: the named phase is
                            wrong or incomplete; output correct only via the
                            fallback (finding)
  not built                 the scratch copy does not build

usage: sweep_fallback.py [-j 6] [--out tools/vv/sweep_fallback.csv]
"""
import argparse, csv, os, re, shutil, subprocess, tempfile
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FALL = re.compile(r'^(\s*)(\w*_Finish|\w*_Fallback|Bubble_\w+|Insertion_(?:Pass|Sort|Finish)|Linear_\w+)\s*(\([^;]*\))?\s*;', re.I)
TESTNAME = re.compile(r'^(tests?|own_checks|main|demo)', re.I)
PROP = os.path.join(ROOT, 'sorting/SPARK4/Ada-SPARK-Merge-Sort/own_checks.adb')

def strip(l):
    return l.split('--')[0]

def candidates():
    out = []
    for d, dirs, fs in os.walk(ROOT):
        dirs[:] = [x for x in dirs if x not in ('.git', 'obj', 'bin', 'gnatprove', 'tests', 'tools', 'vv', 'docs')]
        for f in sorted(fs):
            if not f.endswith('.adb') or TESTNAME.match(f):
                continue
            p = os.path.join(d, f); lines = open(p, errors='replace').read().split('\n')
            for i, l in enumerate(lines):
                m = FALL.match(strip(l))
                if not m:
                    continue
                # body that contains this line: nearest preceding 'procedure|function X ... is'
                j = i
                while j >= 0 and not re.match(r'^\s*(procedure|function)\s+\w+', lines[j], re.I):
                    j -= 1
                name = re.match(r'^\s*(?:procedure|function)\s+(\w+)', lines[j], re.I).group(1) if j >= 0 else '?'
                if name.lower() == m.group(2).lower():
                    continue
                # last statement before 'end Name;' (ignoring blanks, comments, pragmas, end if/loop)?
                k = i + 1; last = True
                while k < len(lines):
                    s = strip(lines[k]).strip()
                    if re.match(r'end\s+' + re.escape(name) + r'\s*;', s, re.I):
                        break
                    if s and not re.match(r'(pragma\b|end\s+(if|loop)\s*;|end\s*;|null\s*;|return\s*;)', s, re.I):
                        last = False; break
                    k += 1
                body = '\n'.join(strip(x) for x in lines[j:k])
                calls_before = len(re.findall(r'^\s*\w+\s*\(', '\n'.join(strip(x) for x in lines[j + 1:i]), re.M))
                lin_after_bin = m.group(2).lower().startswith('linear') and re.search(r'\bBinary_\w+\s*\(', body, re.I)
                if (last and calls_before > 0) or lin_after_bin:
                    folder = os.path.relpath(d, ROOT)
                    while folder.count('/') > 2:
                        folder = os.path.dirname(folder)
                    out.append(dict(folder=folder, file=os.path.relpath(p, os.path.join(ROOT, folder)), line=i + 1,
                                    caller=name, call=m.group(2)))
    return out

def make_test(w):
    try:
        r = subprocess.run(['make', 'test'], cwd=w, capture_output=True, text=True, timeout=180)
    except subprocess.TimeoutExpired:
        return 'timeout', ''
    out = r.stdout + r.stderr
    if re.search(r'compilation phase failed|cannot generate code|error:', out) and 'raised' not in out:
        return 'not built', out
    if r.returncode != 0 or re.search(r'^\s*FAIL|raised ', out, re.M):
        return 'fail', out
    return 'pass', out

def first_problem(out):
    return next((l.strip() for l in out.split('\n') if re.search(r'raised|FAIL:|error:', l)), '')[:160]

def add_checks(w):
    """Add the generic Sort property check (sorted + same multiset) when the
    folder has no own checks.  Returns True when added."""
    spec = ' '.join(open(os.path.join(w, f), errors='replace').read() for f in os.listdir(w) if f.endswith('.ads'))
    pkg = re.search(r'^\s*package\s+(\w+)', spec, re.M)
    if (os.path.exists(os.path.join(w, 'own_checks.adb')) or not pkg
            or not re.search(r'procedure\s+Sort\s*\(\s*A\s*:\s*in\s+out\s+Element_Array\s*\)', spec)
            or not os.path.exists(os.path.join(w, 'tests.adb'))):
        return False
    t = open(os.path.join(w, 'tests.adb')).read()
    t = re.sub(r'^(with\s+' + pkg.group(1) + r'\b[^\n]*)$', r'\1\nwith Own_Checks;', t, count=1, flags=re.M)
    if 'with Own_Checks' not in t:
        return False
    open(os.path.join(w, 'own_checks.adb'), 'w').write(open(PROP).read().replace('Merge_Sort', pkg.group(1)))
    i = t.rindex('end Tests;')
    open(os.path.join(w, 'tests.adb'), 'w').write(t[:i] + '   Own_Checks;\n' + t[i:])
    return True

def run(c):
    """Baseline first (unmodified code, with the added property check if
    any); the added check is dropped when the unmodified code does not
    pass it (e.g. its inputs break the Sort precondition or the element
    range), so a verdict always compares like with like."""
    src = os.path.join(ROOT, c['folder'])
    w = tempfile.mkdtemp(prefix='fallback_')
    try:
        def fresh(with_checks):
            shutil.rmtree(w, ignore_errors=True)
            shutil.copytree(src, w, ignore=shutil.ignore_patterns('obj', 'bin', 'gnatprove'))
            return add_checks(w) if with_checks else False
        added = fresh(True)
        checks = 'sweep property check added' if added else 'existing tests'
        if added:
            b, out = make_test(w)
            if b != 'pass':
                fresh(False)
                checks = 'existing tests (sweep check rejected by unmodified code: ' + first_problem(out)[:70] + ')'
        b, out = make_test(w)
        if b != 'pass':
            return dict(c, verdict='baseline fails', detail=first_problem(out), checks=checks)
        p = os.path.join(w, c['file']); L = open(p, errors='replace').read().split('\n')
        m = FALL.match(strip(L[c['line'] - 1]))
        L[c['line'] - 1] = m.group(1) + 'null;  --  fallback removed (sweep_fallback.py)'
        open(p, 'w').write('\n'.join(L))
        v, out = make_test(w)
        v = {'pass': 'phase works alone (masked)', 'fail': 'PHASE BROKEN WITHOUT IT',
             'timeout': 'PHASE BROKEN WITHOUT IT (timeout)', 'not built': 'not built'}[v]
        return dict(c, verdict=v, detail=first_problem(out), checks=checks)
    finally:
        shutil.rmtree(w, ignore_errors=True)

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('-j', type=int, default=6)
    ap.add_argument('--out', default=os.path.join(ROOT, 'tools/vv/sweep_fallback.csv')); a = ap.parse_args()
    cs = candidates()
    with ThreadPoolExecutor(a.j) as ex:
        rows = list(ex.map(run, cs))
    rows.sort(key=lambda r: (r['verdict'], r['folder']))
    with open(a.out, 'w', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=['folder', 'file', 'line', 'caller', 'call', 'verdict', 'checks', 'detail'])
        w.writeheader(); w.writerows(rows)
    for r in rows:
        print(f"{r['verdict']:32s} {r['folder']} {r['caller']} -> {r['call']} {r['detail'][:80]}")
    print(len(rows), 'candidates')

if __name__ == '__main__':
    main()
