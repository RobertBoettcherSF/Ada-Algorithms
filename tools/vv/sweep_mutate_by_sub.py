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

def _decl_kind(L, i):
    """Classify the subprogram whose header starts on line i (0-based):
    ('body', None), ('expr', end_line) or ('decl', None).  Scans at
    parenthesis depth 0 for the first ';' or 'is'."""
    depth, j = 0, i
    while j < len(L):
        code = re.sub(r'"[^"]*"', '""', L[j].split('--')[0])
        for m in re.finditer(r'[()]|;|\bis\b', code, re.I):
            t = m.group(0).lower()
            if t == '(':
                depth += 1
            elif t == ')':
                depth -= 1
            elif depth == 0 and t == ';':
                return 'decl', None
            elif depth == 0 and t == 'is':
                rest = code[m.end():] + ' ' + ' '.join(x.split('--')[0] for x in L[j + 1:j + 3])
                if re.match(r'\s*(new|separate|abstract|null\s*;)', rest, re.I):
                    return 'decl', None
                if re.match(r'\s*\(', rest):
                    # expression function: ends at the first ';' at depth 0 after 'is'
                    d2, k, started = 0, j, False
                    while k < len(L):
                        c2 = re.sub(r'"[^"]*"', '""', L[k].split('--')[0])
                        if k == j:
                            c2 = c2[m.end():]
                        for ch in c2:
                            if ch == '(':
                                d2 += 1
                            elif ch == ')':
                                d2 -= 1
                            elif ch == ';' and d2 == 0:
                                return 'expr', k
                        k += 1
                    return 'expr', j
                return 'body', None
        j += 1
    return 'decl', None

def spans(path):
    """[(start, end, name)] 1-based line spans of subprogram bodies (header
    through 'end Name;', contracts included) and expression functions."""
    L = open(path, errors='replace').read().split('\n')
    out, stack = [], []
    for i, l in enumerate(L):
        code = l.split('--')[0]
        m = HDR.match(code)
        if m:
            kind, end = _decl_kind(L, i)
            if kind == 'body':
                stack.append([i + 1, m.group(2)])
            elif kind == 'expr':
                out.append((i + 1, end + 1, m.group(2)))
            continue
        e = re.match(r'^\s*end\s+(\w+)\s*;', code, re.I)
        if e and stack:
            for k in range(len(stack) - 1, -1, -1):
                if stack[k][1].lower() == e.group(1).lower():
                    s0, n = stack[k]; del stack[k:]; out.append((s0, i + 1, n)); break
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
    just = defaultdict(int); testcode = defaultdict(int); ghost = {}
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
            if k not in ghost:
                sp = [x for x in cache[p] if x[2] == name]
                txt = '\n'.join(open(p, errors='replace').read().split('\n')[sp[0][0] - 1:sp[0][1]]) if sp else ''
                ghost[k] = bool(re.search(r'\bGhost\b', txt)) or name.lower().startswith('lemma_')
            cnt[k][r['result']] += 1; src.setdefault(k, set()).add(os.path.basename(d))
            if r['result'] == 'survived' and int(r['line']) in eq[(r['folder'], r['file'])]:
                just[k] += 1
    rows = []
    for (folder, f, name), c in sorted(cnt.items()):
        tot = c['killed'] + c['survived']
        rows.append(dict(folder=folder, file=f, subprogram=name, killed=c['killed'], total=tot,
                         score=f"{100 * c['killed'] // tot}%", ghost='yes' if ghost.get((folder, f, name)) else '', justified_equivalent=just[(folder, f, name)],
                         flag=('unchecked' if c['killed'] == 0 else '') + (' (all survivors justified equivalent)' if c['killed'] == 0 and just[(folder, f, name)] == c['survived'] else ''),
                         sources=';'.join(sorted(src[(folder, f, name)]))))
    with open(a.out, 'w', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=['folder', 'file', 'subprogram', 'killed', 'total', 'score', 'ghost', 'justified_equivalent', 'flag', 'sources'])
        w.writeheader(); w.writerows(rows)
    un = [r for r in rows if r['flag'] and not r['ghost']]
    print(sum(1 for r in rows if r['flag'] and r['ghost']), 'more 0% rows are ghost / lemma code (contracts only; a run cannot observe them)')
    print(len(rows), 'subprograms in', len({r['folder'] for r in rows}), 'folders;', len(un), 'with 0% killed;',
          sum(stale.values()), 'stale mutants ignored;', sum(testcode.values()), 'test-code mutants skipped')
    for r in un:
        print(f"  0%  {r['folder']}  {r['subprogram']}  ({r['total']} mutants){' - all justified equivalent' if 'justified' in r['flag'] else ''}")

if __name__ == '__main__':
    main()
