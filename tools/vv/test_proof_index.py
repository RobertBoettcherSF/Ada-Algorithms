#!/usr/bin/env python3
"""Control rows for tools/proof_index.py (strict training_ready rule) and tools/vv/recount_strict.py.

Builds a throw-away repo with one synthetic folder per failure mode plus one folder that meets every
condition, runs both tools on it, and checks training_ready and the tr_drop reason of every row, and that
the independent recount lists exactly the same passing folders.
  python3 tools/vv/test_proof_index.py        (exit 0 = all control rows as expected)
"""
import csv, json, os, shutil, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)

# folder -> (expected training_ready, expected tr_drop reasons exactly)
CASES = {
    'Good':           ('yes', []),
    'No-Heldout':     ('', ['no held-out mutation score']),
    'Heldout-80':     ('', ['held-out mutation < 90%']),
    'Heldout-Small':  ('', ['held-out too small (n < 20)']),
    'Not-Blind':      ('', ['held-out not blind']),
    'Withdrawn':      ('', ['functional claim withdrawn (contract_scan)']),
    'Partial':        ('', ['partial functional claim (contract_scan)']),
    'Toy-Stub':       ('', ['stub']),
    'Open-Finding':   ('', ['open finding']),
    'Warn-12':        ('', ['warnings GNAT 12']),
    'Twin-Only':      ('', ['twin only']),
    'Escape':         ('', ['unjustified proof escape']),
    'Flaky':          ('', ['flaky (mutation does not count)']),
    'Topup-Summed':   ('yes', []),
    'Index-Pinned':   ('', ['index not independent']),
    'Index-Unread':   ('', ['index independence not measured']),
}

def w(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w').write(text)

def wcsv(path, header, rows):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', newline='') as f:
        c = csv.writer(f); c.writerow(header); c.writerows(rows)

def build(root):
    os.makedirs(os.path.join(root, 'tools', 'vv')); os.makedirs(os.path.join(root, 'docs'))
    shutil.copy(os.path.join(TOOLS, 'proof_index.py'), os.path.join(root, 'tools', 'proof_index.py'))
    shutil.copy(os.path.join(HERE, 'recount_strict.py'), os.path.join(root, 'tools', 'vv', 'recount_strict.py'))
    res, logs = os.path.join(root, '_res'), os.path.join(root, '_logs')
    os.makedirs(res); os.makedirs(logs)
    B, P = open(os.path.join(res, 'build.jsonl'), 'w'), open(os.path.join(res, 'prove.jsonl'), 'w')
    fids = {}
    for alg in CASES:
        fid = 'misc/SPARK2/Ada-SPARK-' + alg
        fids[alg] = fid
        w(os.path.join(root, fid, 'x.ads'), 'pragma SPARK_Mode (On);\npackage X is end X;\n')
        b = dict(id=fid, u14='0', u12='0', mk14='0', mk12='0', r14='0', r12='0', w14='0', w12='2' if alg == 'Warn-12' else '0',
                 ver14='GNATLS 14.2.0', ver12='GNATLS 12.2.0', shared=[])
        B.write(json.dumps(b) + '\n')
        P.write(json.dumps(dict(id=fid, gpr='x.gpr', rc=0)) + '\n')
        d = os.path.join(logs, fid.replace('/', '_')); os.makedirs(d)
        w(os.path.join(d, 'prove.log'), '')
        w(os.path.join(d, 'gnatprove.out'), 'Total 50\nFunctional Contracts 10\n')
    B.close(); P.close()
    vv = os.path.join(root, 'tools', 'vv')
    wcsv(os.path.join(vv, 'own_tests.csv'), ['folder', 'checks'], [[fids[a], 'own brute force'] for a in CASES if a != 'Twin-Only'])
    wcsv(os.path.join(root, 'vv', 'results', 'diff.csv'), ['pair', 'ada', 'spark', 'result', 'disagree', 'cases'],
         [['p1', 'misc/Ada/Twin', fids['Twin-Only'], 'agree', '0', '100']])
    wcsv(os.path.join(vv, 'flaky.csv'), ['folder', 'compiler', 'flaky'],
         [[fids[a], 'GNATMAKE 14.2.0', 'yes' if a == 'Flaky' else 'no'] for a in CASES])
    hb = ['folder', 'split_seed', 'mutation_tuned_k', 'mutation_tuned_n', 'heldout_family', 'heldout_seed', 'heldout_drawn',
          'mutation_heldout_k', 'mutation_heldout_n', 'heldout_pct', 'heldout_equivalent_excluded', 'heldout_timeouts_in_n', 'heldout_stillborn', 'notes']
    rows = []
    for a in CASES:
        if a == 'No-Heldout': continue
        k, n, pct, note = 30, 30, '100.0%', 'blind'
        if a == 'Heldout-80': k, n, pct = 24, 30, '80.0%'
        if a == 'Heldout-Small': k, n, pct = 12, 12, 'too small (n=12 < 20): not scored'
        if a == 'Not-Blind': note = 'RERUN, NOT BLIND (held summary seen)'
        if a == 'Topup-Summed':   # first row too small, then a top-up row that supersedes it
            rows.append([fids[a], '1', '9', '9', 'std+alt', '1', '', '12', '12', 'too small (n=12 < 20): not scored', '0', '0', '0', 'too small'])
            k, n, pct = 42, 42, '100.0%'
        rows.append([fids[a], '1', '9', '9', 'std+alt', '1', '', str(k), str(n), pct, '0', '0', '0', note])
    wcsv(os.path.join(vv, 'sweep_heldout_B.csv'), hb, rows)
    wcsv(os.path.join(vv, 'contract_scan.csv'),
         ['folder', 'file', 'subprogram', 'check', 'trivial_body', 'prove_result', 'pre_reject_rate', 'verdict', 'withdraw_functional', 'reason', 'owner', 'status', 'fix_commit', 'notes'],
         [[fids['Withdrawn'], 'x.ads', 'S', 'Post', 'return Input', 'proves', '', 'too weak', 'yes', 'Post too weak', '', 'open', '', ''],
          [fids['Partial'], 'x.ads', 'S', 'Post', '', '', '', 'partial', 'no', 'if found then correct only', '', 'open', '', '']])
    wcsv(os.path.join(vv, 'findings.csv'), ['folder', 'description', 'status', 'test_commit', 'fix_commit'],
         [[fids['Open-Finding'], 'wrong answer', 'open', '', '']])
    wcsv(os.path.join(vv, 'proof_escapes.csv'), ['folder', 'file', 'line', 'kind', 'text', 'justification', 'justified'],
         [[fids['Escape'], 'x.adb', '1', 'Assume', 'pragma Assume (X)', '', 'no'],
          [fids['Good'], 'x.adb', '1', 'Annotate', 'pragma Annotate (GNATprove, ...)', 'written reason', 'yes']])
    wcsv(os.path.join(vv, 'index_shift.csv'), ['folder', 'subprogram', 'kind', 'status', 'fix_kind', 'n_array_params', 'detail', 'note'],
         [[fids['Good'], '', 'skipped', 'skipped', '', '', 'no unconstrained array type', ''],
          [fids['Topup-Summed'], 'F', 'catalog', 'catalog', '', '1', 'function n_arrays=1', ''],
          [fids['Topup-Summed'], 'F', 'ok', 'ok', '', '1', 'origins 0 and 100 agree', ''],
          [fids['Index-Pinned'], 'F', 'catalog', 'catalog', '', '1', 'function n_arrays=1', ''],
          [fids['Index-Pinned'], '', 'first_pinned', 'fail', '', '', "Pre requires A'First = 1", ''],
          [fids['Index-Unread'], 'F', 'catalog', 'catalog', '', '1', 'function n_arrays=1', '']])
    return res, logs, fids

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PATH_SCOPE = []   # whole repo (git ls-files): tracked files must not name absolute box paths (tools/vv/check_paths.py)

def main():
    root = tempfile.mkdtemp(prefix='tpi_')
    try:
        res, logs, fids = build(root)
        r = subprocess.run([sys.executable, 'tools/proof_index.py', '--results', res, '--logs', logs], cwd=root, capture_output=True, text=True)
        if r.returncode:
            print(r.stdout, r.stderr); return 1
        got = {x['folder']: x for x in csv.DictReader(open(os.path.join(root, 'PROOFS.csv')))}
        bad = 0
        for alg, (tr, why) in CASES.items():
            x = got[fids[alg]]
            reasons = [s for s in x['tr_drop'].split('; ') if s]
            ok = x['training_ready'] == tr and reasons == why
            bad += not ok
            print(('ok  ' if ok else 'FAIL') + f" {alg:14} training_ready={x['training_ready'] or '-':3} tr_drop={x['tr_drop'] or '-'}"
                  + ('' if ok else f"   (expected {tr or '-'} / {'; '.join(why) or '-'})"))
        r2 = subprocess.run([sys.executable, 'tools/vv/recount_strict.py', '--results', res, '--logs', logs, '--list'],
                            cwd=root, capture_output=True, text=True)
        if r2.returncode:
            print(r2.stdout, r2.stderr); return 1
        rec = {l.strip() for l in r2.stdout.splitlines() if l.strip() and not l.startswith('#')}
        idx = {f for f, x in got.items() if x['training_ready'] == 'yes'}
        same = rec == idx
        bad += not same
        print(('ok  ' if same else 'FAIL') + f' recount_strict.py lists the same {len(rec)} passing folder(s)'
              + ('' if same else f': only index {sorted(idx - rec)}, only recount {sorted(rec - idx)}'))
        r3 = subprocess.run([sys.executable, os.path.join(REPO, 'tools/vv/check_paths.py')] + PATH_SCOPE,
                            capture_output=True, text=True)
        print(r3.stdout.rstrip().splitlines()[-1] if r3.stdout.strip() else r3.stderr)
        bad += r3.returncode != 0
        print(f"{len(CASES) + 2 - bad}/{len(CASES) + 2} control checks pass")
        return 1 if bad else 0
    finally:
        shutil.rmtree(root, ignore_errors=True)

if __name__ == '__main__':
    sys.exit(main())
