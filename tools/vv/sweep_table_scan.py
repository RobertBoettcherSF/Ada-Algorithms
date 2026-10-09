#!/usr/bin/env python3
"""Agent B (2026-10-09): scan library sources for lookup-table placeholders.

A. constant aggregates with >= MIN_LIT numeric literals (tables of data);
B. case statements / case expressions with >= MIN_ARMS arms that each give
   a literal answer (return L; X := L; or => L in a case expression);
C. folders whose tests.adb passes only numeric literals <= SMALL to the
   package while the package's input parameters use an unbounded integer
   type (Integer, Natural, Positive, Long_*), or whose spec narrows the
   input to an upper bound <= SMALL.
Test drivers (tests.adb, own_checks.adb, main.adb, tests/ dirs) are not
scanned for A/B. Prints CSV rows: folder,file,line,kind,detail.
"""
import os, re, sys, csv
MIN_LIT, MIN_ARMS, SMALL = 16, 6, 100
NUM = re.compile(r"(?<![\w.#])(?:\d[\d_]*#[0-9A-Fa-f_]+#|\d[\d_]*(?:\.\d[\d_]*)?(?:[eE][+-]?\d+)?)")
def strip_comments(t):
    out = []
    for line in t.split('\n'):
        s = re.sub(r'"(?:[^"]|"")*"', lambda m: ' ' * len(m.group(0)), line)
        i = s.find('--')
        out.append(line[:i] if i >= 0 else line)
    return '\n'.join(out)
def is_driver(path):
    b = os.path.basename(path).lower()
    return b in ('tests.adb', 'own_checks.adb', 'main.adb', 'test.adb') or '/tests/' in path or b.startswith('test_') or b.endswith('_tests.adb')
def folder_of(p):
    parts = p.split('/')
    return '/'.join(parts[:3])
rows = []
for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in ('.git', 'obj', 'bin', 'gnatprove', 'tools', 'alire')]
    for f in files:
        if not f.endswith(('.ads', '.adb')): continue
        p = os.path.join(root, f)[2:]
        if is_driver(p): continue
        t = strip_comments(open(p, errors='replace').read())
        # A: constant aggregates
        for m in re.finditer(r':\s*constant\b[^;]*?:=\s*([(\[])', t, re.S):
            start = m.end(1) - 1; depth = 0; i = start
            close = {'(': ')', '[': ']'}
            while i < len(t):
                c = t[i]
                if c in '([': depth += 1
                elif c in ')]':
                    depth -= 1
                    if depth == 0: break
                i += 1
            body = t[start:i + 1]
            n = len(NUM.findall(body))
            if n >= MIN_LIT:
                line = t[:m.start()].count('\n') + 1
                name = t[:m.start()].rsplit('\n', 1)[-1].strip().split(':')[0].strip()
                rows.append((folder_of(p), p, line, 'A constant aggregate', f'{name}: {n} literals'))
        # B: case with literal answers
        for m in re.finditer(r'\bcase\b(.*?)\bis\b', t, re.S):
            seg = t[m.end():m.end() + 6000]
            endm = re.search(r'\bend\s+case\b|\)\s*(?:;|$|with|\n)', seg)
            seg = seg[:endm.start()] if endm else seg
            arms = re.findall(r'\bwhen\b[^=]*=>\s*(.*?)(?=\bwhen\b|$)', seg, re.S)
            lit = [a for a in arms if re.fullmatch(r'\s*(?:return\s+)?(?:\w+\s*:=\s*)?-?\s*\(?\s*(?:\d[\d_#A-Fa-f.]*|True|False|\'.\')\s*\)?\s*[;,]?\s*', a)]
            if len(lit) >= MIN_ARMS:
                line = t[:m.start()].count('\n') + 1
                rows.append((folder_of(p), p, line, 'B case answer table', f'{len(lit)} of {len(arms)} arms give a literal'))
# C: small test inputs vs unbounded parameter types
for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in ('.git', 'obj', 'bin', 'gnatprove', 'tools', 'alire')]
    if 'tests.adb' not in files: continue
    fo = root[2:]
    specs = [os.path.join(root, f) for f in files if f.endswith('.ads')]
    spec = ' '.join(strip_comments(open(s, errors='replace').read()) for s in specs)
    small_sub = re.findall(r'subtype\s+(\w+)\s+is\s+\w+\s+range\s+[-\d_]+\s*\.\.\s*(\d[\d_]*)\s*;', spec)
    narrowed = [(n, int(b.replace('_', ''))) for n, b in small_sub if int(b.replace('_', '')) <= SMALL]
    params = re.findall(r'\(\s*\w+\s*:\s*(?:in\s+)?(Integer|Natural|Positive|Long_Integer|Long_Long_Integer)\b', spec)
    tt = strip_comments(open(os.path.join(root, 'tests.adb'), errors='replace').read())
    lits = [int(x.replace('_', '')) for x in re.findall(r'(?<![\w.#])\d[\d_]*(?![\w.#])', tt)]
    if params and lits and max(lits) <= SMALL:
        rows.append((folder_of(fo + '/x'), fo + '/tests.adb', 1, 'C small test inputs', f'unbounded params {sorted(set(params))}; largest literal in tests.adb {max(lits)}'))
    for n, b in narrowed:
        if re.search(r'\b(N|Number|Input|Value|X)\b', n):
            rows.append((folder_of(fo + '/x'), fo, 0, 'C narrowed input subtype', f'subtype {n} upper bound {b}'))
w = csv.writer(sys.stdout, lineterminator='\n')
w.writerow(['folder', 'file', 'line', 'kind', 'detail'])
for r in sorted(rows): w.writerow(r)
