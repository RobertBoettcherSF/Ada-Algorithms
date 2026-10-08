#!/usr/bin/env python3
"""Held-out mutation scoring (docs/VV.md 3c, room rule 2026-10-08 19:56).

Every mutation site of a folder's library code (same operators and same kill rule as
tools/vv/sweep_mutate.py) goes to one of two halves, tuning or held-out. The choice is
made by a hash of (split seed, file, the line's text, column, operator), so it does not
depend on line numbers and stays put when unrelated lines move. Mutants already
published by the rescore (vv/results/mutation_tr_detail.csv) are always put in the
tuning half, because anyone may have looked at them.

  heldout.py split FOLDER...                   counts per half, nothing is run
  heldout.py score FOLDER... --half tuning     score up to --max mutants of the tuning half
  heldout.py score FOLDER... --half heldout    the 90% bar (never look at these survivors
                                               before the folder's test work is final)

Results are appended to vv/results/mutation_halves.csv (folder, half, split_seed,
sample_seed, sites_half, mutants, killed, survived, timeout, stillborn, equivalent,
score). Per-mutant rows go to mutation_halves_detail.csv. A survivor counts as
equivalent only when tools/vv/sweep_equivalent.csv (or flagship_equivalent.csv)
lists it as "file:line op ...". The held-out half needs at least 20 non-equivalent
scored mutants. If it has fewer, the row says so (short=yes) and must be topped up
from the alternative operator family (sweep_mutate.py --family alt).
"""
import argparse, csv, hashlib, os, random, re, shutil, sys
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mutate, sweep_mutate as sm

ROOT = mutate.ROOT
RES = os.path.join(ROOT, 'vv', 'results')
SPLIT_SEED = 20261108

def published():
    seen = set()
    p = os.path.join(RES, 'mutation_tr_detail.csv')
    if os.path.exists(p):
        for d in csv.DictReader(open(p)):
            seen.add((d['folder'], d['file'], d['before'].strip()[:100], d['op']))
    return seen

def equivalents():
    eq = set()
    for n in ('sweep_equivalent.csv', 'flagship_equivalent.csv'):
        p = os.path.join(ROOT, 'tools', 'vv', n)
        if os.path.exists(p):
            for x in csv.DictReader(open(p)):
                m = re.match(r'\s*([^:\s]+):(\d+)\s+(.*?)\s+->', x.get('mutant', ''))
                if m and (x.get('range_or_reason') or '').strip():
                    eq.add((x['folder'], os.path.basename(m.group(1)), int(m.group(2))))
    return eq

def halves(fid, seed, seen):
    src = os.path.join(ROOT, fid)
    tun, ho = [], []
    for rel in sm.lib_files(src):
        lines = open(os.path.join(src, rel), errors='replace').read().split('\n')
        for (ln, c0, c1, name, rep) in mutate.sites(os.path.join(src, rel)):
            text = lines[ln].strip()
            if (fid, rel, text[:100], name) in seen:
                tun.append((rel, ln, c0, c1, name, rep)); continue
            h = hashlib.sha256(f'{seed}|{rel}|{text}|{c0}|{name}|{rep}'.encode()).digest()[0]
            (ho if h & 1 else tun).append((rel, ln, c0, c1, name, rep))
    return tun, ho

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=('split', 'score')); ap.add_argument('folders', nargs='+')
    ap.add_argument('--half', choices=('tuning', 'heldout'), default='heldout')
    ap.add_argument('--split-seed', type=int, default=SPLIT_SEED)
    ap.add_argument('--seed', type=int, default=20261109, help='sample seed inside the half')
    ap.add_argument('--max', type=int, default=40); ap.add_argument('-j', type=int, default=6)
    ap.add_argument('--work', default='/tmp/heldout_work')
    ap.add_argument('--out', default=os.path.join(RES, 'mutation_halves.csv'))
    a = ap.parse_args()
    seen, eq = published(), equivalents()
    rows, detail = [], []
    for fid in a.folders:
        tun, ho = halves(fid, a.split_seed, seen)
        if a.cmd == 'split':
            print(f'{fid:60s} tuning={len(tun)} heldout={len(ho)}'); continue
        cand = tun if a.half == 'tuning' else ho
        src = os.path.join(ROOT, fid); wk = os.path.join(a.work, fid.replace('/', '_'))
        shutil.rmtree(wk, ignore_errors=True); shutil.copytree(src, wk + '/base', ignore=sm.IGN)
        base = sm.run_tests(wk + '/base')
        pick = random.Random(a.seed).sample(cand, min(a.max, len(cand))) if base == 'survived' else []
        jobs = [(src, f'{wk}/m{i}', rel, ln, c0, c1, rep) for i, (rel, ln, c0, c1, name, rep) in enumerate(pick)]
        with ThreadPoolExecutor(a.j) as ex:
            res = list(ex.map(sm.one, jobs))
        k = s = to = sb = e = 0
        for (rel, ln, c0, c1, name, rep), (b, af, r) in zip(pick, res):
            iseq = r == 'survived' and (fid, os.path.basename(rel), ln + 1) in eq
            k += r == 'killed'; s += r == 'survived' and not iseq; to += r == 'timeout'; sb += r == 'stillborn'; e += iseq
            detail.append(dict(folder=fid, half=a.half, file=rel, line=ln + 1, op=name, before=b, after=af,
                               result='equivalent' if iseq else r))
        n = k + s + to
        rows.append(dict(folder=fid, half=a.half, split_seed=a.split_seed, sample_seed=a.seed,
                         baseline='pass' if base == 'survived' else base, sites_half=len(cand), mutants=len(pick),
                         killed=k, survived=s, timeout=to, stillborn=sb, equivalent=e,
                         score=f'{k}/{n}' if n else '', short='yes' if a.half == 'heldout' and n < 20 else 'no'))
        shutil.rmtree(wk, ignore_errors=True)
        print(f"{fid:60s} {a.half} base={rows[-1]['baseline']} sites={len(cand)} killed={k} survived={s} timeout={to} "
              f"stillborn={sb} equivalent={e} score={rows[-1]['score']} short={rows[-1]['short']}", flush=True)
    if rows:
        for path, rs in ((a.out, rows), (a.out.replace('.csv', '_detail.csv'), detail)):
            if not rs: continue
            new = not os.path.exists(path)
            with open(path, 'a', newline='') as fh:
                w = csv.DictWriter(fh, fieldnames=list(rs[0].keys()), lineterminator='\n')
                if new: w.writeheader()
                w.writerows(rs)

if __name__ == '__main__':
    main()
