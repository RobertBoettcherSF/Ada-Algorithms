#!/usr/bin/env python3
"""Held-out mutant set with operators that sweep_mutate.py does not use:
statement deletion (single-line assignment -> null;), condition negation
(if/elsif/while/exit when C -> not (C)), True<->False, integer literal
0->1, 1->0, 1->2. Library .adb files only (same file filter as
sweep_mutate.py); lines with string literals and comment text are skipped.
Seeded sample; same build/run as /tmp/flag_mutate.py (timeouts separate)."""
import sys, os, re, random, csv, shutil, argparse
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, '/workspace/aa-flag/tools/vv')
import sweep_mutate as sm
import importlib.util
spec = importlib.util.spec_from_file_location('fm', '/tmp/flag_mutate.py'); fm = importlib.util.module_from_spec(spec); spec.loader.exec_module(fm)

def sites(path):
    out = []
    lines = open(path, errors='replace').read().split('\n')
    for ln, raw in enumerate(lines):
        code = raw.split('--')[0]
        if '"' in code or "'" in code.replace("'Image", "").replace("'Length", "").replace("'First", "").replace("'Last", "").replace("'Range", "").replace("'Old", "").replace("'Result", "").replace("'Max", "").replace("'Min", "").replace("'Pos", "").replace("'Val", ""):
            pass
        if '"' in code or not code.strip():
            continue
        m = re.match(r'^(\s*)([A-Za-z_][\w.]*(\s*\([^;]*\))?)\s*:=\s*[^;]*;\s*$', code)
        if m and not re.match(r'^\s*(for|while|if|elsif|return|when)\b', code) and ':' not in code.replace(':=', ''):
            out.append((ln, 'delete assignment', m.group(1) + 'null;'))
        for kw, end in (('if', 'then'), ('elsif', 'then'), ('while', 'loop')):
            m = re.match(r'^(\s*)' + kw + r'\s+(.+?)\s+' + end + r'\s*$', code)
            if m:
                out.append((ln, f'negate {kw}', f'{m.group(1)}{kw} not ({m.group(2)}) {end}'))
        m = re.match(r'^(\s*)exit when\s+(.+);\s*$', code)
        if m:
            out.append((ln, 'negate exit when', f'{m.group(1)}exit when not ({m.group(2)});'))
        for word, rep in (('True', 'False'), ('False', 'True')):
            for mm in re.finditer(r'\b' + word + r'\b', code):
                out.append((ln, f'{word}->{rep}', code[:mm.start()] + rep + code[mm.end():]))
        for mm in re.finditer(r'(?<![\w.#\'])([01])(?![\w.#])', code):
            for rep in (['1'] if mm.group(1) == '0' else ['0', '2']):
                out.append((ln, f'{mm.group(1)}->{rep}', code[:mm.start()] + rep + code[mm.end():]))
    return out

def one(args):
    src, w, rel, ln, name, newline = args
    shutil.rmtree(w, ignore_errors=True); shutil.copytree(src, w, ignore=sm.IGN)
    p = os.path.join(w, rel); lines = open(p, errors='replace').read().split('\n')
    orig = lines[ln]; lines[ln] = newline
    open(p, 'w').write('\n'.join(lines))
    r = fm.run_tests(w); shutil.rmtree(w, ignore_errors=True)
    return orig.strip()[:100], newline.strip()[:100], r

ap = argparse.ArgumentParser(); ap.add_argument('folders', nargs='+'); ap.add_argument('--max', type=int, default=40)
ap.add_argument('-j', type=int, default=4); ap.add_argument('--seed', type=int, default=20261108)
ap.add_argument('--out', required=True); ap.add_argument('--work', required=True)
a = ap.parse_args(); rows = []; detail = []
for fid in a.folders:
    src = os.path.join(sm.ROOT, fid); wk = os.path.join(a.work, fid.replace('/', '_'))
    cand = [(rel,) + s for rel in sm.lib_files(src) for s in sites(os.path.join(src, rel))]
    pick = random.Random(a.seed).sample(cand, min(a.max, len(cand)))
    jobs = [(src, f'{wk}/m{i}', rel, ln, name, nl) for i, (rel, ln, name, nl) in enumerate(pick)]
    with ThreadPoolExecutor(a.j) as ex: res = list(ex.map(one, jobs))
    c = {k: sum(r[2] == k for r in res) for k in ('killed', 'survived', 'stillborn', 'timeout')}
    for (rel, ln, name, nl), (b, af, r) in zip(pick, res):
        detail.append(dict(folder=fid, file=rel, line=ln + 1, op=name, before=b, after=af, result=r))
    rows.append(dict(folder=fid, sites=len(cand), mutants=len(pick), **c))
    print(fid, len(cand), c, flush=True)
with open(a.out, 'w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
with open(a.out.replace('.csv', '_detail.csv'), 'w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=list(detail[0].keys())); w.writeheader(); w.writerows(detail)
