#!/usr/bin/env python3
"""Unseal the survivors of a finished sweep_topup_B.py run, for classification
after the blind score has been recorded (the score itself is not changed).

sweep_topup_B.py draws its candidates deterministically (fresh(): seeded shuffle
of the var family, then seeded higher-order std combinations) and writes one
sealed row (operator, result) per drawn candidate, in draw order. This script
replays fresh() on the same commit and pairs the i-th candidate with the i-th
sealed row of that folder and seed, checking that the operators agree.

usage (from a clean `git archive` of the commit the run used):
  sweep_topup_B_reveal.py FOLDER --seed S --sealed SEALED.csv [--target 30]
prints every drawn candidate that survived or timed out, with its edits.
"""
import argparse, csv, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sweep_mutate as sm
import sweep_topup_B as tb


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('folder')
    ap.add_argument('--seed', type=int, required=True)
    ap.add_argument('--sealed', required=True)
    ap.add_argument('--target', type=int, default=30)
    ap.add_argument('--split-rng-seed', type=int, default=20261008)
    a = ap.parse_args()
    rows = [r for r in csv.DictReader(open(a.sealed))
            if r['folder'] == a.folder and int(r['seed']) == a.seed]
    src = os.path.join(sm.ROOT, a.folder)
    cand = tb.fresh(src, a.seed, a.target * 3, a.split_rng_seed)
    assert len(cand) >= len(rows), (len(cand), len(rows))
    for i, (r, (name, edits)) in enumerate(zip(rows, cand)):
        op = (name.split(' ->')[0].split(' + ')[0] if len(edits) == 1 else 'std combination') + ' (order ' + str(len(edits)) + ')'
        op_run1 = name.split(' ')[0] + ' (order ' + str(len(edits)) + ')'   # operator label of the first version (run 1)
        assert r['op'] in (op, op_run1), (i, op, r['op'])
        if r['result'] in ('survived', 'timeout'):
            print(f'#{i} {r["result"]}: {name}')
            for (rel, ln, c0, c1, rep) in edits:
                line = open(os.path.join(src, rel), errors='replace').read().split('\n')[ln]
                print(f'    {rel}:{ln + 1}: {line.strip()}')
                print(f'    -> {(line[:c0] + rep + line[c1:]).strip()}')


if __name__ == '__main__':
    main()
