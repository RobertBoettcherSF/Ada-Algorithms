#!/usr/bin/env python3
"""Differential testing of Ada/SPARK pairs (see docs/VV.md).

Each pair lives in tools/vv/diff/<Name>/ with
  pair.json            {"ada": folder, "spark": folder, "gen": "array:MINLEN:MAXLEN:LO:HI", "cases": N}
  vv_ada_driver.adb    reads cases from stdin, prints one result line per case (Ada side)
  vv_spark_driver.adb  same protocol, SPARK side
Each case is one line: the count, then the values. Both drivers get the same
seeded inputs; any line that differs (or a crash on one side) is a disagreement.

usage: difftest.py [--seed S] [--cases N] [--out results.csv] [--only NAME ...] [-j JOBS]
"""
import argparse, csv, json, os, random, re, shutil, subprocess, sys, glob, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HERE = os.path.join(ROOT, 'tools', 'vv', 'diff')
GNATMAKE = os.environ.get('VV_GNATMAKE', 'gnatmake')

def gen_cases(spec, n, rng, zero_edge=False):
    kind, mn, mx, lo, hi = spec.split(':')
    mn, mx, lo, hi = int(mn), int(mx), int(lo), int(hi)
    edge = [lo, hi, 0 if lo <= 0 <= hi else lo, lo + 1 if lo < hi else lo, hi - 1 if hi > lo else hi]
    out = []
    for k in range(n):
        ln = rng.randint(mn, mx)
        if k < 50:            # first cases: edge values only
            vals = [rng.choice(edge) for _ in range(ln)]
        elif k % 5 == 0:      # small values exercise special cases
            vals = [rng.randint(lo, min(hi, lo + 20)) for _ in range(ln)]
        else:
            vals = [rng.randint(lo, hi) for _ in range(ln)]
        if zero_edge and k < 4:
            vals = [[0, 0], [0, 7], [7, 0], [1, 1]][k][:ln]
        out.append(' '.join(map(str, [ln] + vals)))
    return out

def build(work, folder, driver):
    src = os.path.join(ROOT, folder)
    os.makedirs(work, exist_ok=True)
    for f in glob.glob(os.path.join(src, '**', '*.ad[sb]'), recursive=True):
        b = os.path.basename(f)
        if b.startswith('test') or b == 'main.adb':
            continue
        shutil.copy(f, work)
    shutil.copy(driver, work)
    main = os.path.basename(driver)
    r = subprocess.run([GNATMAKE, '-q', '-gnat2022', '-gnata', '-O1', main, '-o', 'drv'],
                       cwd=work, capture_output=True, text=True)
    return r.returncode == 0, (r.stdout + r.stderr)[-800:]

def toks(line):
    """Compare outputs token-wise; numbers are split even when 'Image' output glues
    negatives together ("-3-1" == "-3 -1")."""
    return re.findall(r'-?\d+|[^\s\d-]+|-', line)

def run(work, data, timeout=120):
    try:
        r = subprocess.run(['./drv'], cwd=work, input=data, capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout.splitlines(), r.stderr[-400:]
    except subprocess.TimeoutExpired:
        return 124, [], 'timeout'

def run_cases(work, cases, chunk=50):
    """Run cases in chunks of 50; if the driver dies or hangs on a chunk, rerun that
    chunk case by case so one crash does not hide the rest (at most 25 crashes, then stop)."""
    res, crashes = [], 0
    for c0 in range(0, len(cases), chunk):
        part = cases[c0:c0 + chunk]
        if crashes >= 25:
            res += ['CRASH (not run: too many crashes)'] * len(part); crashes += len(part)
            continue
        rc, out, err = run(work, '\n'.join(part) + '\n', timeout=900)
        if rc == 0 and len(out) == len(part):
            res += out
            continue
        for c in part:
            if crashes >= 25:
                res.append('CRASH (not run: too many crashes)'); crashes += 1
                continue
            rc, o, e = run(work, c + '\n', timeout=60)
            if rc != 0 or len(o) != 1:
                res.append('CRASH ' + (e.strip().splitlines() or ['rc=%d' % rc])[-1][:120]); crashes += 1
            else:
                res.append(o[0])
    return res, crashes

def one_pair(name, a):
    p = json.load(open(os.path.join(HERE, name, 'pair.json')))
    n = a.cases or p.get('cases', 1000)
    rng = random.Random(f"{a.seed}:{name}")
    cases = gen_cases(p['gen'], n, rng, p.get('zero_edge', False))
    row = dict(pair=name, ada=p['ada'], spark=p['spark'], seed=a.seed, cases=n, result='', disagree=0,
               crash_ada=0, crash_spark=0, first_case='', ada_out='', spark_out='')
    shutil.rmtree(os.path.join(a.work, name), ignore_errors=True)
    outs = {}
    for side in ('ada', 'spark'):
        w = os.path.join(a.work, name, side)
        ok, log = build(w, p[side], os.path.join(HERE, name, f'vv_{side}_driver.adb'))
        if not ok:
            row['result'] = f'driver build failed ({side})'; row['first_case'] = log.replace('\n', ' | ')[:300]
            break
        outs[side], row['crash_' + side] = run_cases(w, cases)
    if not row['result']:
        bad = [i for i in range(n) if toks(outs['ada'][i]) != toks(outs['spark'][i])]
        row['disagree'] = len(bad)
        row['result'] = 'agree' if not bad else ('DISAGREE (known)' if p.get('known_difference') else 'DISAGREE')
        if bad:
            i = bad[0]
            row['first_case'] = cases[i][:200]; row['ada_out'] = outs['ada'][i][:200]; row['spark_out'] = outs['spark'][i][:200]
    print(f"{name:34s} {row['result']:10s} disagree={row['disagree']}/{n} crash ada/spark={row['crash_ada']}/{row['crash_spark']}"
          + (f"  e.g. [{row['first_case'][:60]}] ada={row['ada_out'][:40]} spark={row['spark_out'][:40]}" if row['disagree'] else ''), flush=True)
    return row

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--seed', type=int, default=20261008)
    ap.add_argument('--cases', type=int, default=0, help='override cases per pair')
    ap.add_argument('--out', default=os.path.join(ROOT, 'vv', 'results', 'diff.csv'))
    ap.add_argument('--work', default=os.path.join(tempfile.gettempdir(), 'vv_diff'))
    ap.add_argument('--only', nargs='*')
    ap.add_argument('-j', '--jobs', type=int, default=1, help='pairs run in parallel')
    a = ap.parse_args()
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    names = [n for n in sorted(os.listdir(HERE))
             if os.path.exists(os.path.join(HERE, n, 'pair.json')) and (not a.only or n in a.only)]
    from concurrent.futures import ThreadPoolExecutor
    with ThreadPoolExecutor(max(1, a.jobs)) as ex:
        rows = list(ex.map(lambda n: one_pair(n, a), names))
    with open(a.out, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
    print('wrote', a.out)

if __name__ == '__main__':
    main()
