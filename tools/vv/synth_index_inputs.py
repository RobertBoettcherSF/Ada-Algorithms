#!/usr/bin/env python3
"""Synthesise tools/proof_index.py inputs (build.jsonl, prove.jsonl, logs/) from the committed PROOFS.csv.

The per-folder build/prove result dirs of tools/audit are from an older full run and would blank
newer columns, so the index is regenerated from the build, test, warning, compiler, silver, checks,
proof_run and proof_gpr columns already in PROOFS.csv (the way main regenerated it in 2e8ee194);
every derived column then comes fresh from the tools/vv tables.

usage: synth_index_inputs.py [--root REPO] [--out DIR]
  --root  repository root (default: this checkout)
  --out   output dir (default: a new mktemp dir); the dir is printed on the last line.
Regenerate and cross-check:
  D=$(python3 tools/vv/synth_index_inputs.py | tail -1)
  python3 tools/proof_index.py --results "$D" --logs "$D/logs"
  python3 tools/vv/recount_strict.py --results "$D" --logs "$D/logs" --list
"""
import argparse, csv, json, os, re, sys, tempfile
ap = argparse.ArgumentParser()
ap.add_argument('--root', default=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
ap.add_argument('--out', default='')
_a = ap.parse_args()
root, out = _a.root, (_a.out or tempfile.mkdtemp(prefix='aa_index_inputs_'))
os.makedirs(out, exist_ok=True)
logs = os.path.join(out, 'logs'); os.makedirs(logs, exist_ok=True)
rows = list(csv.DictReader(open(os.path.join(root, 'PROOFS.csv'), newline='')))
B, P = open(os.path.join(out, 'build.jsonl'), 'w'), open(os.path.join(out, 'prove.jsonl'), 'w')
for r in rows:
    f = r['folder']
    if any(r[k] for k in ('make_test', 'build_gnat14', 'build_gnat12', 'tests_pass_gnat14')):
        yn = lambda v: '0' if v == 'yes' else '1'
        b = dict(id=f, u14=yn(r['build_gnat14']), u12=yn(r['build_gnat12']),
                 mk14='NA' if r['make_test'] in ('n/a', '') else yn(r['make_test']),
                 mk12='NA' if r['make_test_gnat12'] in ('n/a', '') else yn(r['make_test_gnat12']),
                 r14=yn(r['tests_pass_gnat14']), r12=yn(r['tests_pass_gnat12']),
                 w14=r['warnings_gnat14'], w12=r['warnings_gnat12'],
                 ver14=r['compiler_14_version'], ver12=r['compiler_12_version'],
                 shared=r['shared_sources'].split() if r['shared_sources'] else [])
        B.write(json.dumps(b) + '\n')
    s = r['silver']
    if s in ('no SPARK', 'skipped (no SPARK_Mode)', 'not run', ''): continue
    gpr = r['proof_gpr'].replace(' (generated)', '')
    j = dict(id=f, gpr=gpr, how='generated' if '(generated)' in r['proof_gpr'] else '')
    m = re.match(r'steps=(\d+)', r['proof_run'])
    if m: j['steps'] = m.group(1)
    d = os.path.join(logs, f.replace('/', '_')); os.makedirs(d, exist_ok=True)
    log = ''
    if s.startswith('proven') or s.startswith('not proven (unjustified'): j['rc'] = 0
    elif s == 'timeout': j['rc'] = 124
    elif s == 'tool crash': j['rc'] = 1; log = 'GNAT BUG DETECTED\n'
    elif s.endswith(' unproved'):
        j['rc'] = 1; log = ''.join(f'x.adb:{i+1}:1: medium: synthesized\n' for i in range(int(s.split()[0])))
    elif s == 'not built': j['rc'] = 1; log = 'x.adb:1:1: error: synthesized\n'
    else: print('unhandled silver', f, s); continue
    open(os.path.join(d, 'prove.log'), 'w').write(log)
    if j['rc'] == 0 and r['checks']:
        fc = r['functional_checks'] if r['functional_checks'].isdigit() else ('restored' if r['functional_checks'] == 'restored' else '0')
        open(os.path.join(d, 'gnatprove.out'), 'w').write(f"Total {r['checks']}\nFunctional Contracts {fc}\n")
    P.write(json.dumps(j) + '\n')
print(out)
