#!/usr/bin/env python3
"""Proof-kill step for held-out mutation survivors (sweep B).

For every mutant that SURVIVED or TIMED OUT the tests in a sweep_mutate.py detail CSV,
re-create the mutant in a fresh copy of the folder and run `make prove`; a mutant the
prover rejects counts as a proof kill.

Usage:
  python3 tools/vv/proofkill.py ROOT FOLDER SPLIT_SEED SEED MAX OUTDIR JOBS half:family:DETAIL.csv ...
    ROOT        repo root (e.g. .)
    FOLDER      repo-relative folder id, e.g. sorting/SPARK4/Ada-SPARK-Slowsort
    SPLIT_SEED  the --split-seed of the sweep_mutate.py run
    SEED        the --seed of the sweep_mutate.py run (default there 20261008)
    MAX         the --max of the sweep_mutate.py run (default 40)
    OUTDIR      scratch directory (one subdir per mutant + proofkill.csv); keep it outside git
    JOBS        parallel make prove jobs
Each detail CSV must be the *_detail.csv written by the matching sweep_mutate.py run
(the candidate draw is replayed and checked row by row against it).

Committed from the box scratch copy (proofkill.py) on 2026-10-09 (handover H129/H130/H141);
logic unchanged.
"""
import sys, os, random, csv, shutil, subprocess, re
from concurrent.futures import ThreadPoolExecutor
root, fid, split, seed, mx, outdir, jobs = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), sys.argv[6], int(sys.argv[7])
runs = sys.argv[8:]   # entries half:family:detail
sys.path.insert(0, os.path.join(root, 'tools/vv'))
import sweep_mutate as sm
src = os.path.join(root, fid)
todo = []
for spec in runs:
    half, family, detail = spec.split(':', 2)
    cand = sm.candidates(src, family, random.Random(seed + 1))
    cand = [c for c in cand if sm.split_half(src, c, split) == half]
    pick = random.Random(seed).sample(cand, min(mx, len(cand)))
    rows = list(csv.DictReader(open(detail)))
    assert len(rows) == len(pick), (len(rows), len(pick))
    for k, ((n, e), r) in enumerate(zip(pick, rows)):
        assert n == r['op']
        if r['result'] in ('survived', 'timeout'):
            todo.append((half, family, k, n, e, r['result']))
os.makedirs(outdir, exist_ok=True)
def one(t):
    half, family, k, n, e, res = t
    d = os.path.join(outdir, f'{half}_{family}_{k}')
    shutil.rmtree(d, ignore_errors=True)
    shutil.copytree(src, d, ignore=shutil.ignore_patterns('obj', 'bin', 'gnatprove'))
    files = {}
    for (f, ln, a, b, rep) in e:
        files.setdefault(f, []).append((ln, a, b, rep))
    before, after = [], []
    for f, eds in files.items():
        p = os.path.join(d, f)
        L = open(p).read().split('\n')
        for ln, a, b, rep in sorted(eds, key=lambda x: (x[0], x[1]), reverse=True):
            before.append(L[ln].strip())
            L[ln] = L[ln][:a] + rep + L[ln][b:]
            after.append(L[ln].strip())
        open(p, 'w').write('\n'.join(L))
    try:
        pr = subprocess.run(['make', 'prove'], cwd=d, capture_output=True, text=True, timeout=1800)
        out = pr.stdout + pr.stderr; rc = pr.returncode
    except subprocess.TimeoutExpired:
        out, rc = 'TIMEOUT', -1
    msgs = re.findall(r'^\s*(?:medium|high|low|error|warning)[^\n]*\n-->\s*([^\n]+)', out, re.M)
    first = re.findall(r'^\s*((?:medium|high|low|error|warning):[^\n]*)\n-->\s*([^\n]+)', out, re.M)
    if rc == 0 and 'Success' in out:
        verdict = 'proved'
    elif first:
        verdict = 'proof_fail'
    elif 'TIMEOUT' in out:
        verdict = 'prove_timeout'
    else:
        verdict = 'error'
    m = re.search(r'all checks proved \((\d+) checks\)', out)
    ev = ('; '.join(f'{a.strip()} at {b.strip()}' for a, b in first[:2]) if first else (m.group(0) if m else out.strip().split('\n')[-1][:200]))
    open(os.path.join(d, 'prove.log'), 'w').write(out)
    lines = '+'.join(str(x[1] + 1) for x in e)
    return [fid, half, family, f'{e[0][0]}:{lines} {n}', ' || '.join(before) + ' => ' + ' || '.join(after), res, verdict, ev]
with ThreadPoolExecutor(jobs) as ex:
    rows = list(ex.map(one, todo))
w = csv.writer(open(os.path.join(outdir, 'proofkill.csv'), 'w', newline=''), lineterminator='\n')
w.writerow(['folder', 'half', 'family', 'mutant', 'change', 'test_result', 'prove_verdict', 'evidence'])
w.writerows(rows)
for r in rows: print(r[1], r[2], r[3], '|', r[6], '|', r[7][:160])
