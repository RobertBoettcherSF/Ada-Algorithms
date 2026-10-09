#!/usr/bin/env python3
"""Held-out top-up for sweep B folders whose held-out half has fewer than 20
non-equivalent mutants (docs/VV.md 3i: top up until the floor is met, then score).

The split rounds used every std and alt candidate of a folder (tune half seen,
held half already scored). This top-up draws only mutants that are in NEITHER
list: second-order pairs and third-order triples of std mutants
(sweep_heldout_alt.extra_pairs, fresh Random(seed + 2)), with every key that
occurs in the std or alt candidate lists excluded and first-order singles
dropped. So no top-up mutant was seen during tuning.

Scoring is raw (no equivalence exclusion, timeouts count as survivors) with
sweep_mutate.one, until --target scored mutants or the generator is exhausted.
The sealed detail file stores operator and result only (line and text hidden).

usage: sweep_topup_B.py FOLDER... --seed S [--target 30] [-j 4] --out X.csv
Run it from a clean `git archive` of the commit under test.
"""
import argparse, csv, os, random, shutil, sys
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sweep_mutate as sm
import sweep_mutate_strict as sms
import sweep_heldout_alt as sha
import mutate


def fresh(src, seed, want, split_rng_seed):
    seen = set()
    for fam in ('std', 'alt'):
        # the same Random(seed + 1) as sweep_mutate.py used for the split rounds,
        # so the alt second-order pairs excluded here are exactly the ones drawn there
        for c in sm.candidates(src, fam, random.Random(split_rng_seed + 1)):
            seen.add(sha.key_of(c))
            if len(c[1]) == 1:
                seen.add(('std',) + tuple(c[1][0]))
    rng = random.Random(seed + 2)
    out = []
    for _ in range(4):
        more = [c for c in sha.extra_pairs(src, rng, seen, want - len(out) + 5) if len(c[1]) >= 2]
        out += [c for c in more if sha.key_of(c) not in {sha.key_of(o) for o in out}]
        if len(out) >= want or not more:
            break
    random.Random(seed).shuffle(out)
    return out


def run_folder(fid, a, ver):
    src = os.path.join(sm.ROOT, fid)
    wk = os.path.join(a.work, fid.replace('/', '_'))
    shutil.rmtree(wk, ignore_errors=True)
    shutil.copytree(src, wk + '/base', ignore=sm.IGN)
    base = sms.run_tests(wk + '/base')
    row = dict(folder=fid, family='topup higher-order (unseen)', seed=a.seed,
               baseline=('pass' if base == 'survived' else base), pool=0, drawn=0, killed=0,
               survived=0, timeout=0, stillborn=0, scored=0, score='', pct='', compiler=ver)
    if base != 'survived':
        return row, []
    cand = fresh(src, a.seed, a.target * 3, a.split_rng_seed)
    row['pool'] = len(cand)
    res, det, i = [], [], 0
    while i < len(cand):
        scored = sum(r in ('killed', 'survived', 'timeout') for r in res)
        if scored >= a.target:
            break
        batch = cand[i:i + max(1, min(a.j, a.target - scored))]
        i += len(batch)
        jobs = [(src, f'{wk}/m{i}_{n}', name, edits) for n, (name, edits) in enumerate(batch)]
        with ThreadPoolExecutor(a.j) as ex:
            out = list(ex.map(sm.one, jobs))
        for (name, edits), (_b, _af, r, _kk) in zip(batch, out):
            res.append(r)
            det.append(dict(folder=fid, seed=a.seed, op=name.split(' ')[0] + ' (order ' + str(len(edits)) + ')',
                            line='hidden', result=r))
    shutil.rmtree(wk, ignore_errors=True)
    k, s, to, sb = (res.count(x) for x in ('killed', 'survived', 'timeout', 'stillborn'))
    n = k + s + to
    row.update(drawn=len(res), killed=k, survived=s, timeout=to, stillborn=sb, scored=n,
               score=(f'{k}/{n}' if n else ''), pct=(f'{100.0 * k / n:.1f}%' if n else ''))
    return row, det


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('folders', nargs='+')
    ap.add_argument('--seed', type=int, required=True)
    ap.add_argument('--target', type=int, default=30)
    ap.add_argument('--split-rng-seed', type=int, default=20261008, help='the --seed of the split rounds (sweep_mutate.py default)')
    ap.add_argument('-j', type=int, default=4)
    ap.add_argument('--out', required=True)
    ap.add_argument('--work', default='/tmp/topupB_work')
    a = ap.parse_args()
    ver = mutate.require_version(14)
    fields = ['folder', 'family', 'seed', 'baseline', 'pool', 'drawn', 'killed', 'survived', 'timeout',
              'stillborn', 'scored', 'score', 'pct', 'compiler']
    with open(a.out, 'w', newline='') as fo, open(a.out.replace('.csv', '_sealed.csv'), 'w', newline='') as fd:
        w = csv.DictWriter(fo, fieldnames=fields, lineterminator='\n'); w.writeheader()
        wd = csv.DictWriter(fd, fieldnames=['folder', 'seed', 'op', 'line', 'result'], lineterminator='\n'); wd.writeheader()
        for fid in a.folders:
            row, det = run_folder(fid, a, ver)
            w.writerow(row); fo.flush(); wd.writerows(det); fd.flush()
            print(f"{fid:55s} base={row['baseline']} pool={row['pool']} scored={row['scored']} "
                  f"k={row['killed']} s={row['survived']} to={row['timeout']} sb={row['stillborn']} {row['pct']}", flush=True)


if __name__ == '__main__':
    main()
