#!/usr/bin/env python3
"""H181 scan: contract helpers that silently return False on a bad array shape.

A Boolean expression function whose body checks 'First / 'Last / 'Length and yields False when
that check fails (a top-level conjunct, or an if-expression whose else / then branch is False)
can make a contract vacuous, but only where False weakens it:
  pre       anywhere in a Pre (an impossible Pre makes every Post vacuous)
  if-cond   in the condition of an if-expression inside a Post / Contract_Cases (left of an implication)
  not       under `not` inside a Post
  case-guard  in a Contract_Cases guard
In a Post outside those places False only makes the proof fail, which is safe (counted, not flagged).
Cross-check: tools/vv/proof_warnings.csv (--proof-warnings=on reports an impossible Pre); the
`proof_warning` column says whether that file has any recorded warning.
Heuristic text scan (comments stripped, no full parser); every flagged row needs a human look.

  h181_scan.py [--root .] [--out tools/vv/h181_scan.csv]
"""
import argparse, csv, os, re, subprocess
ap = argparse.ArgumentParser(); ap.add_argument('--root', default='.'); ap.add_argument('--out', default='tools/vv/h181_scan.csv')
ap.add_argument('--selftest', action='store_true', help='run the control cases on a throw-away repo and exit')
a = ap.parse_args(); R = os.path.abspath(a.root)
TESTNAME = re.compile(r'^(tests?|own_checks|main|demo)', re.I)
SHAPE = re.compile(r"\b\w+(?:\.\w+)*'(?:First|Last|Length)\b")
EF = re.compile(r'\bfunction\s+(\w+)\s*(\((?:[^()]|\([^()]*\))*\))?\s*return\s+Boolean\s+is\s*\(', re.I)
ASPECT = re.compile(r'\b(Pre|Post|Contract_Cases)(\'Class)?\s*=>', re.I)

def strip_comments(t):
    return '\n'.join(re.sub(r'--.*$', '', l) if '"' not in l else re.sub(r'--[^"]*$', '', l) for l in t.split('\n'))

def match_paren(t, i):   # t[i] == '('
    d = 0
    for j in range(i, len(t)):
        if t[j] == '(':
            d += 1
        elif t[j] == ')':
            d -= 1
            if d == 0:
                return j
    return len(t) - 1

def top_split(body, word):
    parts, d, last = [], 0, 0
    for m in re.finditer(r'[()]|\b' + word + r'\b', body, re.I):
        if m.group() == '(':
            d += 1
        elif m.group() == ')':
            d -= 1
        elif d == 0:
            parts.append(body[last:m.start()]); last = m.end()
    parts.append(body[last:])
    return parts

def guard(body):
    b = body.strip()
    if b.startswith('(') and match_paren(b, 0) == len(b) - 1:
        b = b[1:-1].strip()
    m = re.match(r'if\b(.*?)\bthen\b(.*)\belse\b(.*)$', b, re.I | re.S)
    if m and SHAPE.search(m.group(1)):
        th, el = m.group(2).strip(), m.group(3).strip()
        if re.fullmatch(r'False', el, re.I) or re.fullmatch(r'False', th, re.I):
            return 'if-else-False', ' '.join(m.group(1).split())[:120]
    for c in top_split(b, r'and\s+then') if re.search(r'\band\s+then\b', b, re.I) else top_split(b, 'and'):
        if SHAPE.search(c) and re.search(r'(=|/=|<=|>=|<|>|\bin\b)', c) and not re.search(r'\bfor\s+(all|some)\b', c, re.I):
            return 'conjunct', ' '.join(c.split())[:120]
    return '', ''

def lineno(t, i):
    return t.count('\n', 0, i) + 1

def aspect_text(t, i):   # from i (after '=>') to the next top-level ',' or ';' or ' is' / 'with'
    d = 0
    for j in range(i, len(t)):
        ch = t[j]
        if ch == '(':
            d += 1
        elif ch == ')':
            if d == 0:
                return t[i:j]
            d -= 1
        elif d == 0 and ch in ',;':
            return t[i:j]
        elif d == 0 and re.match(r'\bis\b', t[j:j + 3]) and t[j - 1].isspace():
            return t[i:j]
    return t[i:]

def context(asp, txt, pos):
    if asp.lower() == 'pre':
        return 'pre'
    pre = txt[:pos]
    if re.search(r'\bnot\s*\(?\s*$', pre, re.I):
        return 'not'
    # innermost open paren that starts an if-expression whose 'then' is after pos
    d, opens = 0, []
    for k, ch in enumerate(pre):
        if ch == '(':
            opens.append(k)
        elif ch == ')' and opens:
            opens.pop()
    for k in reversed(opens):
        seg = txt[k + 1:pos]
        if re.match(r'\s*if\b', seg, re.I) and not re.search(r'\bthen\b', seg, re.I):
            return 'if-cond'
        if re.match(r'\s*not\b', txt[k - 4:k + 1] if k >= 4 else '', re.I):
            return 'not'
    if asp.lower() == 'contract_cases':
        tail = txt[pos:]
        m1 = re.search(r'=>', tail); m2 = re.search(r',', tail)
        if m1 and (not m2 or m1.start() < m2.start()):
            return 'case-guard'
    if re.search(r'\bnot\s+\w*\s*$', pre, re.I):
        return 'not'
    return 'post'

if a.selftest:
    import shutil, sys, tempfile
    d = tempfile.mkdtemp(prefix='h181_')
    os.makedirs(os.path.join(d, 'x/SPARK2/P')); os.makedirs(os.path.join(d, 'tools/vv'))
    open(os.path.join(d, 'x/SPARK2/P/p.ads'), 'w').write(
        'package P is\n   type A is array (Positive range <>) of Integer;\n'
        "   function Ok (X : A) return Boolean is (X'First = 1 and then X'Length > 0);\n"
        "   function Ok2 (X : A) return Boolean is (if X'Length > 0 then X (X'First) > 0 else False);\n"
        '   function F1 (X : A) return Integer with Pre => Ok (X);\n'
        '   function F2 (X : A) return Integer with Post => (if Ok (X) then F2\'Result > 0);\n'
        '   function F3 (X : A) return Integer with Post => not Ok2 (X) or else F3\'Result > 0;\n'
        '   function F4 (X : A) return Integer with Post => Ok (X) and then F4\'Result > 0;\n'
        '   function F5 (X : A) return Integer with Contract_Cases => (Ok2 (X) => F5\'Result > 0, others => True);\nend P;\n')
    subprocess.run(['git', 'init', '-q', d]); subprocess.run(['git', '-C', d, 'add', '-A'])
    r = subprocess.run([sys.executable, os.path.abspath(__file__), '--root', d, '--out', 'o.csv'], capture_output=True, text=True)
    got = {(x['line'], x['context']) for x in csv.DictReader(open(os.path.join(d, 'o.csv')))}
    want = {('5', 'pre'), ('6', 'if-cond'), ('7', 'not'), ('8', 'post'), ('9', 'case-guard')}
    shutil.rmtree(d, ignore_errors=True)
    print(('ok  ' if got == want else 'FAIL') + f' h181_scan control: {sorted(got)}' + ('' if got == want else f' (expected {sorted(want)})'))
    sys.exit(0 if got == want else 1)
files = subprocess.run(['git', 'ls-files', '*.ads', '*.adb'], cwd=R, capture_output=True, text=True).stdout.split()
files = [f for f in files if not TESTNAME.match(os.path.basename(f)) and '/tests/' not in f and not f.startswith('tools/')]
src = {}
for f in files:
    try:
        src[f] = strip_comments(open(os.path.join(R, f), errors='replace').read())
    except OSError:
        pass
folder_of = lambda f: os.path.dirname(f)
helpers = {}   # (folder, name) -> (file, line, kind, text)
for f, t in src.items():
    for m in EF.finditer(t):
        i = m.end() - 1; j = match_paren(t, i)
        kind, g = guard(t[i:j + 1])
        if kind:
            helpers.setdefault((folder_of(f), m.group(1).lower()), (f, lineno(t, m.start()), kind, g, m.group(1)))
pw = {}
pwp = os.path.join(R, 'tools/vv/proof_warnings.csv')
if os.path.exists(pwp):
    for r in csv.DictReader(open(pwp)):
        pw.setdefault((r['folder'], r['file']), []).append(r)
rows, seen = [], set()
for f, t in src.items():
    fo = folder_of(f)
    names = {n: v for (fd, n), v in helpers.items() if fd == fo}
    if not names:
        continue
    for m in ASPECT.finditer(t):
        txt = aspect_text(t, m.end())
        for c in re.finditer(r'\b(\w+)\s*\(', txt):
            n = c.group(1).lower()
            if n not in names:
                continue
            hf, hl, kind, g, real = names[n]
            if f == hf and abs(lineno(t, m.start()) - hl) <= 0 and m.group(1).lower() != 'pre':
                pass
            ctx = context(m.group(1), txt, c.start())
            ln = lineno(t, m.end() + c.start())
            key = (f, ln, n, ctx)
            if key in seen:
                continue
            seen.add(key)
            pws = pw.get((fo, os.path.basename(f)), [])
            rows.append([fo, os.path.basename(f), ln, real, f'{os.path.basename(hf)}:{hl}', kind, g, m.group(1) + (m.group(2) or ''), ctx,
                         'yes' if ctx != 'post' else 'no', f'{len(pws)} row(s) in proof_warnings.csv for this file' if pws else 'none'])
for r in rows:   # origin pin ('First = literal) vs relational shape guard (A'First = B'First, 'Length = N)
    r.insert(7, 'origin_pin' if re.search(r"'First\s*=\s*\d|\d\s*=\s*\w+'First", r[6]) else 'relational')
rows.sort()
with open(os.path.join(R, a.out), 'w', newline='') as fh:
    w = csv.writer(fh, quoting=csv.QUOTE_ALL, lineterminator='\n')
    w.writerow(['folder', 'file', 'line', 'helper', 'helper_def', 'guard_kind', 'guard', 'guard_type', 'aspect', 'context', 'flag', 'proof_warning'])
    w.writerows(rows)
fl = [r for r in rows if r[10] == 'yes']
from collections import Counter
print('h181_scan: flagged by context ' + ', '.join(f'{k} {v}' for k, v in sorted(Counter(r[9] for r in fl).items()))
      + '; Pre uses by guard type ' + ', '.join(f'{k} {v}' for k, v in sorted(Counter(r[7] for r in fl if r[9] == 'pre').items())))
print(f'h181_scan: {len(helpers)} shape-guarded Boolean expression function(s) in {len({k[0] for k in helpers})} folder(s); '
      f'{len(rows)} contract use(s), {len(fl)} flagged (pre / if-cond / not / case-guard) in {len({r[0] for r in fl})} folder(s) -> {a.out}')
