#!/usr/bin/env python3
"""All-checks crash run (docs/VV.md): build every plain-Ada folder's test main and its
demo/main programs in a scratch copy with all run-time checks on
(-gnat2022 -gnata -gnato -gnatVa -g, GNAT 14) and run each with a timeout.
The folder's own files and Makefiles are not changed.

A program that does not build as Ada 2022 is retried as Ada 2012 with the same
checks (column built). A run stopped by a failed precondition is repeated with
preconditions ignored and every other check on (column pre_ignored): tests that
pass then only violated a precondition on purpose to reach a defensive raise.

Result per program: ok, Constraint_Error, Assertion_Error, Storage_Error,
Program_Error, other exception, timeout, test failure (non-zero exit or a
FAIL line without an exception), not built.

usage: checks_on.py [--from-file ids.txt] [-j N] [--out tools/vv/checks_on.csv] [--work DIR]
"""
import argparse, csv, os, re, shutil, subprocess, tempfile
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GNATMAKE = os.environ.get('VV_GNATMAKE', 'gnatmake')
FLAGS = ['-gnat2022', '-gnata', '-gnato', '-gnatVa', '-g']
MAINS = ('tests.adb', 'tests/main.adb', 'src/tests.adb')
EXC = {'CONSTRAINT_ERROR': 'Constraint_Error', 'ASSERTION_ERROR': 'Assertion_Error',
       'STORAGE_ERROR': 'Storage_Error', 'PROGRAM_ERROR': 'Program_Error'}

def gpr_mains(folder):
    out = []
    for g in os.listdir(folder):
        if g.endswith('.gpr'):
            t = open(os.path.join(folder, g), errors='replace').read()
            for m in re.finditer(r'for\s+Main\s+use\s*\(([^)]*)\)', t, re.I):
                out += re.findall(r'"([^"]+)"', m.group(1))
    return out

def find(folder, name):
    for d in ('', 'src', 'tests'):
        p = os.path.join(d, name)
        if os.path.exists(os.path.join(folder, p)):
            return p
    return None

def classify(rc, out):
    m = re.search(r'^raised ([A-Z][A-Z0-9_.]*)(?: : (.*))?$', out, re.M)
    if m:
        k = m.group(1).split('.')[-1]
        return EXC.get(k, 'other exception'), (m.group(1) + ' : ' + (m.group(2) or '')).strip()[:200]
    # a summary line such as "FAIL: 0" or "FAIL:  0" reports zero failures
    fails = [l for l in out.splitlines() if re.search(r'^\s*FAIL|\b[1-9]\d* FAIL', l)
             and not re.match(r'^\s*FAIL(ED|S)?\s*[:=]?\s*0\s*$', l)]
    if rc != 0 or fails:
        line = fails[0] if fails else (out.strip().splitlines()[-1] if out.strip() else '')
        return 'test failure', ('rc=%d ' % rc + line.strip())[:200]
    return 'ok', ''

def run_prog(work, main, timeout, pre_ignore=False):
    exe = 'co_' + re.sub(r'\W', '_', main)
    inc = [f'-I{d}' for d in ('src', 'tests') if os.path.isdir(os.path.join(work, d))]
    adc = []
    if pre_ignore:   # second pass: preconditions off, every other check still on
        open(os.path.join(work, 'co.adc'), 'w').write("pragma Assertion_Policy (Pre => Ignore, Pre'Class => Ignore);\n")
        adc = ['-gnatec=' + os.path.join(work, 'co.adc')]
    built = 'yes'
    for flags in (FLAGS, [f for f in FLAGS if f != '-gnat2022']):   # Ada 2012 fallback (e.g. Append ambiguity)
        b = subprocess.run([GNATMAKE, '-q', '-f', *flags, *adc, *inc, '-D', 'obj', main, '-o', exe],
                           cwd=work, capture_output=True, text=True, errors='replace')
        if b.returncode == 0:
            break
        if flags is FLAGS:
            err = next((l for l in (b.stdout + b.stderr).splitlines() if 'error' in l), (b.stdout + b.stderr).strip()[:150])
        built = 'yes (Ada 2012 fallback)'
    if b.returncode != 0:
        return 'no', 'not built', err[:200]
    try:
        r = subprocess.run(['./' + exe], cwd=work, capture_output=True, text=True, errors='replace',
                           timeout=timeout, stdin=subprocess.DEVNULL)
    except subprocess.TimeoutExpired:
        return 'yes', 'timeout', f'> {timeout} s'
    res, msg = classify(r.returncode, r.stdout + r.stderr)
    return built, res, msg

def check(fid, work_root, timeout):
    src = os.path.join(ROOT, fid)
    progs = []
    t = next((m for m in MAINS if os.path.exists(os.path.join(src, m))), None)
    if t: progs.append(('tests', t))
    for m in gpr_mains(src):
        p = find(src, m)
        if p and p != t and os.path.basename(p) != 'tests.adb':
            progs.append(('main', p))
    rows = []
    if not progs:
        return [dict(folder=fid, program='', kind='', built='', ran='no', result='no tests or main', message='', pre_ignored='')]
    work = tempfile.mkdtemp(prefix=fid.replace('/', '_') + '_', dir=work_root)
    try:
        shutil.copytree(src, work, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns('obj', 'bin', 'gnatprove', '*.o', '*.ali'))
        os.makedirs(os.path.join(work, 'obj'), exist_ok=True)
        for kind, p in progs:
            built, res, msg = run_prog(work, p, timeout)
            pre = ''
            if res == 'Assertion_Error' and 'failed precondition' in msg:
                _, r2, m2 = run_prog(work, p, timeout, pre_ignore=True)
                pre = (r2 + (' : ' + m2 if m2 else ''))[:200]
            rows.append(dict(folder=fid, program=p, kind=kind, built=built,
                             ran='yes' if built != 'no' else 'no', result=res, message=msg, pre_ignored=pre))
    finally:
        shutil.rmtree(work, ignore_errors=True)
    return rows

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--from-file'); ap.add_argument('-j', type=int, default=4)
    ap.add_argument('--out', default=os.path.join(ROOT, 'tools/vv/checks_on.csv'))
    ap.add_argument('--work', default=None); ap.add_argument('--timeout', type=int, default=20)
    a = ap.parse_args()
    if a.from_file:
        ids = [l.strip() for l in open(a.from_file) if l.strip() and not l.startswith('#')]
    else:
        rows = csv.DictReader(open(os.path.join(ROOT, 'PROOFS.csv')))
        ids = [r['folder'] for r in rows if r['level'] == 'Ada' and not r['duplicate_of']]
    work_root = a.work or tempfile.mkdtemp(prefix='checks_on_')
    os.makedirs(work_root, exist_ok=True)
    out = []
    with ThreadPoolExecutor(a.j) as ex:
        for rows in ex.map(lambda f: check(f, work_root, a.timeout), ids):
            for r in rows:
                print(f"{r['folder']:60s} {r['kind']:5s} {r['result']:16s} {r['message'][:70]}", flush=True)
            out += rows
    out.sort(key=lambda r: (r['folder'], r['kind'] != 'tests', r['program']))
    with open(a.out, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=['folder', 'program', 'kind', 'built', 'ran', 'result', 'message', 'pre_ignored'], lineterminator='\n')
        w.writeheader(); w.writerows(out)
    print('wrote', a.out)

if __name__ == '__main__':
    main()
