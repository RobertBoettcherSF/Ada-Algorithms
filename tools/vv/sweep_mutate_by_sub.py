#!/usr/bin/env python3
"""Per-subprogram mutation breakdown (docs/VV.md 3i, pattern 7).

Reads mutation detail files (folder,file,line,op,before,after,result as
written by tools/vv/mutate.py and tools/vv/sweep_mutate.py), maps every
mutant to the innermost subprogram whose body (or contract) contains its
line in the folder's current source, and counts killed / survived per
subprogram. A subprogram with mutants but none killed is flagged
`unchecked`: no test notices any change to it (fallback-masked phase, dead
helper, or contract-only code). Mutants whose recorded source line no
longer matches the current file are located by their text; if the text is
gone they are counted as `stale` and ignored.

usage: sweep_mutate_by_sub.py DETAIL.csv ... [--out tools/vv/sweep_mutate_by_sub.csv]
(give the detail files oldest first: the last file that has a folder wins;
test-code mutants from older mutate.py runs are skipped)
"""
import argparse, csv, os, re
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
# Test code (older mutate.py runs mutated it too) is not library code: skipped.
TESTFILE = re.compile(r'^(tests?|own_checks|main|demo)', re.I)
HDR = re.compile(r'^\s*(?:overriding\s+|not\s+overriding\s+)?(procedure|function)\s+(\w+)', re.I)

def spans(path):
    """[(start, end, name, ghost)] 1-based, for subprogram bodies / expression functions."""
    L = open(path, errors='replace').read().split('\n')
    out, stack = [], []
    for i, l in enumerate(L, 1):
        code = l.split('--')[0]
        m = HDR.match(code)
        if m:
            # spec-only declaration ending in ';' without 'is' before it -> skip
            j, txt = i, code
            while ';' not in txt and not re.search(r'\bis\b', txt, re.I) and j < len(L):
                txt += ' ' + L[j].split('--')[0]; j += 1
            if re.search(r'\bis\b', txt, re.I) or re.search(r'\bwith\b', txt, re.I) and not txt.rstrip().endswith(';'):
                stack.append([i, m.group(2)])
            continue
        if stack:
            e = re.match(r'^\s*end\s+(\w+)\s*;', code, re.I)
            if e and e.group(1).lower() == stack[-1][1].lower():
                s, n = stack.pop(); out.append((s, i, n))
    # expression functions / bodies without 'end Name;' : treat header .. next header as span
    for s, n in stack:
        out.append((s, s + 40, n))
    return out

def locate(folder, f, line, before):
    p = os.path.join(ROOT, folder, f)
    if not os.path.exists(p):
        return None, None
    L = open(p, errors='replace').read().split('\n')
    b = before.strip()
    if 0 < line <= len(L) and L[line - 1].strip()[:len(b)] == b[:len(L[line - 1].strip())][:len(b)] and b[:40] in L[line - 1]:
        return p, line
    hits = [i for i, l in enumerate(L, 1) if b and b[:60] in l]
    return (p, hits[0]) if len(hits) == 1 else (None, None)

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('details', nargs='+')
    ap.add_argument('--out', default=os.path.join(ROOT, 'tools/vv/sweep_mutate_by_sub.csv')); a = ap.parse_args()
    cnt = defaultdict(lambda: {'killed': 0, 'survived': 0}); stale = defaultdict(int); src = {}
    cache = {}
    # A folder can appear in several runs (an old run before a fix, a newer
    # one after).  Only the last detail file on the command line that has
    # the folder counts, so give the files oldest first.
    last = {}
    for d in a.details:
        for r in csv.DictReader(open(d)):
            last[r['folder']] = d
    eq = defaultdict(set)   # (folder, file, line) of justified equivalent mutants
    ep = os.path.join(ROOT, 'tools/vv/sweep_equivalent.csv')
    if os.path.exists(ep):
        for r in csv.DictReader(open(ep)):
            m = re.match(r'\s*([\w.]+):(\d+)', r['mutant'])
            if m:
                eq[(r['folder'], m.group(1))].add(int(m.group(2)))
    just = defaultdict(int); testcode = defaultdict(int)
    for d in a.details:
        for r in csv.DictReader(open(d)):
            if r['result'] not in ('killed', 'survived') or last[r['folder']] != d:
                continue
            if TESTFILE.match(os.path.basename(r['file'])) or r['file'].startswith('tests/'):
                testcode[r['folder']] += 1; continue
            p, ln = locate(r['folder'], r['file'], int(r['line']), r['before'])
            if not p:
                stale[r['folder']] += 1; continue
            if p not in cache:
                cache[p] = spans(p)
            inner = [s for s in cache[p] if s[0] <= ln <= s[1]]
            name = min(inner, key=lambda s: s[1] - s[0])[2] if inner else '(package level)'
            k = (r['folder'], r['file'], name)
            cnt[k][r['result']] += 1; src.setdefault(k, set()).add(os.path.basename(d))
            if r['result'] == 'survived' and int(r['line']) in eq[(r['folder'], r['file'])]:
                just[k] += 1
    rows = []
    for (folder, f, name), c in sorted(cnt.items()):
        tot = c['killed'] + c['survived']
        rows.append(dict(folder=folder, file=f, subprogram=name, killed=c['killed'], total=tot,
                         score=f"{100 * c['killed'] // tot}%", justified_equivalent=just[(folder, f, name)],
                         flag=('unchecked' if c['killed'] == 0 else '') + (' (all survivors justified equivalent)' if c['killed'] == 0 and just[(folder, f, name)] == c['survived'] else ''),
                         sources=';'.join(sorted(src[(folder, f, name)]))))
    with open(a.out, 'w', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=['folder', 'file', 'subprogram', 'killed', 'total', 'score', 'justified_equivalent', 'flag', 'sources'])
        w.writeheader(); w.writerows(rows)
    un = [r for r in rows if r['flag']]
    print(len(rows), 'subprograms in', len({r['folder'] for r in rows}), 'folders;', len(un), 'with 0% killed;',
          sum(stale.values()), 'stale mutants ignored;', sum(testcode.values()), 'test-code mutants skipped')
    for r in un:
        print(f"  0%  {r['folder']}  {r['subprogram']}  ({r['total']} mutants){' - all justified equivalent' if 'justified' in r['flag'] else ''}")

if __name__ == '__main__':
    main()
