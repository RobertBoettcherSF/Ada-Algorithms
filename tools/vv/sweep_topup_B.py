#!/usr/bin/env python3
"""Held-out top-up for sweep B folders whose held-out half has fewer than 20
non-equivalent mutants (docs/VV.md 3i: top up until the floor is met, then score).

The split rounds used every std and alt candidate of a folder (tune half seen,
held half already scored). This top-up draws only mutants that are in NEITHER
list, from a third operator family never used in the split rounds:
* variable replacement: one use of a declared variable, parameter or loop
  variable on a statement line replaced by another such name of the file
  (ghost declarations excluded; type errors are stillborn and not scored);
* loop direction: "in reverse" -> "in", and "in" -> "in reverse";
* 'Max <-> 'Min;
* return value: "return E;" -> "return E + 1;";
then, if still short, second-order pairs and third-order triples of std
mutants (sweep_heldout_alt.extra_pairs, fresh Random(seed + 2)). Every edit
key that occurs in the std or alt candidate lists is excluded, so no top-up
mutant was seen during tuning.

Scoring is raw (no equivalence exclusion, timeouts count as survivors) with
sweep_mutate.one, until --target scored mutants or the generator is exhausted.
The sealed detail file stores operator and result only (line and text hidden).

usage: sweep_topup_B.py FOLDER... --seed S [--target 30] [-j 4] --out X.csv
Run it from a clean `git archive` of the commit under test.
"""
import argparse, csv, os, random, shutil, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sweep_mutate as sm
import sweep_mutate_strict as sms
import sweep_heldout_alt as sha
import mutate


import re

DECL_LINE = re.compile(r'^\s*(function|procedure|type|subtype|package|is\b|end\b|begin\b|private\b|with\b|use\b)', re.I)
LOCAL = re.compile(r'^\s*([A-Za-z]\w*(?:\s*,\s*[A-Za-z]\w*)*)\s*:\s*(?!=)', re.I)
PARAM = re.compile(r'([A-Za-z]\w*(?:\s*,\s*[A-Za-z]\w*)*)\s*:\s*(?:in\s+out\s+|in\s+|out\s+)?[A-Za-z]', re.I)
LOOPV = re.compile(r'\bfor\s+([A-Za-z]\w*)\s+in\b', re.I)
KEYW = {'in', 'out', 'is', 'for', 'loop', 'if', 'then', 'else', 'elsif', 'end', 'return', 'and', 'or', 'not',
        'reverse', 'begin', 'declare', 'null', 'others', 'when', 'case', 'mod', 'rem', 'abs', 'xor', 'constant'}


def var_sites(path):
    lines = open(path, errors='replace').read().split('\n')
    names = set()
    for line in lines:
        code = line.split('--')[0]
        if re.search(r'\bGhost\b', code):
            continue
        m = LOCAL.match(code)
        if m and not DECL_LINE.match(code):
            names.update(x.strip() for x in m.group(1).split(','))
        if re.match(r'\s*(function|procedure)\b', code, re.I):
            for pm in PARAM.finditer(code[code.find('('):] if '(' in code else ''):
                names.update(x.strip() for x in pm.group(1).split(','))
        for lm in LOOPV.finditer(code):
            names.add(lm.group(1))
    names = sorted(n for n in names if n.lower() not in KEYW)
    out, in_pragma = [], False
    for ln, line in enumerate(lines):
        code = line.split('--')[0]
        starts = bool(re.match(r'\s*pragma\b', code, re.I))
        skip = in_pragma or starts
        if (in_pragma or starts) and ';' not in code:
            in_pragma = True
        elif ';' in code:
            in_pragma = False
        if skip or mutate.SKIP_LINE.search(code) or code.count('"') or DECL_LINE.match(code) \
                or (LOCAL.match(code) and not LOOPV.search(code)) or re.search(r'\bGhost\b', code):
            continue
        for n in names:
            for m in re.finditer(r'(?<![\w.\'])' + re.escape(n) + r'(?![\w\'])(?!\s*=>)', code, re.I):
                if LOOPV.search(code) and code[:m.start()].rstrip().lower().endswith('for'):
                    continue
                for o in names:
                    if o.lower() != n.lower():
                        out.append((ln, m.start(), m.end(), f'replace variable {n} -> {o}', o))
        for m in re.finditer(r'\bin\s+reverse\b', code, re.I):
            out.append((ln, m.start(), m.end(), 'loop direction reverse -> forward', 'in'))
        for m in re.finditer(r'(?<=\bfor\s)\s*[A-Za-z]\w*\s+in\b(?!\s+reverse)', code, re.I):
            out.append((ln, m.end() - 2, m.end(), 'loop direction forward -> reverse', 'in reverse'))
        for m in re.finditer(r"'(Max|Min)\b", code):
            out.append((ln, m.start(), m.end(), f"'{m.group(1)} -> '{'Min' if m.group(1) == 'Max' else 'Max'}",
                        "'Min" if m.group(1) == 'Max' else "'Max"))
        m = re.search(r'\breturn\s+([^;]+);', code, re.I)
        if m:
            out.append((ln, m.end(1), m.end(1), 'return value + 1', ' + 1'))
    return out


def fresh(src, seed, want, split_rng_seed):
    seen = set()
    for fam in ('std', 'alt'):
        # the same Random(seed + 1) as sweep_mutate.py used for the split rounds,
        # so the alt second-order pairs excluded here are exactly the ones drawn there
        for c in sm.candidates(src, fam, random.Random(split_rng_seed + 1)):
            seen.add(sha.key_of(c))
            if len(c[1]) == 1:
                seen.add(('std',) + tuple(c[1][0]))
    out = []
    var = [(name, [(rel, ln, c0, c1, rep)]) for rel in sm.lib_files(src)
           for (ln, c0, c1, name, rep) in var_sites(os.path.join(src, rel))]
    var = [c for c in var if sha.key_of(c) not in seen]
    random.Random(seed).shuffle(var)
    out += var
    rng = random.Random(seed + 2)
    for _ in range(4):
        more = [c for c in sha.extra_pairs(src, rng, seen, want - len(out) + 5) if len(c[1]) >= 2]
        out += [c for c in more if sha.key_of(c) not in {sha.key_of(o) for o in out}]
        if len(out) >= want or not more:
            break
    return out   # var family first (shuffled), higher-order std combinations after it


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
    row['family'] = 'topup var+higher-order (unseen)'
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
            det.append(dict(folder=fid, seed=a.seed, op=(name.split(' ->')[0].split(' + ')[0] if len(edits) == 1 else 'std combination') + ' (order ' + str(len(edits)) + ')',
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
    ap.add_argument('--work', default=os.path.join(tempfile.gettempdir(), 'topupB_work'))
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
