#!/usr/bin/env python3
"""Seal a score138 held half before anything else (2026-10-10 night, H182-H185).

Computes the score138 pools for FOLDER under SEED (no test is run, no mutant is shown) and prints
one CSV row: folder, seed, base commit, held pool size, held pool per family, and the sha256 of
the held draw order (json of [family, operator, edits] per family list in score138's shuffled
order). The same command on the same tree gives the same hash, so the later held run can be
checked against the sealed row (--check HASH exits 1 on a mismatch). Mutant text is never printed.

  seal_held.py FOLDER --seed S [--check HASH]
"""
import argparse, hashlib, json, os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import score138
ap = argparse.ArgumentParser()
ap.add_argument('folder'); ap.add_argument('--seed', type=int, required=True); ap.add_argument('--check', default='')
a = ap.parse_args()
P, nseen = score138.pools(a.folder, a.seed)
order = {f: [[c[0], c[1], c[2]] for c in P[('held', f)]] for f in score138.FAMS}
h = hashlib.sha256(json.dumps(order, sort_keys=True).encode()).hexdigest()
by = ' '.join(f'{f}={len(order[f])}' for f in score138.FAMS)
head = subprocess.run(['git', 'rev-parse', '--short=8', 'HEAD'], cwd=score138.ROOT, capture_output=True, text=True).stdout.strip()
print(f'"{a.folder}","{a.seed}","{head}","{sum(len(v) for v in order.values())}","{by}","{nseen}","{h}","{time.strftime("%Y-%m-%d %H:%M:%S %Z")}"')
if a.check and a.check != h:
    sys.exit(f'held draw order changed: sealed {a.check}, now {h}')
