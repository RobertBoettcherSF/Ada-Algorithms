#!/usr/bin/env python3
"""Per-subprogram breakdown of the mutation results (docs/VV.md 3c).

Reads vv/results/mutation_tr_detail.csv, maps each mutant's file:line to the innermost enclosing
subprogram body in that file (procedure/function ... is ... end Name;), and writes
tools/vv/mutation_subprograms.csv: folder,subprogram,killed,survived,equivalent,score.
A surviving mutant listed in tools/vv/sweep_equivalent.csv (with exhaustive evidence or a written reason)
counts as equivalent. A subprogram with mutants but 0 killed is unchecked by the folder's tests.
"""
import csv, os, re, collections
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def spans(path):
    lines = open(path, errors='replace').read().split('\n')
    out, stack = [], []
    head = re.compile(r'^\s*(?:overriding\s+)?(procedure|function)\s+("?[\w.]+"?)', re.I)
    for i, l in enumerate(lines):
        code = l.split('--')[0]
        m = head.match(code)
        if m:
            # a body if an "is" follows before the next ";" (skip declarations / renames / expression functions)
            j, txt = i, ''
            while j < len(lines) and j < i + 30:
                txt += ' ' + lines[j].split('--')[0]
                if ';' in lines[j].split('--')[0] or re.search(r'\bis\b', lines[j].split('--')[0]):
                    break
                j += 1
            if re.search(r'\bis\b\s*$', txt.strip() + ' ') and not re.search(r'\bis\s+(new|separate|abstract|null)\b', txt):
                stack.append((m.group(2), i))
        e = re.match(r'^\s*end\s+("?[\w.]+"?)\s*;', code, re.I)
        if e and stack:
            for k in range(len(stack) - 1, -1, -1):
                if stack[k][0].lower() == e.group(1).lower():
                    name, s0 = stack.pop(k)
                    out.append((s0 + 1, i + 1, name))
                    del stack[k:]
                    break
    return out
eq = set()
p = os.path.join(ROOT, 'tools', 'vv', 'sweep_equivalent.csv')
if os.path.exists(p):
    for x in csv.DictReader(open(p)):
        m = re.match(r'^\s*([^:\s]+):(\d+)\s+(.+?)\s+\(', x.get('mutant', ''))
        if m and (x.get('method', '').strip() == 'exhaustive' or x.get('range_or_reason', '').strip()):
            eq.add((x['folder'], os.path.basename(m.group(1)), int(m.group(2)), m.group(3).strip()))
p = os.path.join(ROOT, 'tools', 'vv', 'flagship_equivalent.csv')
if os.path.exists(p):
    for x in csv.DictReader(open(p)):
        if x.get('line', '').strip().isdigit() and (x.get('method', '').strip() == 'exhaustive' or x.get('range_or_reason', '').strip()):
            eq.add((x['folder'], os.path.basename(x['file']), int(x['line']), None))
cnt = collections.defaultdict(lambda: [0, 0, 0])
cache = {}
for d in csv.DictReader(open(os.path.join(ROOT, 'vv', 'results', 'mutation_tr_detail.csv'))):
    if d['result'] not in ('killed', 'survived', 'timeout'):
        continue
    f = os.path.join(ROOT, d['folder'], d['file'])
    if f not in cache:
        cache[f] = spans(f) if os.path.exists(f) else []
    ln = int(d['line'])
    inner = [s for s in cache[f] if s[0] <= ln <= s[1]]
    name = min(inner, key=lambda s: s[1] - s[0])[2] if inner else '(package level)'
    c = cnt[(d['folder'], name)]
    if d['result'] == 'killed': c[0] += 1
    elif d['result'] == 'timeout': c[1] += 1   # a timeout is not a kill
    elif (d['folder'], os.path.basename(d['file']), ln, d['op'].strip()) in eq or (d['folder'], os.path.basename(d['file']), ln, None) in eq: c[2] += 1
    else: c[1] += 1
with open(os.path.join(ROOT, 'tools', 'vv', 'mutation_subprograms.csv'), 'w', newline='') as fh:
    w = csv.writer(fh, lineterminator='\n'); w.writerow(['folder', 'subprogram', 'killed', 'survived', 'equivalent', 'score'])
    for (fo, sp), (k, s, e) in sorted(cnt.items()):
        w.writerow([fo, sp, k, s, e, f'{k}/{k + s}' if k + s else 'all equivalent'])
rows = list(cnt.items())
unchecked = [r for r in rows if r[1][0] == 0 and r[1][1] > 0]
print(len(rows), 'subprograms with mutants;', len(unchecked), 'with 0 killed (unchecked) in', len({r[0][0] for r in unchecked}), 'folders')
