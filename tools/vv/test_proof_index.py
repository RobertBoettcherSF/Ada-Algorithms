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
    'Handover-Gap':   ('', ['open handover gap']),
    'Clamp-Dead':     ('', ['clamp unreviewed or dead (clamp_scan)']),
    'Rescore-Pending': ('yes', []),   # meets rule v1 on its recorded score, but a codefix.csv fix came later
    'Rescored':       ('yes', []),    # same fix, then a tools/vv/rescored.csv row: confirmed again
}
# expected rescore_pending (non-empty) per folder; every other case must have it empty
PENDING = {'Rescore-Pending'}

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
    for t in ('synth_index_inputs.py', 'run_proof_index.py'):   # H188: `make proof-index` path
        if os.path.exists(os.path.join(HERE, t)):
            shutil.copy(os.path.join(HERE, t), os.path.join(root, 'tools', 'vv', t))
    res, logs = os.path.join(root, '_res'), os.path.join(root, '_logs')
    os.makedirs(res); os.makedirs(logs)
    B, P = open(os.path.join(res, 'build.jsonl'), 'w'), open(os.path.join(res, 'prove.jsonl'), 'w')
    fids = {}
    for i, alg in enumerate(CASES):
        fid = 'misc/SPARK2/Ada-SPARK-' + alg
        fids[alg] = fid
        # distinct package text so the catalog lists every folder (identical text would collapse them)
        w(os.path.join(root, fid, 'x.ads'),
          f'pragma SPARK_Mode (On);\npackage X is\n   N : constant Integer := {i};\nend X;\n')
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
          [fids['Rescore-Pending'], '', 'skipped', 'skipped', '', '', 'no unconstrained array type', ''],
          [fids['Rescored'], '', 'skipped', 'skipped', '', '', 'no unconstrained array type', ''],
          [fids['Topup-Summed'], 'F', 'catalog', 'catalog', '', '1', 'function n_arrays=1', ''],
          [fids['Topup-Summed'], 'F', 'ok', 'ok', '', '1', 'origins 0 and 100 agree', ''],
          [fids['Index-Pinned'], 'F', 'catalog', 'catalog', '', '1', 'function n_arrays=1', ''],
          [fids['Index-Pinned'], '', 'first_pinned', 'fail', '', '', "Pre requires A'First = 1", ''],
          [fids['Index-Unread'], 'F', 'catalog', 'catalog', '', '1', 'function n_arrays=1', '']])
    wcsv(os.path.join(vv, 'handover.csv'), ['id', 'category', 'folder', 'status'],
         [['H1', 'functional_gap', fids['Handover-Gap'] + '; misc/SPARK2/Ada-SPARK-Other', 'open'],
          ['H2', 'dead_code', fids['Good'], 'closed (fixed)'],
          ['H3', 'unproved_check', fids['Good'], 'open']])
    wcsv(os.path.join(vv, 'clamp_scan.csv'), ['folder', 'file_line', 'kind', 'helper', 'text', 'callers', 'reachable', 'evidence'],
         [[fids['Clamp-Dead'], 'x.adb:7', 'attr_return', 'Add', "return T'Last;", 'x.adb:20', 'unknown', ''],
          [fids['Good'], 'x.adb:9', 'attr_return', 'Wrap', "P := I'First;", 'x.adb:30', 'yes', 'wrap-around, reached']])
    wcsv(os.path.join(vv, 'codefix.csv'), ['folder', 'problem', 'test_commit', 'fix_commit', 'reference_check', 'agent'],
         [[fids['Rescore-Pending'], 'code fix', 't1', 'f1', 'own', 'x'],
          [fids['Rescored'], 'code fix', 't2', 'f2', 'own', 'x'],
          [fids['Open-Finding'], 'code fix, still not ready', 't3', 'f3', 'own', 'x']])
    wcsv(os.path.join(vv, 'rescored.csv'), ['folder', 'after_fix_commit', 'record'], [[fids['Rescored'], 'f2', 'control']])
    return res, logs, fids

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PATH_SCOPE = []   # whole repo (git ls-files): tracked files must not name absolute box paths (tools/vv/check_paths.py)

# check_placeholders.py control cases: (description, setup, expected exit code)
def placeholder_case(kind):
    """A throw-away repo with one flagged folder X (open handover placeholder row H901).
    good: open row + lines; missing: open row, README lacks the line; stale: row closed (handover closed)
    but the line is still there; unlisted: flagged folder without a placeholders.csv row; code: good plus
    an indented placeholder comment in an unlisted folder Y; code_ok: the same with Y's file allowlisted."""
    root = tempfile.mkdtemp(prefix='tph_')
    hstat = 'closed abc1234' if kind == 'stale' else 'open'
    wcsv(os.path.join(root, 'tools/vv/handover.csv'), ['id', 'category', 'folder', 'problem', 'status'],
         [['H901', 'placeholder', 'misc/SPARK2/X', 'table of answers', hstat]])
    wcsv(os.path.join(root, 'tools/vv/hidden_stub.csv'), ['folder', 'signal', 'verdict', 'stub_marked', 'was_training_ready'], [])
    wcsv(os.path.join(root, 'PROOFS.csv'), ['folder', 'stub'], [['misc/SPARK2/X', '']])
    line = 'PLACEHOLDER: table of answers; see H901'
    if kind != 'unlisted':
        wcsv(os.path.join(root, 'tools/vv/placeholders.csv'), ['folder', 'ref', 'what', 'status'],
             [['misc/SPARK2/X', 'H901', 'table of answers', 'closed abc1234' if kind == 'stale' else 'open']])
    w(os.path.join(root, 'misc/SPARK2/X/README.md'), '# X\n' if kind == 'missing' else f'# X\n\n{line}\n')
    w(os.path.join(root, 'misc/SPARK2/X/x.ads'), f'--  {line}\npackage X is\nend X;\n')
    if kind in ('code', 'code_ok'):   # an indented placeholder comment in another folder
        w(os.path.join(root, 'misc/Ada/Y/y.adb'), 'procedure Y is\nbegin\n   null; -- PLACEHOLDER: not done\nend Y;\n')
        if kind == 'code_ok':
            wcsv(os.path.join(root, 'tools/vv/placeholder_comment_ok.csv'), ['folder', 'file', 'reason'],
                 [['misc/Ada/Y', 'y.adb', 'benign wording']])
    r = subprocess.run([sys.executable, os.path.join(REPO, 'tools/vv/check_placeholders.py'), '--root', root],
                       capture_output=True, text=True)
    shutil.rmtree(root, ignore_errors=True)
    return r.returncode
PH_CASES = [('good', 0), ('missing', 1), ('stale', 1), ('unlisted', 1), ('code', 1), ('code_ok', 0)]

def catalog_check(root, runner):
    """CATALOG.md from the committed PROOFS.csv: sections, live column text, computed counts, idempotent."""
    p = os.path.join(root, 'CATALOG.md')
    if not os.path.exists(p):
        return ('catalog', False, 'CATALOG.md missing')
    text = open(p).read()
    rows = list(csv.DictReader(open(os.path.join(root, 'PROOFS.csv'))))
    uniq = [r for r in rows if not r['duplicate_of']]
    ready = [r for r in uniq if r['training_ready'] == 'yes']
    topics = sorted({r['topic'] for r in uniq})
    levels = [lv for lv in ('Ada', 'SPARK1', 'SPARK2', 'SPARK3', 'SPARK4') if any(r['level'] == lv for r in uniq)]
    head = '| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |'
    sentence = (f"**{len(ready)} folder{'' if len(ready) == 1 else 's'}** "
                'with `training_ready` = yes (duplicates counted once).')

    def findings(rs):
        n = 0
        for r in rs:
            v = (r.get('open_findings') or '').strip()
            if v:
                n += int(v) if v.isdigit() else 1
        return n

    def counts(rs):
        return ([str(len(rs))]
                + [str(sum(1 for r in rs if r['level'] == lv)) for lv in levels]
                + [str(sum(1 for r in rs if r['training_ready'] == 'yes')),
                   str(sum(1 for r in rs if r['stub'] == 'yes')),
                   str(sum(1 for r in rs if r['implement_next'] == 'yes')),
                   str(findings(rs))])

    if '## Training-ready' not in text or not topics:
        return ('catalog', False, 'missing Training-ready section or topics')
    ok = ('do not edit by hand' in text and '## Topic index' in text
          and head in text and sentence in text and 'Rule v1' not in text
          and all(f'\n## {t}\n' in text for t in topics))
    for r in uniq:
        line = (f"| [{r['folder']}]({r['folder']}) | {r['silver']} | {r['training_ready']} | "
                f"{r['stub']} | {r['implement_next']} | {r['open_findings']} |")
        ok = ok and line in text
    for r in rows:
        if r['duplicate_of']:
            ok = ok and f"[{r['folder']}]({r['folder']})" not in text
    start = text.index('## Training-ready')
    rest = text[start:]
    section = rest[:rest.index('\n## ', len('## Training-ready'))]
    for r in uniq:
        link = f"[{r['folder']}]({r['folder']})"
        ok = ok and ((link in section) == (r['training_ready'] == 'yes'))
    ok = ok and ('| All | ' + ' | '.join(counts(uniq)) + ' |') in text
    for t in topics:
        rs = [r for r in uniq if r['topic'] == t]
        ok = ok and ('| ' + ' | '.join([f'[{t}](#{t})'] + counts(rs)) + ' |') in text
    before = text
    r = subprocess.run([sys.executable, runner, '--catalog-only'], cwd=root, capture_output=True, text=True)
    after = open(p).read()
    ok = ok and r.returncode == 0 and after == before and 'unchanged' in r.stdout
    return ('catalog', ok, f'ready {len(ready)} topics {len(topics)} uniq {len(uniq)} exit {r.returncode}')

# H188 control cases for tools/vv/run_proof_index.py (what `make proof-index` runs):
#   default  no --results: inputs synthesised from the committed PROOFS.csv; exit 0, headline unchanged
#   stale    --results whose build input disagrees with PROOFS.csv (Good gets 2 GNAT 12 warnings, like the
#            stale default results dir that gave 92 + 3): exit 2; PROOFS.csv / PROOFS.md / README.md /
#            docs/IMPLEMENT.md / CATALOG.md left untouched
#   allowed  the same stale inputs with --allow-input-change: exit 0 and Good drops (a deliberate new run)
def index_cases(root, res, logs, fids):
    out = []
    runner = os.path.join(root, 'tools', 'vv', 'run_proof_index.py')
    def snap():
        files = ('PROOFS.csv', 'PROOFS.md', 'README.md', 'CATALOG.md', os.path.join('docs', 'IMPLEMENT.md'))
        return {f: open(os.path.join(root, f)).read() for f in files if os.path.exists(os.path.join(root, f))}
    def tr():
        return {x['folder']: (x['training_ready'], bool(x['rescore_pending'])) for x in csv.DictReader(open(os.path.join(root, 'PROOFS.csv')))}
    before = tr()
    r = subprocess.run([sys.executable, runner], cwd=root, capture_output=True, text=True)
    out.append(('default', r.returncode == 0 and tr() == before, f'exit {r.returncode}' + ('' if r.returncode == 0 else ': ' + (r.stdout + r.stderr).strip()[-300:])))
    out.append(catalog_check(root, runner))
    stale = os.path.join(root, '_stale'); shutil.copytree(res, stale)
    lines = [json.loads(l) for l in open(os.path.join(stale, 'build.jsonl'))]
    for b in lines:
        if b['id'] == fids['Good']: b['w12'] = '2'
    open(os.path.join(stale, 'build.jsonl'), 'w').write(''.join(json.dumps(b) + '\n' for b in lines))
    s0 = snap()
    r = subprocess.run([sys.executable, runner, '--results', stale, '--logs', logs], cwd=root, capture_output=True, text=True)
    out.append(('stale', r.returncode == 2 and snap() == s0 and 'disagree' in (r.stdout + r.stderr), f'exit {r.returncode}'))
    r = subprocess.run([sys.executable, runner, '--results', stale, '--logs', logs, '--allow-input-change'], cwd=root, capture_output=True, text=True)
    out.append(('allowed', r.returncode == 0 and tr().get(fids['Good'], ('?',))[0] == '', f'exit {r.returncode}'))
    return out

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
            ok = x['training_ready'] == tr and reasons == why and bool(x['rescore_pending']) == (alg in PENDING)
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
        r5 = subprocess.run([sys.executable, 'tools/vv/recount_strict.py', '--results', res, '--logs', logs, '--pending'],
                            cwd=root, capture_output=True, text=True)
        recp = {l.strip() for l in r5.stdout.splitlines() if l.strip() and not l.startswith('#')}
        idxp = {f for f, x in got.items() if x['rescore_pending']}
        okp = r5.returncode == 0 and recp == idxp == {fids[a] for a in PENDING}
        bad += not okp
        print(('ok  ' if okp else 'FAIL') + f' rescore_pending: index and recount_strict.py --pending list the same {len(recp)} folder(s)'
              + ('' if okp else f': index {sorted(idxp)}, recount {sorted(recp)}'))
        IDX = index_cases(root, res, logs, fids)
        for name, ok, info in IDX:
            bad += not ok
            print(('ok  ' if ok else 'FAIL') + f' run_proof_index control {name:8} {info}')
        r3 = subprocess.run([sys.executable, os.path.join(REPO, 'tools/vv/check_paths.py')] + PATH_SCOPE,
                            capture_output=True, text=True)
        print(r3.stdout.rstrip().splitlines()[-1] if r3.stdout.strip() else r3.stderr)
        bad += r3.returncode != 0
        for kind, want in PH_CASES:
            got_rc = placeholder_case(kind)
            ok = got_rc == want
            bad += not ok
            print(('ok  ' if ok else 'FAIL') + f' check_placeholders control {kind:9} exit {got_rc} (expected {want})')
        r4 = subprocess.run([sys.executable, os.path.join(REPO, 'tools/vv/check_placeholders.py')], capture_output=True, text=True)
        print(r4.stdout.rstrip().splitlines()[-1] if r4.stdout.strip() else r4.stderr)
        bad += r4.returncode != 0
        total = len(CASES) + 4 + len(PH_CASES) + len(IDX)
        print(f"{total - bad}/{total} control checks pass")
        return 1 if bad else 0
    finally:
        shutil.rmtree(root, ignore_errors=True)

if __name__ == '__main__':
    sys.exit(main())
