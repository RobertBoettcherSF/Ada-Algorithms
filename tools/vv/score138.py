#!/usr/bin/env python3
"""Blind held-out mutation score with MIXED operator families (agent-S138, 2026-10-09).

For folders whose only strict-rule failure is 'no held-out mutation score'.
One candidate list per folder from all five operator families of tools/vv:
  std  first-order mutate.py operators (sweep_mutate.py std)
  alt  statement deletion, integer constant +-1/0, argument swap (sweep_mutate.alt_sites)
  ho   second-order: pairs of std mutants on different lines (all pairs; at most 300, Random(seed + 1))
  B    variable replacement, loop direction, 'Max/'Min, return + 1 (sweep_topup_B.var_sites)
  C    actual +-1, swapped actuals, mod/rem, 'First/'Last +-1, also in .ads (sweep_topup_C.c_sites)
Candidates that produce the same file text are kept once (first family in the
order above).  Candidates already shown in any visible (non-hidden) detail
file of the repo (vv/results/*detail*.csv, tools/vv/*detail*.csv) are SEEN and
forced into the tune half.  Every other candidate is split tune/held by a
sha256 of (split seed, family, file, mutated line text, column, replacement):
stable against edits elsewhere in the folder.

Draw (pre-registered, same for both halves): per family a list shuffled with
Random('<seed>:<half>:<family>'); round robin over the families, each family
contributing one SCORED (non-stillborn) mutant per round, rounds continue until
>= --target scored or every family is exhausted.  Balanced by construction;
a family with a small pool simply runs out.

  score138.py list   FOLDER... --seed S            pool sizes per family/half, no tests run
  score138.py run    FOLDER  --seed S --half tune|held --out DIR [--target 48] [-j 2] [--dummy]
Held output: DIR/<folder>_held.json holds the full edits (kept OUT of the repo
until the held run is final, for the proof pass and later classification);
the committed sealed file has family / operator / result only.
Kill = non-zero exit or FAIL line (sweep_mutate.run_tests); timeout = survivor
in the score; stillborn not scored.  Assignment-deletion survivors are
re-checked under Initialize_Scalars + -gnatVa (kill_kind=uninit).
"""
import argparse, csv, glob, hashlib, json, os, random, shutil, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mutate, sweep_mutate as sm, sweep_topup_B as tb, sweep_topup_C as tc

FAMS = ('std', 'alt', 'ho', 'B', 'C')
ROOT = sm.ROOT


def _apply(src, edits):
    out = {}
    for rel, ln, c0, c1, rep in edits:
        if rel not in out:
            out[rel] = open(os.path.join(src, rel), errors='replace').read().split('\n')
        line = out[rel][ln]
        out[rel][ln] = line[:c0] + rep + line[c1:]
    return tuple(sorted((r, '\n'.join(v)) for r, v in out.items()))


def _shown(src, edits):
    b, a = [], []
    for rel, ln, c0, c1, rep in edits:
        line = open(os.path.join(src, rel), errors='replace').read().split('\n')[ln]
        b.append(line.strip()[:100]); a.append((line[:c0] + rep + line[c1:]).strip()[:100])
    return ' || '.join(b), ' || '.join(a)


def seen_keys(fid):
    """(file basename, before, after) of every mutant of this folder shown in a visible detail file."""
    keys = set()
    files = glob.glob(os.path.join(ROOT, 'vv', 'results', '*detail*.csv')) + glob.glob(os.path.join(ROOT, 'tools', 'vv', '*detail*.csv'))
    for p in files:
        try:
            for r in csv.DictReader(open(p, errors='replace')):
                if r.get('folder') != fid:
                    continue
                b, a = (r.get('before') or '').strip(), (r.get('after') or '').strip()
                if not b or b == 'hidden' or a == 'hidden':
                    continue
                keys.add((os.path.basename(r.get('file') or ''), b, a))
        except Exception:
            pass
    return keys


def candidates(src, seed_rng):
    fam = {}
    std = sm.candidates(src, 'std', None)
    fam['std'] = std
    fam['alt'] = [(n, [(rel, ln, c0, c1, rep)]) for rel in sm.lib_files(src)
                  for (ln, c0, c1, n, rep) in sm.alt_sites(os.path.join(src, rel))]
    # every pair of std mutants on different lines (second order), at most 300 drawn with Random(seed + 1)
    pairs = [(std[i][0] + ' + ' + std[k][0], std[i][1] + std[k][1]) for i in range(len(std)) for k in range(i + 1, len(std))
             if (std[i][1][0][0], std[i][1][0][1]) != (std[k][1][0][0], std[k][1][0][1])]
    if len(pairs) > 300:
        pairs = random.Random(seed_rng + 1).sample(pairs, 300)
    fam['ho'] = pairs
    fam['B'] = [(n, [(rel, ln, c0, c1, rep)]) for rel in sm.lib_files(src)
                for (ln, c0, c1, n, rep) in tb.var_sites(os.path.join(src, rel))]
    fam['C'] = [(n, [(rel, ln, c0, c1, rep)]) for rel in tc.lib_all(src)
                for (ln, c0, c1, n, rep) in tc.c_sites(os.path.join(src, rel))]
    texts, out = set(), []
    for f in FAMS:
        for name, edits in fam[f]:
            t = _apply(src, edits)
            if t in texts:
                continue
            texts.add(t)
            out.append((f, name, edits))
    return out


def split(src, c, seed, seen):
    f, name, edits = c
    b, a = _shown(src, edits)
    if (os.path.basename(edits[0][0]), b, a) in seen:
        return 'tune', True
    key = [str(seed), f, name]
    for rel, ln, c0, c1, rep in edits:
        text = open(os.path.join(src, rel), errors='replace').read().split('\n')[ln]
        key += [rel, text.strip(), str(c0 - (len(text) - len(text.lstrip()))), text[c0:c1], rep]
    h = int(hashlib.sha256('\x1f'.join(key).encode()).hexdigest(), 16) % 2
    return ('held' if h else 'tune'), False


def pools(fid, seed):
    src = os.path.join(ROOT, fid)
    seen = seen_keys(fid)
    P = {('tune', f): [] for f in FAMS}; P.update({('held', f): [] for f in FAMS})
    nseen = 0
    for c in candidates(src, seed):
        h, s = split(src, c, seed, seen)
        nseen += s
        P[(h, c[0])].append(c)
    for (h, f), lst in P.items():
        random.Random(f'{seed}:{h}:{f}').shuffle(lst)
    return P, nseen


def run(fid, seed, half, target, j, outdir, dummy=False):
    ver = mutate.require_version(14)
    src = os.path.join(ROOT, fid)
    P, nseen = pools(fid, seed)
    wk = os.path.join(tempfile.gettempdir(), 's138_work', fid.replace('/', '_') + '_' + half + ('_dummy' if dummy else ''))
    shutil.rmtree(wk, ignore_errors=True); shutil.copytree(src, wk + '/base', ignore=sm.IGN)
    sm.DUMMY = dummy
    if dummy:
        mutate.make_dummy(wk + '/base')
    base = sm.run_tests(wk + '/base')
    if base != 'survived':
        sys.exit(f'baseline {base}')
    ptr = {f: 0 for f in FAMS}; got = {f: 0 for f in FAMS}; res = []
    rnd = 0; idx = 0
    while sum(got.values()) < target or any(got[f] < rnd and ptr[f] < len(P[(half, f)]) for f in FAMS):
        need = [f for f in FAMS if got[f] <= rnd and ptr[f] < len(P[(half, f)])]
        if not need:
            if all(ptr[f] >= len(P[(half, f)]) for f in FAMS):
                break
            rnd += 1; continue
        jobs = []
        for f in need:
            c = P[(half, f)][ptr[f]]; ptr[f] += 1; idx += 1
            jobs.append((c, (src, f'{wk}/m{idx}', c[1], c[2])))
        with ThreadPoolExecutor(j) as ex:
            out = list(ex.map(sm.one, [x[1] for x in jobs]))
        for (c, _), (b, a, r, kk) in zip(jobs, out):
            res.append(dict(family=c[0], op=c[1], edits=c[2], before=b, after=a, result=r, kill_kind=kk))
            if r != 'stillborn':
                got[c[0]] += 1
        if all(got[f] > rnd or ptr[f] >= len(P[(half, f)]) for f in FAMS):
            rnd += 1
            if sum(got.values()) >= target:
                break
    shutil.rmtree(wk, ignore_errors=True)
    rec = dict(folder=fid, seed=seed, half=half, target=target, dummy=dummy, compiler=ver, seen_forced_tune=nseen,
               pool={f: len(P[(half, f)]) for f in FAMS}, mutants=res)
    os.makedirs(outdir, exist_ok=True)
    p = os.path.join(outdir, fid.replace('/', '_') + f'_{half}' + ('_dummy' if dummy else '') + '.json')
    json.dump(rec, open(p, 'w'), indent=1)
    by = {}
    for m in res:
        by.setdefault(m['family'], []).append(m['result'])
    for f in FAMS:
        rs = by.get(f, [])
        print(f"{f:4s} pool={len(P[(half, f)]):4d} drawn={len(rs):3d} killed={rs.count('killed')} survived={rs.count('survived')} "
              f"timeout={rs.count('timeout')} stillborn={rs.count('stillborn')}")
    k = sum(m['result'] == 'killed' for m in res); n = sum(m['result'] in ('killed', 'survived', 'timeout') for m in res)
    print(f'{fid} {half} seed={seed} {"DUMMY " if dummy else ""}raw {k}/{n} -> {p}')
    if half == 'tune' and not dummy:
        for m in res:
            if m['result'] in ('survived', 'timeout'):
                print('  SURV', m['family'], m['op'], m['edits'][0][0], [e[1] + 1 for e in m['edits']], '|', m['before'], '=>', m['after'], m['result'])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=('list', 'run'))
    ap.add_argument('folders', nargs='+')
    ap.add_argument('--seed', type=int, required=True)
    ap.add_argument('--half', choices=('tune', 'held'))
    ap.add_argument('--target', type=int, default=48)
    ap.add_argument('-j', type=int, default=2)
    ap.add_argument('--out', default=os.environ.get('AA_S138_PRIVATE', os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))), 's138_private')))   # outside the checkout: held results stay out of git
    ap.add_argument('--dummy', action='store_true')
    ap.add_argument('--timeout', type=int, default=30, help='per-run test timeout in s; must be the value sealed for the folder before any mutant runs (VV.md rule v1 timeouts)')
    a = ap.parse_args()
    sm.TIMEOUT = a.timeout
    if a.cmd == 'list':
        for fid in a.folders:
            P, nseen = pools(fid, a.seed)
            print(fid, 'seen->tune', nseen, ' '.join(f"{h}:{f}={len(P[(h, f)])}" for h in ('tune', 'held') for f in FAMS), flush=True)
        return
    for fid in a.folders:
        run(fid, a.seed, a.half, a.target, a.j, a.out, a.dummy)


if __name__ == '__main__':
    main()
