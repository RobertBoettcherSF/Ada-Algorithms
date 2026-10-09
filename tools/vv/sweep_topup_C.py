#!/usr/bin/env python3
"""Held-out top-up, family C (docs/VV.md 3i), for folders whose held halves plus
the sweep_topup_B.py pool stay below 20 non-equivalent mutants.

A fourth operator family, never used in tuning, the split rounds or top-up B:
* subscript / argument off-by-one: one top-level actual of a call or array
  subscript "N (..., E, ...)" becomes "E + 1" or "E - 1";
* swapped actuals: the first two top-level actuals of a call are exchanged;
* mod <-> rem;
* boundary attribute +-1: X'First -> X'First + 1, X'Last -> X'Last - 1.
Sites: the library .adb files and, unlike the earlier families, the
library .ads files (expression-function bodies, private part); lines with
Pre / Post / invariants / predicates / Global / Depends, pragmas, comments
and declarations are skipped.

Unseen by construction: a family C mutant is dropped when the mutated file
text equals the text of any std or alt candidate (split rounds, same
Random(split seed + 1)) or any top-up B variable / loop / 'Max / return
mutant of that file. Scoring is raw (equivalents not excluded here,
timeouts count as survivors) with sweep_mutate.one, until --target scored
mutants or the pool is exhausted. The sealed detail file stores operator
and result only.

usage: sweep_topup_C.py FOLDER... --seed S [--target 30] [-j 2] --out X.csv
Run the copy inside a clean `git archive` of the commit under test (the
repo root is taken from the script's location, as in sweep_topup_B.py).
"""
import argparse, csv, os, random, re, shutil, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sweep_mutate as sm
import sweep_mutate_strict as sms
import sweep_topup_B as tb
import mutate

SKIP = re.compile(r'\b(Pre|Post|Type_Invariant|Invariant|Dynamic_Predicate|Static_Predicate|Predicate|Global|Depends|'
                  r'Contract_Cases|Loop_Invariant|Loop_Variant|Ghost)\b|^\s*pragma\b', re.I)
DECL = re.compile(r'^\s*(function|procedure|type|subtype|package|with|use|end|private|is|begin)\b', re.I)
KEYW = {'if', 'and', 'or', 'not', 'then', 'else', 'elsif', 'return', 'in', 'when', 'mod', 'rem', 'abs', 'xor',
        'loop', 'case', 'others', 'for', 'all', 'some', 'of', 'new', 'null', 'delta', 'with'}
CALL = re.compile(r'([A-Za-z]\w*(?:\.[A-Za-z]\w*)*)\s*\(')


def lib_all(src):
    for d, dirs, fs in os.walk(src):
        dirs[:] = [x for x in dirs if x not in ('obj', 'bin', 'gnatprove', 'tests', 'tools')]
        for f in sorted(fs):
            if (f.endswith('.adb') or f.endswith('.ads')) and not sm.TESTNAME.match(f):
                yield os.path.relpath(os.path.join(d, f), src)


def top_args(code, open_pos):
    """(start, end) spans of the top-level actuals of the paren at open_pos, or None."""
    depth, spans, start = 0, [], open_pos + 1
    for i in range(open_pos, len(code)):
        ch = code[i]
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
            if depth == 0:
                spans.append((start, i))
                return spans
        elif ch == ',' and depth == 1:
            spans.append((start, i)); start = i + 1
    return None


def c_sites(path):
    out, in_aspect = [], False
    for ln, line in enumerate(open(path, errors='replace').read().split('\n')):
        code = line.split('--')[0]
        if in_aspect:                                      # continuation of a contract / pragma
            in_aspect = not code.rstrip().endswith(';')
            continue
        if SKIP.search(code):
            in_aspect = not code.rstrip().endswith(';')
            continue
        if not code.strip() or DECL.match(code) or '"' in code:
            continue
        if re.search(r'(?<![:=/<>])\s:\s', code):          # object / parameter declaration
            continue
        for m in CALL.finditer(code):
            if m.group(1).lower() in KEYW or code[:m.start()].rstrip().endswith("'"):
                continue
            spans = top_args(code, m.end() - 1)
            if not spans:
                continue
            texts = [code[a:b] for a, b in spans]
            if any('=>' in t or not t.strip() for t in texts):
                continue
            for (a, b), t in zip(spans, texts):
                lead = len(t) - len(t.lstrip()); a2, b2 = a + lead, a + len(t.rstrip())
                core = code[a2:b2]
                if re.search(r'\b(and|or|xor|in)\b|[<>=]', core):
                    continue
                out.append((ln, a2, b2, f'actual off-by-one +1', core + ' + 1'))
                out.append((ln, a2, b2, f'actual off-by-one -1', core + ' - 1'))
            if len(spans) >= 2:
                (a1, b1), (a2, b2) = spans[0], spans[1]
                t1, t2 = code[a1:b1].strip(), code[a2:b2].strip()
                if t1 != t2:
                    out.append((ln, a1, b2, 'swap first two actuals', f'{t2}, {t1}' if code[a1] != ' ' else f' {t2}, {t1}'))
        for m in re.finditer(r'\b(mod|rem)\b', code, re.I):
            out.append((ln, m.start(), m.end(), f'{m.group(1).lower()} -> {"rem" if m.group(1).lower() == "mod" else "mod"}',
                        'rem' if m.group(1).lower() == 'mod' else 'mod'))
        for m in re.finditer(r"'(First|Last)\b(?!\s*\()", code):
            out.append((ln, m.start(), m.end(), f"'{m.group(1)} +-1", f"'{m.group(1)}" + (' + 1' if m.group(1) == 'First' else ' - 1')))
    return out


def apply(text, edits):
    lines = text.split('\n')
    for (ln, c0, c1, rep) in sorted(edits, key=lambda e: (e[0], -e[1])):
        lines[ln] = lines[ln][:c0] + rep + lines[ln][c1:]
    return '\n'.join(lines)


def seen_texts(src, split_rng_seed):
    seen = {}
    def add(rel, edits):
        base = open(os.path.join(src, rel), errors='replace').read()
        seen.setdefault(rel, set()).add(apply(base, edits))
    for fam in ('std', 'alt'):
        for name, edits in sm.candidates(src, fam, random.Random(split_rng_seed + 1)):
            rels = {e[0] for e in edits}
            if len(rels) == 1:
                add(edits[0][0], [tuple(e[1:]) for e in edits])
    for rel in sm.lib_files(src):
        for (ln, c0, c1, name, rep) in tb.var_sites(os.path.join(src, rel)):
            add(rel, [(ln, c0, c1, rep)])
    return seen


def fresh(src, seed, split_rng_seed):
    seen = seen_texts(src, split_rng_seed)
    out, texts = [], set()
    for rel in lib_all(src):
        base = open(os.path.join(src, rel), errors='replace').read()
        for (ln, c0, c1, name, rep) in c_sites(os.path.join(src, rel)):
            t = apply(base, [(ln, c0, c1, rep)])
            if t == base or t in seen.get(rel, ()) or (rel, t) in texts:
                continue
            texts.add((rel, t))
            out.append((name, [(rel, ln, c0, c1, rep)]))
    random.Random(seed).shuffle(out)
    return out


def run_folder(fid, a, ver):
    src = os.path.join(sm.ROOT, fid)
    wk = os.path.join(a.work, fid.replace('/', '_'))
    shutil.rmtree(wk, ignore_errors=True)
    shutil.copytree(src, wk + '/base', ignore=sm.IGN)
    base = sms.run_tests(wk + '/base')
    row = dict(folder=fid, family='topup C: actual +-1, swapped actuals, mod/rem, First/Last +-1 (unseen)', seed=a.seed,
               baseline=('pass' if base == 'survived' else base), pool=0, drawn=0, killed=0,
               survived=0, timeout=0, stillborn=0, scored=0, score='', pct='', compiler=ver)
    if base != 'survived':
        return row, []
    cand = fresh(src, a.seed, a.split_rng_seed)
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
            det.append(dict(folder=fid, seed=a.seed, op=name, line='hidden', result=r))
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
    ap.add_argument('--split-rng-seed', type=int, default=20261008)
    ap.add_argument('-j', type=int, default=2)
    ap.add_argument('--out', required=True)
    ap.add_argument('--work', default=os.path.join(tempfile.gettempdir(), 'topupC_work'))
    ap.add_argument('--list', action='store_true', help='print the pool size per folder and exit (no tests run)')
    a = ap.parse_args()
    if a.list:
        for fid in a.folders:
            c = fresh(os.path.join(sm.ROOT, fid), a.seed, a.split_rng_seed)
            print(fid, 'pool', len(c), sorted({n for n, _ in c}))
        return
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
