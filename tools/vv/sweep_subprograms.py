#!/usr/bin/env python3
"""Per-subprogram breakdown of one sweep_mutate.py detail file (docs/VV.md 3i).
usage: sweep_subprograms.py DETAIL.csv
Prints folder, subprogram, killed, survived, timeout, score; a subprogram with
mutants and 0 killed is flagged UNCHECKED (dead helper or hidden by a fallback).
Survivors listed in sweep_equivalent.csv are not subtracted here (see that file).
"""
import csv, os, sys, re, collections, importlib.util
here = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.dirname(os.path.dirname(here))
src = open(os.path.join(here, 'mutation_subprograms.py')).read()
ns = {'__file__': os.path.join(here, 'mutation_subprograms.py')}
exec(src[:src.index('eq = set()')], ns)     # only the spans() helper
spans = ns['spans']
cnt = collections.OrderedDict()
for r in csv.DictReader(open(sys.argv[1])):
    path = os.path.join(ROOT, r['folder'], r['file'])
    ln = int(r['line'])
    inner = [s for s in spans(path) if s[0] <= ln <= s[1]]
    name = min(inner, key=lambda s: s[1] - s[0])[2] if inner else '(package level)'
    c = cnt.setdefault((r['folder'], name), collections.Counter())
    c[r['result']] += 1
for (f, n), c in cnt.items():
    k, s, t = c['killed'], c['survived'], c['timeout']
    flag = '  UNCHECKED' if k == 0 and s > 0 else ''
    print(f'{f},{n},{k},{s},{t},{k}/{k + s}{flag}')
