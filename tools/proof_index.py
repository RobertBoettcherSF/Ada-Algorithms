#!/usr/bin/env python3
"""Regenerate PROOFS.md / PROOFS.csv (one row per algorithm folder).

Inputs are the per-folder results written by tools/audit/build_folder.sh and
tools/audit/prove_folder.sh (JSON lines) plus the gnatprove logs:
  python3 tools/proof_index.py --results DIR --logs PROVE_WORKDIR
DIR must contain build.jsonl and prove.jsonl (last line per folder wins).
Run from the repo root.  Without results the columns show 'not run'.
"""
import argparse, csv, difflib, hashlib, json, os, re, collections
LEVELS = ('Ada', 'SPARK1', 'SPARK2', 'SPARK3', 'SPARK4')
SKIP = {'bin', 'obj', 'src', 'tests', 'gnatprove'}
ap = argparse.ArgumentParser()
ap.add_argument('--results', default='')
ap.add_argument('--logs', default='')
ap.add_argument('--root', default='.')
ap.add_argument('--steps-logs', default='', help='workdir of step-budget reruns (prove_steps.jsonl in --results)')
ap.add_argument('--tool-info', default='', help='text file with gnatprove --version output')
ap.add_argument('--batch-cmd', default='gnatprove -P <folder gpr> --mode=silver --level=2 -j1 --output=oneline -k')
ap.add_argument('--steps-cmd', default='gnatprove -P <folder gpr> --mode=silver --level=2 --timeout=0 --steps=<N> --counterexamples=off -j2 --output=oneline -k')
a = ap.parse_args()
R = a.root

def jl(p):
    d = {}
    if p and os.path.exists(p):
        for l in open(p):
            try:
                j = json.loads(l); d[j['id']] = j
            except Exception:
                pass
    return d
B = jl(os.path.join(a.results, 'build.jsonl')) if a.results else {}
P = jl(os.path.join(a.results, 'prove.jsonl')) if a.results else {}
S = jl(os.path.join(a.results, 'prove_steps.jsonl')) if a.results else {}
chk = re.compile(r'^[\w\-.]+\.ad[sb]:\d+:\d+: (high|medium|low): ')
spark_on = re.compile(r'SPARK_Mode(\s*=>\s*On\b|\s*;|\s*\(\s*On\s*\))', re.I)

def norm_name(n):
    n = n.lower()
    for p in ('ada-spark-', 'ada-'):
        if n.startswith(p): n = n[len(p):]
    n = re.sub(r'[^a-z0-9]', '', n)
    return re.sub(r'algorithm$', '', n) or n

def srcfiles(path):
    out = []
    for dp, dn, fn in os.walk(path):
        dn[:] = [d for d in dn if d not in ('obj', 'bin', 'gnatprove')]
        out += [os.path.relpath(os.path.join(dp, f), path) for f in fn if f.endswith(('.ads', '.adb'))]
    return out

def pkg_text(path):
    out = []
    for f in sorted(srcfiles(path)):
        if not os.path.basename(f).startswith(('test', 'main')):
            t = open(os.path.join(path, f), errors='replace').read()
            t = re.sub(r'--[^\n]*', '', t)
            out.append(re.sub(r'\s+', ' ', t).strip().lower())
    return '\n'.join(out)

folders = []
for topic in sorted(os.listdir(R)):
    tp = os.path.join(R, topic)
    if topic.startswith('.') or not os.path.isdir(tp) or topic in SKIP | {'tools'}: continue
    for lev in sorted(os.listdir(tp)):
        lp = os.path.join(tp, lev)
        if lev not in LEVELS or not os.path.isdir(lp): continue
        for alg in sorted(os.listdir(lp)):
            p = os.path.join(lp, alg)
            if os.path.isdir(p) and alg not in SKIP:
                folders.append((topic, lev, alg, p))

def silver(fid, has_spark, built):
    if not has_spark: return 'no SPARK'
    j, logs = (S[fid], a.steps_logs) if fid in S else (P.get(fid), a.logs)
    if not j: return 'not run'
    if j.get('status') == 'no_sources': return 'not built'
    log = os.path.join(logs, fid.replace('/', '_'), 'prove.log') if logs else ''
    txt = open(log, errors='replace').read() if log and os.path.exists(log) else ''
    n = sum(1 for l in txt.splitlines() if chk.match(l))
    if j.get('rc') == 124: return 'timeout'
    if 'GNAT BUG DETECTED' in txt: return 'tool crash'
    if n: return f'{n} unproved'
    if j.get('rc') != 0 or ': error:' in txt: return 'not built'
    return 'proven'

rows = []
texts = {}
for topic, lev, alg, p in folders:
    fid = f'{topic}/{lev}/{alg}'
    srcs = srcfiles(p)
    has_mode = any(spark_on.search(open(os.path.join(p, f), errors='replace').read())
                   for f in srcs if not os.path.basename(f).startswith('test'))
    has_spark = has_mode or (lev != 'Ada' and bool(srcs))
    b = B.get(fid, {})
    def ok(k): return '' if not b else ('yes' if b.get(k) == '0' else 'no')
    mk = '' if not b else ('n/a' if b.get('mk14') in ('NA', None) else ('yes' if b.get('mk14') == '0' and not b.get('fail_mk14') else 'no'))
    tp14 = '' if not b else ('yes' if mk == 'yes' or (b.get('r14') == '0' and not b.get('fail_r14')) else 'no')
    tp12 = '' if not b else ('yes' if (b.get('mk12') == '0' and not b.get('fail_mk12')) or (b.get('r12') == '0' and not b.get('fail_r12')) else 'no')
    rows.append(dict(folder=fid, topic=topic, level=lev, algorithm=alg, make_test=mk,
                     build_gnat14=ok('u14'), build_gnat12=ok('u12'),
                     tests_pass_gnat14=tp14, tests_pass_gnat12=tp12,
                     warnings_gnat14=b.get('w14', ''), warnings_gnat12=b.get('w12', ''),
                     silver=(silver(fid, has_spark, ok('u14')) if has_mode or not has_spark else 'skipped (no SPARK_Mode)'),
                     proof_run=('steps=%s' % S[fid].get('steps') if fid in S else ('level2-timeout' if fid in P else '')) if has_spark else '',
                     proof_gpr=(P.get(fid, {}).get('gpr', '') + (' (generated)' if P.get(fid, {}).get('how') == 'generated' else '')) if has_spark else '',
                     shared_sources=' '.join(b.get('shared', [])), pair='', duplicate_of=''))
    texts[fid] = pkg_text(p)

# duplicates: identical package sources (comments/whitespace ignored) or same name+level with >=90% similar text
by_hash = collections.defaultdict(list)
for r in rows:
    t = texts[r['folder']]
    if t: by_hash[hashlib.sha1(t.encode()).hexdigest()].append(r['folder'])
dup = {}
for g in by_hash.values():
    for f in g[1:]: dup[f] = g[0] + ' (identical)'
by_nl = collections.defaultdict(list)
for r in rows: by_nl[(re.sub(r'(lite|stub)$', '', norm_name(r['algorithm'])), r['level'])].append(r['folder'])
for g in by_nl.values():
    for f in g[1:]:
        if f in dup or not texts[f] or not texts[g[0]]: continue
        x, y = texts[g[0]], texts[f]
        if difflib.SequenceMatcher(None, x[:20000], y[:20000], autojunk=False).quick_ratio() >= 0.9 and \
           difflib.SequenceMatcher(None, x[:20000], y[:20000], autojunk=False).ratio() >= 0.9:
            dup[f] = g[0] + ' (near-identical)'
for r in rows: r['duplicate_of'] = dup.get(r['folder'], '')

# pairs: plain-Ada folder <-> SPARK folder(s) with the same normalized name (duplicates excluded)
spark_by = collections.defaultdict(list)
for r in rows:
    if r['level'] != 'Ada' and not r['duplicate_of']: spark_by[norm_name(r['algorithm'])].append(r['folder'])
npairs = 0
for r in rows:
    if r['level'] == 'Ada' and not r['duplicate_of']:
        m = spark_by.get(norm_name(r['algorithm']), [])
        if m:
            r['pair'] = ' '.join(m); npairs += 1
            for s in m:
                for q in rows:
                    if q['folder'] == s: q['pair'] = (q['pair'] + ' ' + r['folder']).strip()

with open(os.path.join(R, 'PROOFS.csv'), 'w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)

uniq = [r for r in rows if not r['duplicate_of']]
C = collections.Counter
def c(pred, rs=uniq): return sum(1 for r in rs if pred(r))
import datetime
tool = open(a.tool_info).read().strip() if a.tool_info and os.path.exists(a.tool_info) else '(tool info not given)'
reran = sorted(S)
L = ['# Proof index', '',
     f'Generated {datetime.datetime.now().astimezone():%Y-%m-%d %H:%M %Z}.', '',
     '## Proof setup', '', '```', tool, '```', '',
     f'* Batch (all SPARK folders): `{a.batch_cmd}` - level 2 = provers cvc5,z3,altergo, `--timeout=5` s per check (wall clock), `--steps=0`, `--memlimit=1000`, per_check, counterexamples off.',
     f'* Rerun with a deterministic step budget (rows with `proof_run` = `steps=N`; replaces the batch result): `{a.steps_cmd}` - no wall-clock timeout, so the result does not depend on machine load.',
     f'* Rows rerun with steps ({len(reran)}): ' + (', '.join(f"`{x}`" for x in reran) or 'none'), '',
     'One row per algorithm folder (full data in [`PROOFS.csv`](PROOFS.csv)). Regenerate with',
     '`python3 tools/proof_index.py --results <dir> --logs <prove-workdir>` (see `tools/audit/`).',
     'Builds: `gnatmake -gnatwa -gnat2022` on `tests.adb` (GNAT 14 system, GNAT 12 Alire). `make test` = the folder\'s own Makefile (GNAT 14). Tests pass = `make test` passes, or the uniform build\'s test binary exits 0 with no FAIL lines.',
     'Silver: `gnatprove --mode=silver --level=2` on the folder\'s own .gpr (generated where none exists).', '',
     f'Folders: {len(rows)}; duplicates (counted once): {len(rows) - len(uniq)}; Ada<->SPARK pairs: {npairs}.', '',
     '| Level | Folders | make test OK | Build 14 | Build 12 | Tests 14 | Tests 12 | 0 warn 14 | 0 warn 12 | Proven | Unproved | Not built/crash | Not run |',
     '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
for lev in ('Ada', 'SPARK2', 'SPARK4', 'All'):
    s = [r for r in uniq if lev == 'All' or r['level'] == lev]
    if not s: continue
    L.append(f"| {lev} | {len(s)} | {c(lambda r: r['make_test']=='yes', s)} | {c(lambda r: r['build_gnat14']=='yes', s)} | {c(lambda r: r['build_gnat12']=='yes', s)} | "
             f"{c(lambda r: r['tests_pass_gnat14']=='yes', s)} | {c(lambda r: r['tests_pass_gnat12']=='yes', s)} | "
             f"{c(lambda r: str(r['warnings_gnat14'])=='0' and r['build_gnat14']=='yes', s)} | {c(lambda r: str(r['warnings_gnat12'])=='0' and r['build_gnat12']=='yes', s)} | "
             f"{c(lambda r: r['silver']=='proven', s)} | {c(lambda r: r['silver'].endswith('unproved'), s)} | "
             f"{c(lambda r: r['silver'] in ('not built','tool crash','timeout'), s)} | {c(lambda r: r['silver']=='not run', s)} |")
L += ['', '| Folder | Make | B14 | B12 | T14 | T12 | W14 | W12 | Silver | Pair | Duplicate of |', '|---|---|---|---|---|---|---|---|---|---|---|']
for r in rows:
    L.append(f"| {r['folder']} | {r['make_test']} | {r['build_gnat14']} | {r['build_gnat12']} | {r['tests_pass_gnat14']} | {r['tests_pass_gnat12']} | "
             f"{r['warnings_gnat14']} | {r['warnings_gnat12']} | {r['silver']} | {r['pair']} | {r['duplicate_of']} |")
open(os.path.join(R, 'PROOFS.md'), 'w').write('\n'.join(L) + '\n')
print(f'{len(rows)} folders, {len(rows)-len(uniq)} duplicates, {npairs} pairs')
