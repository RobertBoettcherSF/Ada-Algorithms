#!/usr/bin/env python3
# H191 scratch measurement only: wraps each lemma call after "use Lemmas;" in a block carrying
# pragma Assertion_Policy (Ghost => Ignore) (required: calls from a Check region are illegal). usage: ignore_blocks.py <body.adb>
import sys, re
p = sys.argv[1]
L = open(p).read().split('\n')
start = next(i for i, l in enumerate(L) if l.strip() == 'use Lemmas;')
out = L[:start+1]; i = start + 1
call = re.compile(r'^(\s*)Lemma_\w+ \(')
while i < len(L):
    m = call.match(L[i])
    if not m:
        out.append(L[i]); i += 1; continue
    ind = m.group(1); grp = []
    while i < len(L) and call.match(L[i]) and call.match(L[i]).group(1) == ind:
        j = i
        while not L[j].rstrip().endswith(';'): j += 1
        grp += L[i:j+1]; i = j + 1
    out += [ind + 'declare', ind + '   pragma Assertion_Policy (Ghost => Ignore);', ind + 'begin']
    out += ['   ' + x for x in grp]
    out += [ind + 'end;']
open(p, 'w').write('\n'.join(out))
