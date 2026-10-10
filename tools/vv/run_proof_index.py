#!/usr/bin/env python3
"""What `make proof-index` runs (H188): regenerate the index from the right inputs, or fail loudly.

Default (no --results): the inputs are synthesised from the committed PROOFS.csv
(tools/vv/synth_index_inputs.py), so a stale results dir in $TMPDIR can no longer change the
headline (it gave 92 = 92 + 3 instead of 87 + 5 on 2026-10-10).

With --results/--logs (a new build + prove run): after tools/proof_index.py has run, every input
column (build, tests, warnings, compiler, silver, checks, proof run/gpr) is compared with the
PROOFS.csv that was there before; on any difference the old PROOFS.csv / PROOFS.md / README.md /
docs/IMPLEMENT.md are restored and the exit status is 2, unless --allow-input-change says the new
inputs are meant (`make proof-index RESULTS=... ALLOW_INPUT_CHANGE=1`).

Always: the training-ready set and the rescore_pending set (codefix.csv / rescored.csv) of the new
PROOFS.csv must equal what tools/vv/recount_strict.py --list / --pending reads independently from
the same inputs; otherwise the files are restored and the exit status is 3.

usage: run_proof_index.py [--results DIR --logs DIR] [--allow-input-change] [-- proof_index.py args]
"""
import argparse, csv, os, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ap = argparse.ArgumentParser()
ap.add_argument('--root', default='.')
ap.add_argument('--results', default='')
ap.add_argument('--logs', default='')
ap.add_argument('--allow-input-change', action='store_true')
ap.add_argument('rest', nargs=argparse.REMAINDER, help='extra arguments for tools/proof_index.py (after --)')
a = ap.parse_args()
root = os.path.abspath(a.root)
extra = a.rest[1:] if a.rest[:1] == ['--'] else a.rest
OUT = ('PROOFS.csv', 'PROOFS.md', 'README.md', os.path.join('docs', 'IMPLEMENT.md'))
INPUT_COLS = ('make_test', 'make_test_gnat12', 'build_gnat14', 'build_gnat12', 'tests_pass_gnat14', 'tests_pass_gnat12',
              'warnings_gnat14', 'warnings_gnat12', 'compiler_14_version', 'compiler_12_version',
              'silver', 'checks', 'proof_run', 'proof_gpr')

def snapshot():
    return {f: open(os.path.join(root, f), 'rb').read() for f in OUT if os.path.exists(os.path.join(root, f))}

def restore(s):
    for f, b in s.items():
        open(os.path.join(root, f), 'wb').write(b)

def table():
    p = os.path.join(root, 'PROOFS.csv')
    return {r['folder']: r for r in csv.DictReader(open(p, newline=''))} if os.path.exists(p) else {}

def listed(flag, res, logs):
    r = subprocess.run([sys.executable, os.path.join('tools', 'vv', 'recount_strict.py'), '--results', res, '--logs', logs, flag],
                       cwd=root, capture_output=True, text=True)
    if r.returncode:
        sys.exit(f'run_proof_index: recount_strict.py {flag} failed:\n{r.stdout}{r.stderr}')
    return {l.strip() for l in r.stdout.splitlines() if l.strip() and not l.startswith('#')}

snap, old = snapshot(), table()
if not a.results:
    if a.logs:
        sys.exit('run_proof_index: --logs without --results')
    if not old:
        sys.exit('run_proof_index: no committed PROOFS.csv to synthesise inputs from; pass --results/--logs')
    r = subprocess.run([sys.executable, os.path.join('tools', 'vv', 'synth_index_inputs.py'), '--root', root],
                       cwd=root, capture_output=True, text=True)
    if r.returncode:
        sys.exit(f'run_proof_index: synth_index_inputs.py failed:\n{r.stdout}{r.stderr}')
    res = r.stdout.strip().splitlines()[-1]
    logs, how = os.path.join(res, 'logs'), 'inputs synthesised from the committed PROOFS.csv'
else:
    if not a.logs:
        sys.exit('run_proof_index: --results needs --logs')
    res, logs, how = a.results, a.logs, f'inputs from {a.results}'
r = subprocess.run([sys.executable, os.path.join('tools', 'proof_index.py'), '--results', res, '--logs', logs] + extra, cwd=root)
if r.returncode:
    restore(snap)
    sys.exit(f'run_proof_index: proof_index.py failed (exit {r.returncode}); files restored')
new = table()
diffs = []
if old and a.results:
    for f in sorted(set(old) | set(new)):
        if f not in old or f not in new:
            diffs.append(f"{f}: {'added' if f in new else 'missing'}")
            continue
        for c in INPUT_COLS:
            if old[f].get(c, '') != new[f].get(c, ''):
                diffs.append(f"{f}: {c} {old[f].get(c, '')!r} -> {new[f].get(c, '')!r}")
if diffs and not a.allow_input_change:
    restore(snap)
    print(f'run_proof_index: FAIL inputs disagree with the committed PROOFS.csv ({len(diffs)} difference(s)); files restored.', file=sys.stderr)
    for d in diffs[:25]:
        print('  ' + d, file=sys.stderr)
    print('  Default inputs: `make proof-index` (no RESULTS). A deliberate new run: add ALLOW_INPUT_CHANGE=1.', file=sys.stderr)
    sys.exit(2)
tr = {f for f, x in new.items() if x.get('training_ready') == 'yes'}
pend = {f for f, x in new.items() if x.get('rescore_pending')}
rec, recp = listed('--list', res, logs), listed('--pending', res, logs)
if tr != rec or pend != recp:
    restore(snap)
    print('run_proof_index: FAIL index and recount_strict.py disagree; files restored.', file=sys.stderr)
    print(f'  training_ready only index {sorted(tr - rec)[:10]}, only recount {sorted(rec - tr)[:10]}', file=sys.stderr)
    print(f'  rescore_pending only index {sorted(pend - recp)[:10]}, only recount {sorted(recp - pend)[:10]}', file=sys.stderr)
    sys.exit(3)
print(f'run_proof_index: {how}; {len(diffs)} input change(s)' + (' (allowed)' if diffs else '')
      + f'; training-ready {len(tr)} = {len(tr - pend)} confirmed + {len(tr & pend)} pending re-score; recount_strict.py agrees')
