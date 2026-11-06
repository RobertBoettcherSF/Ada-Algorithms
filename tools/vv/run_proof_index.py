#!/usr/bin/env python3
"""What `make proof-index` runs (H188): regenerate the index from the right inputs, or fail loudly.

Default (no --results): the inputs are synthesised from the committed PROOFS.csv
(tools/vv/synth_index_inputs.py), so a stale results dir in $TMPDIR can no longer change the
headline (it gave 92 = 92 + 3 instead of 87 + 5 on 2026-10-10).

With --results/--logs (a new build + prove run): after tools/proof_index.py has run, every input
column (build, tests, warnings, compiler, silver, checks, proof run/gpr) is compared with the
PROOFS.csv that was there before; on any difference the old PROOFS.csv / PROOFS.md / README.md /
docs/IMPLEMENT.md / CATALOG.md are restored and the exit status is 2, unless --allow-input-change
says the new inputs are meant (`make proof-index RESULTS=... ALLOW_INPUT_CHANGE=1`).

Always: the training-ready set and the rescore_pending set (codefix.csv / rescored.csv) of the new
PROOFS.csv must equal what tools/vv/recount_strict.py --list / --pending reads independently from
the same inputs; otherwise the files are restored and the exit status is 3.

Every run that keeps the new index also writes CATALOG.md from that PROOFS.csv. `--catalog-only`
writes CATALOG.md from the current CSV and does not regenerate the index.

usage: run_proof_index.py [--catalog-only] [--results DIR --logs DIR] [--allow-input-change]
       [-- proof_index.py args]
"""
import argparse, csv, os, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ap = argparse.ArgumentParser()
ap.add_argument('--root', default='.')
ap.add_argument('--results', default='')
ap.add_argument('--logs', default='')
ap.add_argument('--allow-input-change', action='store_true')
ap.add_argument('--catalog-only', action='store_true',
                help='write CATALOG.md from the current PROOFS.csv and do nothing else')
ap.add_argument('rest', nargs=argparse.REMAINDER, help='extra arguments for tools/proof_index.py (after --)')
a = ap.parse_args()
root = os.path.abspath(a.root)
extra = a.rest[1:] if a.rest[:1] == ['--'] else a.rest
OUT = ('PROOFS.csv', 'PROOFS.md', 'README.md', os.path.join('docs', 'IMPLEMENT.md'), 'CATALOG.md')
INPUT_COLS = ('make_test', 'make_test_gnat12', 'build_gnat14', 'build_gnat12', 'tests_pass_gnat14', 'tests_pass_gnat12',
              'warnings_gnat14', 'warnings_gnat12', 'compiler_14_version', 'compiler_12_version',
              'silver', 'checks', 'proof_run', 'proof_gpr')

def snapshot():
    return {f: open(os.path.join(root, f), 'rb').read() for f in OUT if os.path.exists(os.path.join(root, f))}

def restore(s):
    for f, b in s.items():
        open(os.path.join(root, f), 'wb').write(b)
    # a file this run created (CATALOG.md on a first write) goes away again when the run fails
    for f in OUT:
        p = os.path.join(root, f)
        if f not in s and os.path.exists(p):
            os.remove(p)

def table():
    p = os.path.join(root, 'PROOFS.csv')
    return {r['folder']: r for r in csv.DictReader(open(p, newline=''))} if os.path.exists(p) else {}

def listed(flag, res, logs):
    r = subprocess.run([sys.executable, os.path.join('tools', 'vv', 'recount_strict.py'), '--results', res, '--logs', logs, flag],
                       cwd=root, capture_output=True, text=True)
    if r.returncode:
        sys.exit(f'run_proof_index: recount_strict.py {flag} failed:\n{r.stdout}{r.stderr}')
    return {l.strip() for l in r.stdout.splitlines() if l.strip() and not l.startswith('#')}

# CATALOG.md is generated from PROOFS.csv. Counts are computed here; none are written into the text.
_LEVELS = ('Ada', 'SPARK1', 'SPARK2', 'SPARK3', 'SPARK4')
_COLS = (('folder path', 'folder'), ('Silver', 'silver'), ('Training-ready', 'training_ready'),
         ('Stub', 'stub'), ('Needs implementation', 'implement_next'), ('Open findings', 'open_findings'))

def _findings(rs):
    n = 0
    for r in rs:
        v = (r.get('open_findings') or '').strip()
        if not v:
            continue
        n += int(v) if v.isdigit() else 1
    return n

def _cell(v):
    return (v or '').replace('|', '/')

def _nfolders(n, dot=False):
    return f"**{n} folder{'' if n == 1 else 's'}{'.' if dot else ''}**"

def _folder_line(r):
    cells = []
    for _title, key in _COLS:
        if key == 'folder':
            cells.append(f"[{r['folder']}]({r['folder']})")
        else:
            cells.append(_cell(r.get(key, '')))
    return '| ' + ' | '.join(cells) + ' |'

def _levels(rows):
    present = {r['level'] for r in rows}
    return [lv for lv in _LEVELS if lv in present] + sorted(present - set(_LEVELS))

def catalog_text(rows):
    uniq = sorted((r for r in rows if not r.get('duplicate_of')), key=lambda r: r['folder'])
    topics = sorted({r['topic'] for r in uniq})
    levels = _levels(uniq)
    ready = [r for r in uniq if r.get('training_ready') == 'yes']

    def counts(rs):
        return ([str(len(rs))]
                + [str(sum(1 for r in rs if r['level'] == lv)) for lv in levels]
                + [str(sum(1 for r in rs if r.get('training_ready') == 'yes')),
                   str(sum(1 for r in rs if r.get('stub') == 'yes')),
                   str(sum(1 for r in rs if r.get('implement_next') == 'yes')),
                   str(_findings(rs))])

    L = ['# Folder catalog', '',
         'Written by `make proof-index` (tools/vv/run_proof_index.py); do not edit by hand. '
         'Generated from [`PROOFS.csv`](PROOFS.csv): one row per folder, duplicates counted once '
         '(a row with `duplicate_of` set is omitted, the same rule as the README). '
         'Every count below is computed from those rows. '
         'Silver is the `silver` text; Training-ready is `training_ready`; Stub is `stub`; '
         'Needs implementation is `implement_next`; Open findings is `open_findings`. '
         'The topic index sums Open findings.', '']
    L += ['## Topic index', '']
    headers = ['Topic', 'Folders'] + levels + ['Training-ready', 'Stub', 'Needs implementation', 'Open findings']
    L.append('| ' + ' | '.join(headers) + ' |')
    L.append('|' + '|'.join(['---'] + ['---:'] * (len(headers) - 1)) + '|')
    for t in topics:
        rs = [r for r in uniq if r['topic'] == t]
        L.append('| ' + ' | '.join([f'[{t}](#{t})'] + counts(rs)) + ' |')
    L.append('| ' + ' | '.join(['All'] + counts(uniq)) + ' |')
    L.append('')
    silver = {}
    for r in uniq:
        k = r.get('silver', '')
        silver[k] = silver.get(k, 0) + 1
    L.append('Silver (duplicates counted once): '
             + ', '.join(f'{k} {v}' for k, v in sorted(silver.items(), key=lambda kv: (-kv[1], kv[0])))
             + '.')
    L.append('')
    L += ['## Training-ready', '',
          f'{_nfolders(len(ready))} with `training_ready` = yes (duplicates counted once).', '',
          '| ' + ' | '.join(h for h, _k in _COLS) + ' |',
          '|' + '|'.join(['---'] * len(_COLS)) + '|']
    L += [_folder_line(r) for r in ready]
    L.append('')
    for t in topics:
        rs = [r for r in uniq if r['topic'] == t]
        L += [f'## {t}', '', _nfolders(len(rs), dot=True), '']
        for lv in levels:
            grp = [r for r in rs if r['level'] == lv]
            if not grp:
                continue
            L += [f'### {t}/{lv}', '', _nfolders(len(grp), dot=True), '',
                  '| ' + ' | '.join(h for h, _k in _COLS) + ' |',
                  '|' + '|'.join(['---'] * len(_COLS)) + '|']
            L += [_folder_line(r) for r in grp]
            L.append('')
    return '\n'.join(L).rstrip() + '\n'

def write_catalog():
    path = os.path.join(root, 'PROOFS.csv')
    if not os.path.exists(path):
        sys.exit('run_proof_index: no PROOFS.csv to write CATALOG.md from')
    rows = list(csv.DictReader(open(path, newline='')))
    text = catalog_text(rows)
    dest = os.path.join(root, 'CATALOG.md')
    old = open(dest).read() if os.path.exists(dest) else None
    if old != text:
        open(dest, 'w').write(text)
        return True
    return False

if a.catalog_only:
    if a.results or a.logs or a.allow_input_change or extra:
        sys.exit('run_proof_index: --catalog-only writes CATALOG.md from PROOFS.csv and takes no other arguments')
    print('CATALOG.md ' + ('updated' if write_catalog() else 'unchanged'))
    sys.exit(0)

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
cat_changed = write_catalog()
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
print('CATALOG.md ' + ('updated' if cat_changed else 'unchanged'))
print(f'run_proof_index: {how}; {len(diffs)} input change(s)' + (' (allowed)' if diffs else '')
      + f'; training-ready {len(tr)} = {len(tr - pend)} confirmed + {len(tr & pend)} pending re-score; recount_strict.py agrees')
