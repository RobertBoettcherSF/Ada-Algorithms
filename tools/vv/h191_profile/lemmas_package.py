#!/usr/bin/env python3
# H191 scratch measurement only (never applied to the repo): moves the DWAP lemma procedures into a
# nested package Lemmas with pragma Assertion_Policy (Ghost => Ignore). usage: lemmas_package.py <body.adb>
import sys, re
p = sys.argv[1]
L = open(p).read().split('\n')
def idx(pat, start=0):
    for i in range(start, len(L)):
        if re.search(pat, L[i]): return i
    raise SystemExit('not found: ' + pat)
def block(start_pat, end_pat, lead_comment=True):
    s = idx(start_pat); e = idx(end_pat, s)
    while lead_comment and s > 0 and L[s-1].strip().startswith('--'): s -= 1
    return s, e
segs = {}
segs['ways_step'] = block(r'^   procedure Lemma_Ways_Step \(L : Operand_Count\)$', r'^   end Lemma_Ways_Step;')
segs['partial_le'] = block(r'^   procedure Lemma_Partial_Le \(N', r'^   end Lemma_Partial_Le;')
segs['mul_mono'] = block(r'^   procedure Lemma_Mul_Mono \(X', r'^   end Lemma_Mul_Mono;')
segs['bound_mul'] = block(r'^   procedure Lemma_Bound_Mul \(P', r'^   procedure Lemma_Bound_Mul \(P, L : Positive\) is null;')
segs['count_tab'] = block(r'^   type Count_Table is', r'^   Count : constant Count_Table')
segs['lemma_count'] = block(r'^   procedure Lemma_Count \(L', r'^   procedure Lemma_Count \(L : Positive\) is null;')
take = {k: L[s:e+1] for k, (s, e) in segs.items()}
drop = set()
for s, e in segs.values():
    drop.update(range(s, e+1))
# split each lemma into spec (up to the first ';' ending the aspect list) and body
def split(lines):
    for i, l in enumerate(lines):
        if l.rstrip().endswith(';') and not l.strip().startswith('--'):
            return lines[:i+1], lines[i+1:]
spec, body = [], []
for k in ('ways_step', 'partial_le', 'mul_mono', 'bound_mul', 'lemma_count'):
    a, b = split(take[k])
    while b and b[0].strip() == '': b = b[1:]
    spec += ['   ' + x if x else x for x in a] + ['']
    body += ['   ' + x if x else x for x in b] + ['']
pkg = (take['count_tab'] + [''] +
 ['   --  The lemma procedures. Their calls are statements and nothing that is',
  '   --  checked at run time depends on them, so their ghost policy is Ignore',
  '   --  (H191: with -gnata they re-checked O (L ** 2) Big_Integer facts at every',
  '   --  recursive Sub call). Partial, Ways and every Pre, Post, invariant and',
  '   --  Assert of the code below keep the -gnata policy. gnatprove proves the',
  '   --  lemmas and uses their contracts as before (tools/vv/proof_escapes.csv).',
  '   package Lemmas is',
  '      pragma Assertion_Policy (Ghost => Ignore);',
  ''] + spec[:-1] +
 ['   end Lemmas;', '', '   package body Lemmas is', '      pragma Assertion_Policy (Ghost => Ignore);', ''] + body[:-1] +
 ['   end Lemmas;', '', '   use Lemmas;', ''])
# insert the package where Lemma_Ways_Step was (after Lemma_Facts)
ins = segs['ways_step'][0]
out = []
for i, l in enumerate(L):
    if i == ins: out += pkg
    if i in drop: continue
    out.append(l)
s = '\n'.join(out)
s = re.sub(r'\n{3,}', '\n\n', s)
open(p, 'w').write(s)
