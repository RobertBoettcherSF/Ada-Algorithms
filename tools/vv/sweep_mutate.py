#!/usr/bin/env python3
"""Mutation score for the sweep's own tests (docs/VV.md 3i).

Like tools/vv/mutate.py (same operators, same test run with GNAT 14,
-gnat2022 -gnata), but only library code is mutated: .adb files that are
not tests*, own_checks*, main*, demo* and not under obj/, bin/ or tests/.
(mutate.py also samples obj/b__*.adb binder files and own_checks.adb, whose
mutants say nothing about the code under test.) Up to --max mutants per
folder (seeded sample of all sites), run in parallel.

usage: sweep_mutate.py FOLDER... [--max 40] [-j 6] [--out file.csv]
"""
import argparse, csv, os, random, re, shutil, sys
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mutate, subprocess

GNATMAKE = mutate.GNATMAKE
# room rule 2026-10-08 19:25: kill = nonzero exit status or a FAIL line (not one reporting 0 failures);
# a timeout is reported separately and is not a kill for the 90% bar
FAIL_LINE = re.compile(r'\bFAIL')
ZERO_FAIL = re.compile(r'FAIL(ED|S|URES?)?\s*[:=]?\s*0\b|\b0\s+FAIL|0 failed', re.I)

def run_tests(work):
    """Kill = nonzero exit status (an unhandled exception gives one) or a FAIL
    line not reporting 0 failures; 'raised' text alone is not a kill; a
    timeout is returned as 'timeout' (room rule 2026-10-08 19:25)."""
    main = next((m for m in ('tests.adb', 'tests/main.adb', 'src/tests.adb') if os.path.exists(os.path.join(work, m))), None)
    if not main:
        return 'no tests'
    os.makedirs(os.path.join(work, 'obj'), exist_ok=True)
    inc = [f'-I{d}' for d in ('src', 'tests') if os.path.isdir(os.path.join(work, d))]
    b = subprocess.run([GNATMAKE, '-q', '-gnat2022', '-gnata', *inc, '-D', 'obj', main, '-o', 'tbin'],
                       cwd=work, capture_output=True, text=True)
    if b.returncode != 0:
        return 'stillborn'
    try:
        r = subprocess.run(['./tbin'], cwd=work, capture_output=True, text=True, timeout=30)
    except subprocess.TimeoutExpired:
        return 'timeout'
    if r.returncode != 0 or any(FAIL_LINE.search(l) and not ZERO_FAIL.search(l) for l in (r.stdout + r.stderr).split('\n')):
        return 'killed'
    return 'survived'

ROOT = mutate.ROOT
TESTNAME = re.compile(r'^(tests?|own_checks|main|demo)', re.I)
IGN = shutil.ignore_patterns('obj', 'bin', 'gnatprove', 'tbin', '*.o', '*.ali', 'b~*', 'b__*')   # build artefacts (some gprs build in the source dir)
DUMMY = False

def lib_files(src):
    for d, dirs, fs in os.walk(src):
        dirs[:] = [x for x in dirs if x not in ('obj', 'bin', 'gnatprove', 'tests')]
        for f in sorted(fs):
            if f.endswith('.adb') and not TESTNAME.match(f):
                yield os.path.relpath(os.path.join(d, f), src)

def one(args):
    src, w, rel, ln, c0, c1, rep = args
    shutil.rmtree(w, ignore_errors=True); shutil.copytree(src, w, ignore=IGN)
    if DUMMY:
        mutate.make_dummy(w)
    p = os.path.join(w, rel)
    lines = open(p, errors='replace').read().split('\n')
    orig = lines[ln]; lines[ln] = orig[:c0] + rep + orig[c1:]
    open(p, 'w').write('\n'.join(lines))
    res = run_tests(w)
    shutil.rmtree(w, ignore_errors=True)
    return orig.strip()[:100], lines[ln].strip()[:100], res

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('folders', nargs='+'); ap.add_argument('--max', type=int, default=40)
    ap.add_argument('-j', type=int, default=6); ap.add_argument('--seed', type=int, default=20261008)
    ap.add_argument('--out', default='/tmp/sweep_mut.csv'); ap.add_argument('--work', default='/tmp/sweep_mut')
    ap.add_argument('--dummy', action='store_true', help='control (a): always-passing test that checks nothing; must score 0')
    a = ap.parse_args()
    global DUMMY
    DUMMY = a.dummy
    rows, detail = [], []
    for fid in a.folders:
        src = os.path.join(ROOT, fid); wk = os.path.join(a.work, fid.replace('/', '_'))
        shutil.rmtree(wk, ignore_errors=True); shutil.copytree(src, wk + '/base', ignore=IGN)
        if DUMMY:
            mutate.make_dummy(wk + '/base')
        base = run_tests(wk + '/base')
        cand = [(rel,) + s for rel in lib_files(src) for s in mutate.sites(os.path.join(src, rel))]
        rng = random.Random(a.seed)
        pick = rng.sample(cand, min(a.max, len(cand))) if base == 'survived' else []
        jobs = [(src, f'{wk}/m{i}', rel, ln, c0, c1, rep) for i, (rel, ln, c0, c1, name, rep) in enumerate(pick)]
        with ThreadPoolExecutor(a.j) as ex:
            res = list(ex.map(one, jobs))
        k = sum(r[2] == 'killed' for r in res); s = sum(r[2] == 'survived' for r in res); sb = sum(r[2] == 'stillborn' for r in res)
        to = sum(r[2] == 'timeout' for r in res)
        for (rel, ln, c0, c1, name, rep), (b, af, r) in zip(pick, res):
            detail.append(dict(folder=fid, file=rel, line=ln + 1, op=name, before=b, after=af, result=r))
        score = '' if k + s + to == 0 else f'{k}/{k + s + to}'          # timeouts are not kills
        score_t = '' if k + s + to == 0 else f'{k + to}/{k + s + to}'   # reported both ways
        rows.append(dict(folder=fid, baseline=('pass' if base == 'survived' else base), sites=len(cand), mutants=len(pick),
                         killed=k, survived=s, timeout=to, stillborn=sb, score=score, score_with_timeouts=score_t))
        print(f"{fid:60s} base={rows[-1]['baseline']:8s} sites={len(cand):4d} killed={k} survived={s} timeout={to} stillborn={sb} score={score}", flush=True)
    with open(a.out, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
    if detail:
        with open(a.out.replace('.csv', '_detail.csv'), 'w', newline='') as f:
            w = csv.DictWriter(f, fieldnames=list(detail[0].keys())); w.writeheader(); w.writerows(detail)

if __name__ == '__main__':
    main()
