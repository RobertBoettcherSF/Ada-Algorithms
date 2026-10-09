#!/usr/bin/env python3
"""Summarise a score138_thin.py detail CSV into tools/vv/score138_calibration.csv.

Diagnostic only (docs/VV.md, "score138 calibration"): it does not change any
training_ready rule or count.

  python3 tools/vv/score138_calibrate.py DETAIL.csv [--sample F1,F2,...]

Rows (column `section`):
  Also fills column kill_mode of the held rows in tools/vv/score138_sealed.csv.
  folder_family  per folder and mutant kind: hidden non-equivalent n, recorded kills
                 (tests + proof), kills by the full tests on rerun, kills by the thinned
                 tests (tests only, no proof pass), and the kill mode of every recorded kill.
  folder_total   the same per folder plus calib: weak if the thinned tests alone still
                 kill >= 90% of the hidden non-equivalent mutants, ok otherwise.
  kind_all       per kind across all folders: catch rate (recorded k/n) and kill-mode mix.
  total_all      all kinds, all folders.
Kill modes: test_check (FAIL line or assertion in the test files), contract (Pre/Post/
assertion in the unit), runtime_error (Constraint_Error etc. from the unit), uninit (only
the Initialize_Scalars + -gnatVa rerun kills), proof (no test kill; canonical gnatprove
failure), nondeterministic (recorded kill not reproduced on the full rerun).
"""
import argparse, csv, os, collections

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'score138_calibration.csv')
HALVES = os.path.join(HERE, 'score138_halves.csv')
MODES = ['test_check', 'contract', 'runtime_error', 'uninit', 'proof', 'nondeterministic']
COLS = ['section', 'folder', 'kind', 'sample', 'n', 'recorded_k', 'full_tests_k', 'thinned_tests_k',
        'recorded_pct', 'thinned_pct', 'calib'] + MODES + ['note']
FAM_ORDER = ['std', 'alt', 'ho', 'B', 'C']


def pct(k, n):
    return f'{100.0 * k / n:.1f}' if n else ''


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('detail'); ap.add_argument('--sample', default='')
    ap.add_argument('--note', action='append', default=[], help='FOLDER=text, added to the folder_total row')
    a = ap.parse_args()
    sample = set(s for s in a.sample.split(',') if s)
    rows = [r for r in csv.DictReader(open(a.detail)) if r['index']]
    by = collections.defaultdict(dict)   # (folder, index) -> {variant: row}
    for r in rows:
        by[(r['folder'], r['index'])][r['variant']] = r
    agg = collections.defaultdict(collections.Counter)
    for (folder, idx), v in by.items():
        full = v['full']; th = v.get('thinned')
        fam = full['family']
        for key in [(folder, fam), (folder, '*'), ('*', fam), ('*', '*')]:
            c = agg[key]
            c['n'] += 1
            if full['recorded'] == 'killed':
                c['recorded_k'] += 1
                if full['recorded_kill_kind'] == 'proof':
                    c['proof'] += 1
                elif full['tests_result'] == 'killed':
                    c[full['mode'] or 'test_check'] += 1
                else:
                    c['nondeterministic'] += 1
            if full['tests_result'] == 'killed':
                c['full_tests_k'] += 1
            if th is not None:
                c['has_thin'] = 1
                if th['tests_result'] == 'killed':
                    c['thinned_tests_k'] += 1
    out = []
    folders = sorted({f for f, _ in agg if f != '*'})

    def row(section, folder, kind, c, note=''):
        r = dict(section=section, folder=folder, kind=kind,
                 sample='yes' if folder in sample else ('' if folder == '*' else 'no'),
                 n=c['n'], recorded_k=c['recorded_k'], full_tests_k=c['full_tests_k'],
                 thinned_tests_k=c['thinned_tests_k'] if c['has_thin'] else '',
                 recorded_pct=pct(c['recorded_k'], c['n']),
                 thinned_pct=pct(c['thinned_tests_k'], c['n']) if c['has_thin'] else '', calib='', note=note)
        for m in MODES:
            r[m] = c[m]
        return r
    notes = dict(x.split('=', 1) for x in a.note)
    calib = {}
    for f in folders:
        for fam in FAM_ORDER:
            if (f, fam) in agg:
                out.append(row('folder_family', f, fam, agg[(f, fam)]))
        c = agg[(f, '*')]
        r = row('folder_total', f, 'all', c, notes.get(f, ''))
        r['calib'] = ('weak' if c['thinned_tests_k'] >= 0.9 * c['n'] else 'ok') if c['has_thin'] else 'pending'
        calib[f] = r['calib']
        out.append(r)
    for fam in FAM_ORDER:
        if ('*', fam) in agg:
            out.append(row('kind_all', '*', fam, agg[('*', fam)]))
    out.append(row('total_all', '*', 'all', agg[('*', '*')]))
    with open(OUT, 'w', newline='') as fh:
        w = csv.DictWriter(fh, COLS); w.writeheader(); w.writerows(out)
    # informational calib column on the held-out halves rows (never read by the strict rule)
    hr = list(csv.DictReader(open(HALVES)))
    cols = list(hr[0].keys())
    if 'calib' not in cols:
        cols.append('calib')
    for r in hr:
        r['calib'] = calib.get(r['folder'], 'pending') if r['half'] == 'heldout' else ''
    with open(HALVES, 'w', newline='') as fh:
        w = csv.DictWriter(fh, cols); w.writeheader(); w.writerows(hr)
    # kill mode of every held mutant into score138_sealed.csv (raw data for a later recount)
    sp = os.path.join(HERE, 'score138_sealed.csv')
    mode = {}
    for (folder, idx), v in by.items():
        full = v['full']
        if full['recorded'] != 'killed':
            continue
        mode[(folder, idx)] = ('proof' if full['recorded_kill_kind'] == 'proof' else
                               (full['mode'] or 'test_check') if full['tests_result'] == 'killed' else 'nondeterministic')
    sr = list(csv.DictReader(open(sp)))
    for r in sr:
        if (r.get('half') or 'held') == 'held' and (r['folder'], r['index']) in mode:
            r['kill_mode'] = mode[(r['folder'], r['index'])]
    with open(sp, 'w', newline='') as fh:
        w = csv.DictWriter(fh, list(sr[0].keys()), lineterminator='\n'); w.writeheader(); w.writerows(sr)
    print(f'wrote {OUT}: {len(out)} rows; calib', collections.Counter(calib.values()))


if __name__ == '__main__':
    main()
