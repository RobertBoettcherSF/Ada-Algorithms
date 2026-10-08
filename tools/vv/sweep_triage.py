#!/usr/bin/env python3
"""Whole-repo shortcut triage (docs/VV.md 3i).

Scans every folder in PROOFS.csv that has no own tests (column own_tests
empty) for the six shortcut patterns of the checklist and writes one row per
folder with a flag/count per pattern and a risk score; rows are sorted by
risk (rank 1 = look first). The greedy/shortest-path/optimisation family is
listed with family=other-worker and ranked last (it is covered elsewhere).

Library code = non-test .ads/.adb (not tests*, own_checks*, main*, demo*,
nor under tests/). Test/demo code = the rest.

Flags (counts of hits in library code unless noted):
  clamp         'Min/'Max against a literal or 'Last/'First, 'if X > L then X := L',
                Clamp/Saturat*/_Bounded helpers                       (pattern 1)
  early_exit    return/exit/null guarded by a capacity or emptiness test
                (Length/Count/Size/Last/Capacity/Is_Full/Is_Empty) in a
                subprogram with no Success/Ok/Found out parameter and no Pre (pattern 2)
  stub          README/comment says stub/placeholder/simplified/toy/lite/not
                implemented, raise Program_Error bodies, or library code < 25
                non-blank lines; index stub=yes counts too                (pattern 3)
  first_match   exit/return inside a loop of a subprogram named
                min/max/best/shortest/optimal/closest/longest/largest/
                smallest/minimum/maximum                                 (pattern 4)
  demo_literal  integer literals >= 3 in library bodies that also occur in the
                folder's test/demo literals and not in its specs           (pattern 5)
  warn_off      pragma Warnings (Off ...) / -gnatws in library code or build files (6)
  warn_off_tests  the same in test code (listed, lower weight)
  proof_escape  pragma Assume / pragma Annotate (GNATprove, ...)          (pattern 6)
  input_var     input-variation result from tools/vv/random_drive.csv
                (seeded random sizes and values, all checks on) and the
                do-nothing verdict from PROOFS.csv (weak = tests miss a trivial body)

usage: sweep_triage.py [--out tools/vv/sweep_triage.csv]
"""
import argparse, csv, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FAMILY = re.compile(r'dijkstra|bellman|floyd|kruskal|prim|boruvka|huffman|interval-sched|knapsack|coin-change|'
                    r'job-sched|a-star|astar|a\*|weighted-interval|activity-select|shortest-path|minimum-spanning|'
                    r'mst|johnson|spfa|greedy|fractional|travelling|traveling|tsp|branch-and-bound|'
                    r'simplex|linear-programming|optimi|uniform-cost|best-first|d-star|ida-star|jump-point', re.I)
TESTNAME = re.compile(r'^(tests?|own_checks|main|demo|run_|driver|harness|check_)', re.I)
MINMAX = re.compile(r'(min|max|best|shortest|optimal|closest|longest|largest|smallest|minimum|maximum)', re.I)

def strip(t):
    return '\n'.join(l.split('--')[0] for l in t.split('\n'))

def files(folder):
    lib, test, build, readme = [], [], [], ''
    for d, _, fs in os.walk(folder):
        if any(p in d for p in ('/obj', '/bin', '/gnatprove', '/.git')):
            continue
        for f in fs:
            p = os.path.join(d, f)
            if f.endswith(('.ads', '.adb')):
                (test if (TESTNAME.match(f) or '/tests' in d[len(folder):]) else lib).append(p)
            elif f in ('Makefile',) or f.endswith('.gpr'):
                build.append(p)
            elif f.lower() == 'readme.md' and d == folder:
                readme = open(p, errors='replace').read()
    return lib, test, build, readme

def read(ps):
    return {p: open(p, errors='replace').read() for p in ps}

def subprograms(text):
    """Yield (name, header, body) for each subprogram body (rough)."""
    for m in re.finditer(r'^\s*(?:overriding\s+)?(procedure|function)\s+(\w+)(.*?)\bis\b(?!\s*(?:new|<>|abstract|separate|null\s*;))', text, re.M | re.S | re.I):
        start = m.end()
        e = re.search(r'^\s*end\s+' + re.escape(m.group(2)) + r'\s*;', text[start:], re.M | re.I)
        body = text[start:start + e.start()] if e else text[start:start + 3000]
        yield m.group(2), m.group(3), body

LIT = re.compile(r'(?<![\w.#])(\d[\d_]*)(?![\w.#])')

def scan(folder, row):
    lib, test, build, readme = files(folder)
    L, T, B = read(lib), read(test), read(build)
    libs = {p: strip(t) for p, t in L.items()}
    f = dict(clamp=0, early_exit=0, stub=0, first_match=0, demo_literal=0, warn_off=0,
             warn_off_tests=0, proof_escape=0)
    notes = []
    for p, t in libs.items():
        body = p.endswith('.adb')
        f['clamp'] += len(re.findall(r"'(?:Min|Max)\s*\([^;]*?(?:\b\d[\d_]*\b|'Last|'First)", t))
        f['clamp'] += len(re.findall(r'\bif\s+(\w+)\s*>=?\s*(\w+)\s+then\s+\1\s*:=\s*\2\s*;', t, re.I))
        f['clamp'] += len(re.findall(r'\b(?:Clamp\w*|Saturat\w*|\w+_Bounded)\s*\(', t))
        f['warn_off'] += len(re.findall(r'pragma\s+Warnings\s*\(\s*Off', t, re.I))
        f['proof_escape'] += len(re.findall(r'pragma\s+(?:Assume|Annotate\s*\(\s*GNATprove)', t, re.I))
        f['stub'] += len(re.findall(r'raise\s+Program_Error\s*(?:with\s+"[^"]*(?:not\s+impl|todo|stub)[^"]*")?\s*;', t, re.I)) if body else 0
        if not body:
            continue
        for name, hdr, sb in subprograms(t):
            has_success = re.search(r'\b(Success|Ok|Found|Valid|Status|Done)\s*:\s*(?:in\s+)?out\b', hdr, re.I)
            has_pre = re.search(r'\bPre\b', hdr)
            if not has_success and not has_pre:
                g = re.findall(r'\bif\s+[^;]*?\b(Length|Count|Size|Last|Capacity|Is_Full|Is_Empty|Top|Free)\b[^;]*?\bthen\s+(?:return|null)\b', sb, re.I | re.S)
                f['early_exit'] += len(g)
            if MINMAX.search(name):
                for loop in re.finditer(r'\bloop\b(.*?)\bend\s+loop\b', sb, re.S | re.I):
                    if re.search(r'\bexit\s+when\b|\breturn\b', loop.group(1), re.I):
                        f['first_match'] += 1; notes.append(f'first-match in {name}')
                        break
    for p, t in read(lib).items():
        pass
    for p, t in T.items():
        f['warn_off_tests'] += len(re.findall(r'pragma\s+Warnings\s*\(\s*Off', strip(t), re.I))
    for p, t in B.items():
        if re.search(r'-gnatws\b|-gnatwn\b', t):
            f['warn_off'] += 1; notes.append('warnings off in ' + os.path.basename(p))
    # comments/readme stub wording
    words = re.compile(r'\b(stub|placeholder|simplified|toy|teaching stub|not implemented|lite version|deliberately tiny|for brevity|hard-?coded)\b', re.I)
    if words.search(readme) or any(words.search(t) for t in L.values()):
        f['stub'] += 1
    nlines = sum(1 for t in libs.values() for l in t.split('\n') if l.strip())
    if nlines and nlines < 25:
        f['stub'] += 1; notes.append(f'{nlines} library lines')
    if row.get('stub') == 'yes':
        f['stub'] += 1
    # demo literals
    spec_lits = {m for p, t in libs.items() if p.endswith('.ads') for m in LIT.findall(t)}
    test_lits = {m for t in T.values() for m in LIT.findall(strip(t))}
    body_lits = {m for p, t in libs.items() if p.endswith('.adb') for m in LIT.findall(t)}
    demo = sorted({x for x in body_lits & test_lits - spec_lits if int(x.replace('_', '')) >= 3
                   and int(x.replace('_', '')) not in (8, 10, 16, 32, 64, 100, 1000, 256, 255, 128, 127)},
                  key=lambda s: int(s.replace('_', '')))
    f['demo_literal'] = len(demo)
    if demo:
        notes.append('demo literals ' + ' '.join(demo[:6]))
    return f, notes, nlines

W = dict(clamp=3, early_exit=2, stub=2, first_match=4, demo_literal=1, warn_off=3, warn_off_tests=0.25, proof_escape=4)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=os.path.join(ROOT, 'tools/vv/sweep_triage.csv'))
    a = ap.parse_args()
    rows = list(csv.DictReader(open(os.path.join(ROOT, 'PROOFS.csv'))))
    rd = {r['folder']: (r['result'], r.get('classification', '')) for r in csv.DictReader(open(os.path.join(ROOT, 'tools/vv/random_drive.csv')))}
    out = []
    for r in rows:
        if r['own_tests'] == 'yes':
            continue
        folder = os.path.join(ROOT, r['folder'])
        if not os.path.isdir(folder):
            continue
        f, notes, n = scan(folder, r)
        fam = 'other-worker' if FAMILY.search(r['algorithm']) else ''
        drive = rd.get(r['folder'], ('not driven', ''))[0]
        dn = r['do_nothing']
        score = sum(min(f[k], 3) * w for k, w in W.items())
        if dn == 'weak': score += 6
        elif dn in ('baseline fails', 'baseline does not build', 'no tests', 'unchecked (main stillborn)'): score += 3
        if drive.startswith('crash'): score += 3
        if r['known_answer']: score -= 3
        if r['open_findings']: score += 2
        if f['stub'] >= 2 or r['stub'] == 'yes': score -= 4   # stubs: mark, not test
        out.append(dict(folder=r['folder'], level=r['level'], family=fam, risk=round(score, 2), **f,
                        input_var=drive, do_nothing=dn, known_answer=r['known_answer'], stub_index=r['stub'],
                        lib_lines=n, notes='; '.join(notes)))
    out.sort(key=lambda x: (x['family'] != '', -x['risk'], x['folder']))
    for i, x in enumerate(out, 1):
        x['rank'] = i
    cols = ['rank', 'folder', 'level', 'family', 'risk', 'clamp', 'early_exit', 'stub', 'first_match', 'demo_literal',
            'warn_off', 'warn_off_tests', 'proof_escape', 'input_var', 'do_nothing', 'known_answer', 'stub_index', 'lib_lines', 'notes']
    with open(a.out, 'w', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=cols); w.writeheader(); w.writerows(out)
    print(len(out), 'folders;', sum(1 for x in out if x['family']), 'other-worker family')
    for k in W:
        print(f'{k:15s} folders flagged: {sum(1 for x in out if x[k])}')
    print('do-nothing weak:', sum(1 for x in out if x['do_nothing'] == 'weak'),
          ' random-drive crash:', sum(1 for x in out if x['input_var'].startswith('crash')))

if __name__ == '__main__':
    main()
