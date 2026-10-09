#!/usr/bin/env python3
"""Mutation score for the sweep's own tests (docs/VV.md 3i).

Like tools/vv/mutate.py (same operators, same test run with GNAT 14,
-gnat2022 -gnata), but only library code is mutated: .adb files that are
not tests*, own_checks*, main*, demo* and not under obj/, bin/ or tests/.
(mutate.py also samples obj/b__*.adb binder files and own_checks.adb, whose
mutants say nothing about the code under test.) Up to --max mutants per
folder (seeded sample of all sites), run in parallel.

usage: sweep_mutate.py FOLDER... [--max 40] [-j 6] [--out file.csv]
       [--family std|alt] [--split-seed N --half tune|held]
kill_kind=uninit: a survivor of the normal run that dies under Initialize_Scalars+-gnatVa (assignment deletion) counts as killed.\nHeld-out rule (docs/VV.md 3i): for a new folder, split with a recorded
--split-seed before writing tests, look only at --half tune survivors, score
the bar on --half held (survivor lines are hidden in the detail file); top the
held half up to >= 20 non-equivalent mutants with --family alt.
"""
import argparse, csv, os, random, re, shutil, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mutate, subprocess, hashlib

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
    r = mutate.run_limited(['./tbin'], work, 30)   # timeout kills the whole process group
    if r is None:
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
        # tools/: a folder's own developer programs (Modular-Arithmetic's tools/mutate.adb), not library code
        dirs[:] = [x for x in dirs if x not in ('obj', 'bin', 'gnatprove', 'tests', 'tools')]
        for f in sorted(fs):
            if f.endswith('.adb') and not TESTNAME.match(f):
                yield os.path.relpath(os.path.join(d, f), src)

def one(args):
    # (src, work, op_name, edits) with edits = [(rel, ln, c0, c1, rep)], one
    # per line (second-order: two). Older forms still accepted:
    #   (src, work, edits) or (src, work, rel, ln, c0, c1, rep).
    op_name = ''
    if len(args) == 7:
        src, w, rel, ln, c0, c1, rep = args
        edits = [(rel, ln, c0, c1, rep)]
    elif len(args) == 4:
        src, w, op_name, edits = args
    else:
        src, w, edits = args
    shutil.rmtree(w, ignore_errors=True); shutil.copytree(src, w, ignore=IGN)
    if DUMMY:
        mutate.make_dummy(w)
    befores, afters = [], []
    for rel, ln, c0, c1, rep in edits:
        path = os.path.join(w, rel)
        lines = open(path, errors='replace').read().split('\n')
        orig = lines[ln]; lines[ln] = orig[:c0] + rep + orig[c1:]
        open(path, 'w').write('\n'.join(lines))
        befores.append(orig.strip()[:100]); afters.append(lines[ln].strip()[:100])
    res = run_tests(w)
    kill_kind = ''
    if res == 'survived':
        # statement-deletion survivors: Init_Scalars+-gnatVa may expose uninit use
        ck = mutate.recheck_uninit(w, op_name, ' || '.join(afters))
        if ck:
            res, kill_kind = ck
    shutil.rmtree(w, ignore_errors=True)
    return ' || '.join(befores), ' || '.join(afters), res, kill_kind

# Alternative operator family (docs/VV.md 3i, held-out sets for small folders):
# statement deletion, integer-constant replacement, argument swap, and
# second-order mutants (two standard mutants on different lines).
ALT_STMT = re.compile(r'^(\s*)([A-Za-z_][\w.]*(?:\s*\([^;]*\))?\s*:=\s*[^;]+;)\s*(--.*)?$')
ALT_INT = re.compile(r'(?<![\w.#\'])(\d+)(?![\w.#])')
ALT_SWAP = re.compile(r'\(\s*([A-Za-z_][\w.]*)\s*,\s*([A-Za-z_][\w.]*)\s*\)')

def alt_sites(path):
    out = []
    in_pragma = False
    for ln, line in enumerate(open(path, errors='replace').read().split('\n')):
        code = line.split('--')[0]
        starts = bool(re.match(r'\s*pragma\b', code, re.I))
        skip = in_pragma or starts
        if (in_pragma or starts) and ';' not in code:
            in_pragma = True
        elif ';' in code:
            in_pragma = False
        if skip or mutate.SKIP_LINE.search(code) or code.count('"') or re.search(r'\b(constant|range|array|type|subtype)\b', code, re.I):
            continue
        m = ALT_STMT.match(code)
        if m and not re.match(r'\s*\w+\s*:\s', code):          # an assignment statement, not a declaration
            out.append((ln, m.start(2), m.end(2), 'delete statement', 'null;'))
        for m in ALT_INT.finditer(code):
            n = int(m.group(1))
            for r in sorted({n + 1, n - 1, 0} - {n, -1}):
                out.append((ln, m.start(1), m.end(1), f'constant {n} -> {r}', str(r)))
        for m in ALT_SWAP.finditer(code):
            if m.group(1) != m.group(2) and not re.search(r'\b(in|loop|range)\b', code[:m.start()].split(';')[-1][-6:]):
                out.append((ln, m.start(), m.end(), 'swap arguments', f'({m.group(2)}, {m.group(1)})'))
    return out

def split_half(src, cand, seed):
    """'tune' or 'held' for one candidate (name, edits). Keyed on the seed and
    the mutated line's text, column, operator and replacement (not on list
    position), so a fix elsewhere in the folder does not move mutants between
    the halves; a mutant on an edited line gets a new key."""
    key = [str(seed), cand[0]]
    for rel, ln, c0, c1, rep in cand[1]:
        text = open(os.path.join(src, rel), errors='replace').read().split('\n')[ln]
        key += [rel, text.strip(), str(c0 - (len(text) - len(text.lstrip()))), text[c0:c1], rep]
    return 'held' if int(hashlib.sha256('\x1f'.join(key).encode()).hexdigest(), 16) % 2 else 'tune'

def candidates(src, family, rng):
    """List of (name, [edits]) for the folder's library code."""
    std = [(name, [(rel, ln, c0, c1, rep)]) for rel in lib_files(src)
           for (ln, c0, c1, name, rep) in mutate.sites(os.path.join(src, rel))]
    if family == 'std':
        return std
    alt = [(name, [(rel, ln, c0, c1, rep)]) for rel in lib_files(src)
           for (ln, c0, c1, name, rep) in alt_sites(os.path.join(src, rel))]
    # second-order: random pairs of standard mutants on different lines (as many as std sites)
    pairs = []
    for _ in range(len(std)):
        a, b = rng.sample(std, 2) if len(std) >= 2 else (None, None)
        if a and (a[1][0][0], a[1][0][1]) != (b[1][0][0], b[1][0][1]):
            pairs.append((a[0] + ' + ' + b[0], a[1] + b[1]))
    return alt + pairs

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('folders', nargs='+'); ap.add_argument('--max', type=int, default=40)
    ap.add_argument('-j', type=int, default=6); ap.add_argument('--seed', type=int, default=20261008)
    ap.add_argument('--out', default=os.path.join(tempfile.gettempdir(), 'sweep_mut.csv')); ap.add_argument('--work', default=os.path.join(tempfile.gettempdir(), 'sweep_mut'))
    ap.add_argument('--dummy', action='store_true', help='control (a): always-passing test that checks nothing; must score 0')
    ap.add_argument('--family', choices=('std', 'alt'), default='std',
                    help='std: mutate.py operators; alt: statement deletion, constant replacement, argument swap, second-order')
    ap.add_argument('--split-seed', type=int, default=None,
                    help='split the candidate list into two halves with this seed (record it); use with --half')
    ap.add_argument('--half', choices=('tune', 'held'), default=None,
                    help='tune: the half whose survivors may be looked at; held: the scoring half (survivor lines hidden)')
    a = ap.parse_args()
    VER = mutate.require_version(14)   # GNAT 14 only; the version goes into every row
    global DUMMY
    DUMMY = a.dummy
    rows, detail = [], []
    for fid in a.folders:
        src = os.path.join(ROOT, fid); wk = os.path.join(a.work, fid.replace('/', '_'))
        shutil.rmtree(wk, ignore_errors=True); shutil.copytree(src, wk + '/base', ignore=IGN)
        if DUMMY:
            mutate.make_dummy(wk + '/base')
        base = run_tests(wk + '/base')
        cand = candidates(src, a.family, random.Random(a.seed + 1))
        if a.split_seed is not None and a.half:
            cand = [c for c in cand if split_half(src, c, a.split_seed) == a.half]
        rng = random.Random(a.seed)
        pick = rng.sample(cand, min(a.max, len(cand))) if base == 'survived' else []
        jobs = [(src, f'{wk}/m{i}', name, edits) for i, (name, edits) in enumerate(pick)]
        with ThreadPoolExecutor(a.j) as ex:
            res = list(ex.map(one, jobs))
        hide = a.half == 'held'
        k = s = sb = to = 0
        for (name, edits), (b, af, r, kill_kind) in zip(pick, res):
            k += r == 'killed'; s += r == 'survived'; sb += r == 'stillborn'; to += r == 'timeout'
            detail.append(dict(folder=fid, file=edits[0][0],
                               line=('hidden' if hide else '+'.join(str(e[1] + 1) for e in edits)),
                               op=name, before=('hidden' if hide else b), after=('hidden' if hide else af),
                               result=r, kill_kind=kill_kind))
        score = '' if k + s + to == 0 else f'{k}/{k + s + to}'          # timeouts are not kills
        score_t = '' if k + s + to == 0 else f'{k + to}/{k + s + to}'   # reported both ways
        rows.append(dict(folder=fid, family=a.family, split_seed=('' if a.split_seed is None else a.split_seed), half=(a.half or ''),
                         seed=a.seed, baseline=('pass' if base == 'survived' else base), sites=len(cand), mutants=len(pick),
                         killed=k, survived=s, timeout=to, stillborn=sb, score=score, score_with_timeouts=score_t, compiler=VER))
        print(f"{fid:60s} base={rows[-1]['baseline']:8s} sites={len(cand):4d} killed={k} survived={s} timeout={to} stillborn={sb} score={score}", flush=True)
    with open(a.out, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
    if detail:
        with open(a.out.replace('.csv', '_detail.csv'), 'w', newline='') as f:
            w = csv.DictWriter(f, fieldnames=list(detail[0].keys())); w.writeheader(); w.writerows(detail)

if __name__ == '__main__':
    main()
