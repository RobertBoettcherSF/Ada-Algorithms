#!/usr/bin/env python3
"""Held-out round with the alternative operator family (docs/VV.md 3i/3j) for folders whose
first-order (std) mutants were all used for tuning, so no split half is left.

For each folder: candidates = sweep_mutate.candidates(src, 'alt', Random(seed + 1)) (statement
deletion, constant +-1/0, argument swap, second-order pairs of std mutants), shuffled with
Random(seed). Mutants are run in that order with the strict scorer (sweep_mutate_strict.run_tests:
killed = non-zero exit or a FAIL line; 30 s limit) until --target scored mutants (killed +
survived + timeout; stillborn mutants do not count) or the list ends. When the list ends below
--target, it is topped up with further second-order pairs (fresh Random(seed + 2), no repeats).
Raw counts: no equivalence exclusion; timeouts count as survivors (score = killed / scored).
Survivor lines are never printed or stored in the repository: the detail file (--sealed) holds
operator and result only, with line and text hidden, so nobody tunes on held-out survivors.

usage: sweep_heldout_alt.py FOLDER... [--target 30] [--min 20] [--seed 20261010] [-j 4] [--out X.csv]
"""
import argparse, csv, os, random, shutil, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sweep_mutate_strict as sms
import sweep_mutate as sm
import mutate

def extra_pairs(src, rng, seen, want):
    """Further second-order pairs, then third-order triples, then leftover std singles."""
    std = sm.candidates(src, 'std', rng)
    out, tries = [], 0
    while len(out) < want and len(std) >= 2 and tries < 80 * want:
        tries += 1
        a, b = rng.sample(std, 2)
        if (a[1][0][0], a[1][0][1]) == (b[1][0][0], b[1][0][1]):
            continue
        key = tuple(sorted([tuple(a[1][0]), tuple(b[1][0])]))
        if key in seen:
            continue
        seen.add(key); out.append((a[0] + ' + ' + b[0], a[1] + b[1]))
    # third-order triples when pairs alone cannot reach the floor
    while len(out) < want and len(std) >= 3 and tries < 120 * want:
        tries += 1
        a, b, c = rng.sample(std, 3)
        key = ('tri',) + tuple(sorted([tuple(a[1][0]), tuple(b[1][0]), tuple(c[1][0])]))
        if key in seen:
            continue
        seen.add(key); out.append((a[0] + ' + ' + b[0] + ' + ' + c[0], a[1] + b[1] + c[1]))
    for name, edits in std:
        if len(out) >= want:
            break
        key = ('std',) + tuple(edits[0])
        if key in seen:
            continue
        seen.add(key); out.append((name, edits))
    return out

def key_of(c):
    return tuple(sorted(tuple(e) for e in c[1]))

def run_folder(fid, a, ver):
    src = os.path.join(sm.ROOT, fid); wk = os.path.join(a.work, fid.replace('/', '_'))
    shutil.rmtree(wk, ignore_errors=True); shutil.copytree(src, wk + '/base', ignore=sm.IGN)
    base = sms.run_tests(wk + '/base')
    row = dict(folder=fid, family='alt', seed=a.seed, baseline=('pass' if base == 'survived' else base), drawn=0,
               pool=0, topped_up=0, killed=0, survived=0, timeout=0, stillborn=0, scored=0, score='', pct='',
               enough=('no'), compiler=ver)
    if base != 'survived':
        return row, []
    cand = sm.candidates(src, 'alt', random.Random(a.seed + 1))
    seen = {key_of(c) for c in cand}
    random.Random(a.seed).shuffle(cand)
    row['pool'] = len(cand)
    res, det, i, topped = [], [], 0, 0
    trng = random.Random(a.seed + 2)
    while True:
        scored = sum(r in ('killed', 'survived', 'timeout') for r in res)
        if scored >= a.target:
            break
        if i >= len(cand):
            more = extra_pairs(src, trng, seen, a.target - scored + 5)
            if not more:
                break
            cand += more; topped += len(more)
        batch = cand[i:i + max(1, min(a.j, a.target - scored))]; i += len(batch)
        jobs = [(src, f'{wk}/m{i}_{n}', edits) for n, (name, edits) in enumerate(batch)]
        with ThreadPoolExecutor(a.j) as ex:
            out = list(ex.map(sm.one, jobs))
        for (name, edits), (_b, _af, r, *_kind) in zip(batch, out):   # sm.one also returns kill_kind (uninit recheck)
            res.append(r); det.append(dict(folder=fid, seed=a.seed, op=name, line='hidden', result=r))
    shutil.rmtree(wk, ignore_errors=True)
    k, s, to, sb = (res.count(x) for x in ('killed', 'survived', 'timeout', 'stillborn'))
    n = k + s + to
    row.update(drawn=len(res), topped_up=topped, killed=k, survived=s, timeout=to, stillborn=sb, scored=n,
               score=(f'{k}/{n}' if n else ''), pct=(f'{100.0 * k / n:.1f}%' if n else ''),
               enough=('yes' if n >= a.min else 'no'))
    return row, det

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('folders', nargs='*'); ap.add_argument('--from-file')
    ap.add_argument('--target', type=int, default=30); ap.add_argument('--min', type=int, default=20)
    ap.add_argument('--seed', type=int, default=20261010); ap.add_argument('-j', type=int, default=4)
    ap.add_argument('--out', default=os.path.join(tempfile.gettempdir(), 'heldout_alt.csv')); ap.add_argument('--sealed', default=None)
    ap.add_argument('--work', default=os.path.join(tempfile.gettempdir(), 'heldout_alt_work'))
    a = ap.parse_args()
    ids = a.folders + ([l.strip() for l in open(a.from_file) if l.strip()] if a.from_file else [])
    ver = mutate.require_version(14)
    fields = ['folder', 'family', 'seed', 'baseline', 'drawn', 'pool', 'topped_up', 'killed', 'survived', 'timeout',
              'stillborn', 'scored', 'score', 'pct', 'enough', 'compiler']
    sealed = a.sealed or a.out.replace('.csv', '_sealed.csv')
    with open(a.out, 'w', newline='') as fo, open(sealed, 'w', newline='') as fd:
        w = csv.DictWriter(fo, fieldnames=fields, lineterminator='\n'); w.writeheader()
        wd = csv.DictWriter(fd, fieldnames=['folder', 'seed', 'op', 'line', 'result'], lineterminator='\n'); wd.writeheader()
        for fid in ids:
            row, det = run_folder(fid, a, ver)
            w.writerow(row); fo.flush(); wd.writerows(det); fd.flush()
            print(f"{fid:60s} base={row['baseline']:8s} scored={row['scored']:3d} k={row['killed']} s={row['survived']} "
                  f"to={row['timeout']} sb={row['stillborn']} topped={row['topped_up']} {row['pct']}", flush=True)

if __name__ == '__main__':
    main()
