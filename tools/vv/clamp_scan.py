#!/usr/bin/env python3
"""Repo-wide text scan for clamp / saturation code (decision 2026-10-09 ~17:37).

Why: --proof-warnings cannot flag a dead branch inside a separate saturating helper, because gnatprove
analyses each subprogram on its own; the branch is dead only from the callers' context (H146:
Maximum_Subarray.Add, Maximum_Product_Subarray.Multiply).  So clamps are found by text and reviewed.

Patterns (library sources only; tests.adb, own_checks.adb, tests/ and proof-only harnesses skipped):
  attr_return   a branch (if / elsif / else / case alternative) whose body returns or assigns T'Last / T'First
  const_return  `if <expr> <cmp> <literal or T'Last/'First> then` followed within 3 lines by `return` /
                `:=` of a literal or T'Last / T'First (cap or floor on a range test)
  min_max_clip  T'Min / T'Max / Integer'Min ... with a literal or T'Last / T'First argument (clipping a result)
  saturating    a subprogram whose name says it saturates (Sat_*, *_Sat, Saturat*, Clamp*, Clip*)
Each hit: folder, file:line, helper (enclosing subprogram), callers (other lines in the folder that name the
helper), reachable (yes / no / unknown), evidence.  Reviews live in tools/vv/clamp_review.csv (folder, file_line,
reachable, evidence); a hit without a review stays reachable = unknown.  tools/proof_index.py and
tools/vv/recount_strict.py hold a folder out of training_ready while it has a hit that is not reviewed
reachable = yes (unreviewed or dead).
usage: clamp_scan.py [--out tools/vv/clamp_scan.csv]
"""
import argparse, csv, glob, os, re, subprocess
ROOT = subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip()
VV = os.path.join(ROOT, 'tools', 'vv')
ap = argparse.ArgumentParser(); ap.add_argument('--out', default=os.path.join(VV, 'clamp_scan.csv'))
a = ap.parse_args()

SKIP_FILE = re.compile(r'^(tests?|own_checks|test_.*|.*_tests?|driver|harness|main)\.ad[bs]$', re.I)
ATTR = r"[\w.]+'(?:Last|First)"
LIT = r"-?\s*\d[\d_]*(?:\.\d[\d_]*)?"
VAL = rf"(?:{ATTR}|{LIT})"
SUBP = re.compile(r'^\s*(?:overriding\s+)?(?:function|procedure)\s+(\w+)', re.I)
SAT_NAME = re.compile(r'^(sat_(add|sub|mul|plus|minus|inc|dec|times)\w*|\w+_sat|saturat\w*|\w*clamp\w*|clip\w*|\w*_capped|cap_\w+|bounded_(add|sub|mul)\w*)$', re.I)

def strip(l):
    l = re.sub(r'"[^"]*"', '""', l)
    return l.split('--')[0]

def scan_file(path):
    lines = open(path, errors='replace').read().split('\n')
    code = [strip(l) for l in lines]
    hits, cur = [], ''
    for i, c in enumerate(code):
        m = SUBP.match(c)
        if m:
            cur = m.group(1)
            if SAT_NAME.match(cur) and not c.rstrip().endswith(';'):
                hits.append((i, cur, 'saturating', c.strip()))
        s = c.strip()
        if not s:
            continue
        prev = ' '.join(x.strip() for x in code[max(0, i - 3):i])
        # attr_return: return / assignment of T'Last / T'First in a branch body
        if re.search(rf"^(return\s+{ATTR}\s*;|\w[\w.() ]*:=\s*{ATTR}\s*;)", s, re.I) and \
                re.search(r'\b(then|else|=>)\s*$', prev, re.I):
            hits.append((i, cur, 'attr_return', s))
            continue
        # const_return: if <cmp> literal then  ... return/assign literal
        m1 = re.search(rf"^(?:return\s+({VAL})\s*;|\w[\w.() ]*:=\s*({VAL})\s*;)", s, re.I)
        if m1:
            v = re.sub(r'\s', '', (m1.group(1) or m1.group(2))).lower()
            m2 = re.search(rf"\b(?:if|elsif)\s+[^;]*?(?:>=?|<=?)\s*({VAL})\s*then\s*$", prev, re.I)
            if m2 and re.sub(r'\s', '', m2.group(1)).lower() == v:   # cap / floor: returns the bound it tested
                hits.append((i, cur, 'const_return', s))
                continue
        # min_max_clip (statement joined up to its ';')
        if re.search(r"'(?:Min|Max)\b", s, re.I):
            j, st = i, s
            while ';' not in st and j + 1 < len(code) and j - i < 6:
                j += 1; st += ' ' + code[j].strip()
            if re.search(rf"'(?:Min|Max)\s*\(\s*{VAL}\s*,|'(?:Min|Max)\s*\([^;]*?,\s*{VAL}\s*\)", st, re.I):
                hits.append((i, cur, 'min_max_clip', st))
    return lines, hits

review = {}
rp = os.path.join(VV, 'clamp_review.csv')
if os.path.exists(rp):
    for r in csv.DictReader(open(rp)):
        review[(r['folder'], r['file_line'])] = r

rows = []
for d in sorted(glob.glob(os.path.join(ROOT, '*', '*', '*') + '/')):
    fid = os.path.relpath(d, ROOT).rstrip('/')
    if fid.count('/') != 2 or fid.startswith(('tools/', 'docs/', 'vv/')):
        continue
    srcs = [p for p in glob.glob(os.path.join(d, '**', '*.ad[bs]'), recursive=True)
            if not SKIP_FILE.match(os.path.basename(p)) and '/tests/' not in p and '/obj/' not in p and '/gnatprove/' not in p]
    alltext = {p: open(p, errors='replace').read().split('\n') for p in glob.glob(os.path.join(d, '**', '*.ad[bs]'), recursive=True)
               if '/obj/' not in p and '/gnatprove/' not in p}
    for p in sorted(srcs):
        if not p.endswith('.adb'):
            continue
        lines, hits = scan_file(p)
        rel = os.path.relpath(p, d)
        for i, helper, kind, text in hits:
            callers = []
            if helper:
                pat = re.compile(rf'\b{re.escape(helper)}\b', re.I)
                for q, ql in alltext.items():
                    for j, l in enumerate(ql):
                        sl = strip(l)
                        if pat.search(sl) and not SUBP.match(sl) and not re.match(rf'^\s*end\s+{re.escape(helper)}\b', sl, re.I):
                            callers.append(f'{os.path.relpath(q, d)}:{j + 1}')
            fl = f'{rel}:{i + 1}'
            rv = review.get((fid, fl), {})
            rows.append(dict(folder=fid, file_line=fl, kind=kind, helper=helper, text=text[:160],
                             callers=' '.join(callers[:12]) + (' ...' if len(callers) > 12 else ''),
                             reachable=rv.get('reachable', 'unknown') or 'unknown', evidence=rv.get('evidence', '')))
with open(a.out, 'w', newline='') as f:
    w = csv.DictWriter(f, ['folder', 'file_line', 'kind', 'helper', 'text', 'callers', 'reachable', 'evidence'], lineterminator='\n')
    w.writeheader(); w.writerows(rows)
from collections import Counter
print(len(rows), 'hits in', len({r['folder'] for r in rows}), 'folders;', dict(Counter(r['kind'] for r in rows)), dict(Counter(r['reachable'] for r in rows)))
