#!/usr/bin/env python3
"""Regenerate PROOFS.md / PROOFS.csv (one row per algorithm folder).

Inputs are the per-folder results written by tools/audit/build_folder.sh and
tools/audit/prove_folder.sh (JSON lines) plus the gnatprove logs:
  python3 tools/proof_index.py --results DIR --logs PROVE_WORKDIR
DIR must contain build.jsonl and prove.jsonl (last line per folder wins).
Run from the repo root.  Without results the columns show 'not run'.
"""
import glob, argparse, csv, difflib, hashlib, json, os, re, collections
LEVELS = ('Ada', 'SPARK1', 'SPARK2', 'SPARK3', 'SPARK4')
SKIP = {'bin', 'obj', 'src', 'tests', 'gnatprove'}
ap = argparse.ArgumentParser()
ap.add_argument('--results', default='')
ap.add_argument('--logs', default='')
ap.add_argument('--root', default='.')
ap.add_argument('--steps-logs', default='', help='workdir of step-budget reruns (prove_steps.jsonl in --results)')
ap.add_argument('--vv', default='vv/results', help='V&V results dir (diff.csv, mutation*.csv); kat registry: tools/vv/kat_registry.csv')
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

def proof_counts(fid):
    """(total checks, functional-contract checks) from gnatprove.out of the run used, or (None, None)."""
    logs = a.steps_logs if fid in S else a.logs
    if not logs: return None, None
    base = os.path.join(logs, fid.replace('/', '_'))
    for dp, dn, fn in os.walk(base):
        if 'gnatprove.out' in fn:
            t = open(os.path.join(dp, 'gnatprove.out'), errors='replace').read()
            m = re.search(r'^Total\s+(\d+)', t, re.M)
            f = re.search(r'^Functional Contracts\s+(\d+|\.)', t, re.M)
            return (int(m.group(1)) if m else 0), (int(f.group(1)) if f and f.group(1) != '.' else 0)
    return None, None

TRIVIAL_MAX = 3   # proven with <= this many checks -> 'trivial'

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

# folders named *-Stub that were generalised (arbitrary length, real algorithm): no longer counted as stubs
GEN_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'generalised_stubs.txt')
# folders whose README calls them a stub although the name does not end in -Stub
README_STUB_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'readme_stubs.txt')
README_STUBS = {l.split('\t')[0].strip() for l in open(README_STUB_FILE) if l.strip() and not l.startswith('#')} if os.path.exists(README_STUB_FILE) else set()
GEN = set(l.strip() for l in open(GEN_FILE) if l.strip() and not l.startswith('#')) if os.path.exists(GEN_FILE) else set()
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
    mk12 = '' if not b else ('n/a' if b.get('mk12') in ('NA', None) else ('yes' if b.get('mk12') == '0' and not b.get('fail_mk12') else 'no'))
    rows.append(dict(folder=fid, topic=topic, level=lev, algorithm=alg, make_test=mk, make_test_gnat12=mk12,
                     build_gnat14=ok('u14'), build_gnat12=ok('u12'),
                     tests_pass_gnat14=tp14, tests_pass_gnat12=tp12,
                     warnings_gnat14=b.get('w14', ''), warnings_gnat12=b.get('w12', ''),
                     silver=(silver(fid, has_spark, ok('u14')) if has_mode or not has_spark else 'skipped (no SPARK_Mode)'),
                     checks='', functional_checks='', trivial='',
                     proof_run=('steps=%s' % S[fid].get('steps') if fid in S else (('steps=%s' % P[fid]['steps']) if P.get(fid, {}).get('steps') else ('level2-timeout' if fid in P else ''))) if has_spark else '',
                     proof_gpr=(P.get(fid, {}).get('gpr', '') + (' (generated)' if P.get(fid, {}).get('how') == 'generated' else '')) if has_spark else '',
                     shared_sources=' '.join(b.get('shared', [])), stub=('yes' if (re.search(r'(^|-)stub$', alg, re.I) and fid not in GEN) or fid in README_STUBS else ''), generalised=('yes' if fid in GEN else ''), pair='', duplicate_of=''))
    texts[fid] = pkg_text(p)

for r in rows:
    if r['silver'] == 'proven':
        t, f = proof_counts(r['folder'])
        if t is not None:
            r['checks'], r['functional_checks'] = t, f
            r['trivial'] = 'yes' if t <= TRIVIAL_MAX else ''

# V&V columns (docs/VV.md): differential test, mutation score, known-answer vectors
def _csv(path):
    return list(csv.DictReader(open(path))) if os.path.exists(path) else []
VVD = os.path.join(a.root, a.vv) if not os.path.isabs(a.vv) else a.vv
diff_by = {}
for d in _csv(os.path.join(VVD, 'diff.csv')):
    v = d['result'] if d['result'] == 'agree' else f"{d['result']} {d['disagree']}/{d['cases']}"
    for side in ('ada', 'spark'):
        diff_by[d[side]] = f"{v} (vs {d['spark' if side == 'ada' else 'ada']}, {d['cases']} cases)"
mut_by = {}
for mf in sorted(glob.glob(os.path.join(VVD, 'mutation*.csv'))):
    if mf.endswith('_detail.csv'):
        continue
    for m in _csv(mf):
        mut_by[m['folder']] = m['score'] or ('baseline ' + m['baseline'] if m['baseline'] != 'pass' else 'no sites')
kat_by = {k['folder']: k['source'] for k in _csv(os.path.join(a.root, 'tools', 'vv', 'kat_registry.csv'))}
# do-nothing check (tools/vv/donothing.py): 'weak' = the tests still pass when the main subprogram does nothing
dn_by = {d['folder']: d['verdict'] for d in _csv(os.path.join(VVD, 'donothing.csv'))}
# own tests (tools/vv/own_tests.csv): self-written properties / brute-force references, tests/SOURCES.txt per folder
own_by = {o['folder']: o['checks'] for o in _csv(os.path.join(a.root, 'tools', 'vv', 'own_tests.csv'))}
# findings registry (tools/vv/findings.csv): a folder with an open finding is not training-ready
find_open = collections.Counter(f['folder'] for f in _csv(os.path.join(a.root, 'tools', 'vv', 'findings.csv')) if f['status'] == 'open')
# the sweep worker's registry (tools/vv/findings_sweep.csv) counts the same way
find_open.update(f['folder'] for f in _csv(os.path.join(a.root, 'tools', 'vv', 'findings_sweep.csv')) if f.get('status') == 'open')
# the flagship worker's registry (tools/vv/findings_flagship.csv) counts the same way
find_open.update(f['folder'] for f in _csv(os.path.join(a.root, 'tools', 'vv', 'findings_flagship.csv')) if f.get('status') == 'open')
# flagship results (tools/vv/flagship_*.csv, any file with a `folder` column): informational column `flagship`
flag_by = collections.defaultdict(list)
for ff in sorted(glob.glob(os.path.join(a.root, 'tools', 'vv', 'flagship_*.csv'))):
    stem = os.path.basename(ff)[len('flagship_'):-len('.csv')]
    for x in _csv(ff):
        if x.get('folder') and stem not in flag_by[x['folder']]:
            flag_by[x['folder']].append(stem)
# sweep progress (tools/vv/sweep_progress.csv, written by the sweep worker): informational column `sweep`
sweep_by = {}
for x in _csv(os.path.join(a.root, 'tools', 'vv', 'sweep_progress.csv')):
    if x.get('folder'):
        sweep_by[x['folder']] = x.get('status') or ('own tests (sweep); mutation ' + x['mutation_score'].split('->')[-1].strip() if x.get('tests_added') and x.get('mutation_score') else ('own tests (sweep)' if x.get('tests_added') else ''))
# training_ready rules 3 and 4 (tools/vv/escapes_scan.py): warning suppression and proof escapes
# SPARK4 sorts whose proof rests on a final Bubble_Finish pass that masks the named algorithm
# (tools/vv/sweep_masking.csv, written by the sweep worker): column masked_by_finish, not training-ready
mask_by = set()
for x in _csv(os.path.join(a.root, 'tools', 'vv', 'sweep_masking.csv')):
    flag = (x.get('masked_by_finish') or x.get('masked') or 'yes').strip().lower()
    if x.get('folder') and flag in ('yes', 'y', 'true', '1'):
        mask_by.add(x['folder'])
# surviving mutants accepted as equivalent (tools/vv/sweep_equivalent.csv): only with exhaustive evidence
# or a written reason; key = folder + file basename + line + operator, matched against vv/results/mutation*_detail.csv
equiv_keys = set()
for x in _csv(os.path.join(a.root, 'tools', 'vv', 'sweep_equivalent.csv')):
    m = re.match(r'^\s*([^:\s]+):(\d+)\s+(.+?)\s+\(', x.get('mutant', ''))
    if m and (x.get('method', '').strip() == 'exhaustive' or x.get('range_or_reason', '').strip()):
        equiv_keys.add((x['folder'], os.path.basename(m.group(1)), int(m.group(2)), m.group(3).strip()))
# the flagship worker's list (tools/vv/flagship_equivalent.csv: folder,file,line,mutant,method,range_or_reason)
# names the line, not always the operator: it covers any surviving mutant on that line
for x in _csv(os.path.join(a.root, 'tools', 'vv', 'flagship_equivalent.csv')):
    if x.get('line', '').strip().isdigit() and (x.get('method', '').strip() == 'exhaustive' or x.get('range_or_reason', '').strip()):
        equiv_keys.add((x['folder'], os.path.basename(x['file']), int(x['line']), None))
equiv_by = collections.Counter()
for mf in sorted(glob.glob(os.path.join(VVD, 'mutation*_detail.csv'))):
    for d in _csv(mf):
        k4 = (d['folder'], os.path.basename(d['file']), int(d['line']))
        if d.get('result') == 'survived' and (k4 + (d['op'].strip(),) in equiv_keys or k4 + (None,) in equiv_keys):
            equiv_by[d['folder']] += 1
supp_by = collections.Counter(x['folder'] for x in _csv(os.path.join(a.root, 'tools', 'vv', 'warnings_suppressed.csv')))
esc_all = collections.Counter(x['folder'] for x in _csv(os.path.join(a.root, 'tools', 'vv', 'proof_escapes.csv')))
esc_bare = collections.Counter(x['folder'] for x in _csv(os.path.join(a.root, 'tools', 'vv', 'proof_escapes.csv')) if x['justified'] != 'yes')
for r in rows:
    r['open_findings'] = str(find_open[r['folder']]) if find_open[r['folder']] else ''
    r['diff_test'] = diff_by.get(r['folder'], '')
    r['mutation'] = mut_by.get(r['folder'], '')
    r['kat'] = kat_by.get(r['folder'], '')
    r['do_nothing'] = dn_by.get(r['folder'], '')
    r['sweep'] = sweep_by.get(r['folder'], '')
    r['flagship'] = ' '.join(flag_by.get(r['folder'], []))
    r['own_tests'] = 'yes' if r['folder'] in own_by or r['sweep'].startswith('own tests') or os.path.exists(os.path.join(a.root, r['folder'], 'tests', 'SOURCES_sweep.txt')) else ''
    r['warnings_suppressed'] = 'yes' if supp_by[r['folder']] else ''
    r['proof_escapes'] = str(esc_all[r['folder']]) if esc_all[r['folder']] else ''
    if esc_bare[r['folder']] and r['silver'] == 'proven':   # rule 4: an unexplained escape voids the proof claim
        r['silver'] = 'proven, unjustified escape'
    r['masked_by_finish'] = 'yes' if r['folder'] in mask_by else ''
    m = re.match(r'^(\d+)/(\d+)$', r['mutation'])
    eq = equiv_by[r['folder']] if m else 0
    den = int(m.group(2)) - eq if m else 0
    r['mutation_score'] = ((f"{100 * int(m.group(1)) // den}%" if den > 0 else '100%') + (f" ({eq} equivalent)" if eq else '') if m and int(m.group(2)) else
                           ('no sites' if r['mutation'] == 'no sites' else ''))

# known_answer: the expected values come from somewhere other than the program itself - a registered
# known-answer vector, own tests (properties / own brute-force reference), or an agreeing differential
# test against the twin - and the do-nothing check did not flag the folder's tests as weak.
def known_answer(r):
    if r['do_nothing'] == 'weak':
        return ''
    src = [n for n, ok in (('kat', bool(r['kat'])), ('own tests', bool(r['own_tests'])),
                           ('diff agree', r['diff_test'].startswith('agree'))) if ok]
    return ', '.join(src)
# training_ready: builds + tests pass on GNAT 12 and 14, the folder's own `make test` passes on GNAT 14 and 12,
# Silver-proven non-trivially, not a stub, a known answer, and no open finding (tools/vv/findings.csv).
def training_ready(r):
    return (r['build_gnat14'] == 'yes' and r['build_gnat12'] == 'yes'
            and r['tests_pass_gnat14'] == 'yes' and r['tests_pass_gnat12'] == 'yes'
            and r['make_test'] == 'yes' and r['make_test_gnat12'] == 'yes'
            and not r['open_findings']
            and r['silver'] == 'proven' and not r['trivial'] and not r['stub']
            and bool(r['known_answer']))
# Stricter rule (Robert, 2026-10-08 18:55), on top of the above:
#  (1) mutation: the folder's tests kill >= 90% of the planted mutants (vv/results/mutation*.csv; survivors are
#      counted as non-equivalent until reviewed; 'no sites' passes, no run fails);
#  (2) ref_independent: the known answer comes from a different method (registered vector or own tests:
#      brute force / independent property); twin agreement alone (twin_only) does not count;
#  (3) zero warnings with -gnatwa on GNAT 14 and 12, and no suppression (warnings_suppressed);
#  (4) no proof escape (pragma Assume / Annotate) without a written reason (else not Silver non-trivial).
def mutation_ok(r):
    if r['mutation_score'] == 'no sites': return True
    m = re.match(r'^(\d+)/(\d+)$', r['mutation'])
    if not m or int(m.group(2)) == 0: return False
    den = int(m.group(2)) - equiv_by[r['folder']]   # listed equivalents (with evidence) leave the denominator
    return den <= 0 or 10 * int(m.group(1)) >= 9 * den
def drop_reasons(r):
    out = []
    if not mutation_ok(r): out.append('mutation < 90%' if r['mutation_score'] not in ('',) else 'mutation not run')
    if r['ref_independent'] != 'yes': out.append('twin only' if r['twin_only'] else 'old_unverified answers only')
    if r['warnings_gnat14'] != '0' or r['warnings_gnat12'] != '0': out.append('warnings')
    if r['warnings_suppressed']: out.append('warnings suppressed')
    if esc_bare[r['folder']]: out.append('unjustified proof escape')
    if r['masked_by_finish']: out.append('masked by Bubble_Finish')
    return out
# known_answer_source (room rule 2026-10-08 19:25): where the expected values come from.
#   own          own tests (tools/vv/own_tests.csv, the sweep's tests): brute force or independent properties
#   standard     a registered standard vector (tools/vv/kat_registry.csv)
#   old_derived  the folder's old hard-coded answers were derived independently (tools/vv/old_derived.csv)
#   old_unverified  only the old tests' hard-coded answers, possibly copied from program output
# old_unverified does not satisfy the known-answer requirement.
old_derived = {x['folder']: x['derivation'] for x in _csv(os.path.join(a.root, 'tools', 'vv', 'old_derived.csv'))}
def known_answer_source(r):
    if r['own_tests']: return 'own'
    if r['kat']: return 'standard'
    if r['folder'] in old_derived: return 'old_derived'
    return 'old_unverified' if r['tests_pass_gnat14'] == 'yes' or r['make_test'] == 'yes' else ''
for r in rows:
    r['known_answer'] = known_answer(r)
    r['known_answer_source'] = known_answer_source(r)
    r['ref_independent'] = 'yes' if r['known_answer_source'] in ('own', 'standard', 'old_derived') and r['do_nothing'] != 'weak' else ('no' if r['known_answer'] else '')
    r['twin_only'] = 'yes' if r['known_answer'] == 'diff agree' else ''
    r['training_ready_old'] = 'yes' if training_ready(r) else ''
    r['tr_drop'] = '; '.join(drop_reasons(r)) if r['training_ready_old'] else ''
    r['training_ready'] = 'yes' if r['training_ready_old'] and not r['tr_drop'] else ''

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
# near-copies (tools/vv/copy_of.csv): informational pointer to a canonical folder, no effect on counts
COPY_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'vv', 'copy_of.csv')
copy_of = {}
if os.path.exists(COPY_FILE):
    for l in open(COPY_FILE):
        if l.strip() and not l.startswith('#') and not l.startswith('folder,'):
            a, b = l.strip().split(',')[:2]; copy_of[a] = b
for r in rows: r['copy_of'] = copy_of.get(r['folder'], '')

# implementation candidates (Robert, 2026-10-08): every stub = yes folder gets implement_next = yes and is
# listed in docs/IMPLEMENT.md with the signal that marked it and the core step a full version needs
# (tools/implement_notes.txt). No timestamp, so the file is idempotent.
for r in rows: r['implement_next'] = 'yes' if r['stub'] else ''
_TOOLS = os.path.dirname(os.path.abspath(__file__))
_notes = {l.split('\t')[0]: l.split('\t')[1].strip() for l in open(os.path.join(_TOOLS, 'implement_notes.txt'))
          if l.strip() and not l.startswith('#')} if os.path.exists(os.path.join(_TOOLS, 'implement_notes.txt')) else {}
_readme_words = {l.split('\t')[0].strip(): (l.split('\t')[1].strip() if '\t' in l else '')
                 for l in open(README_STUB_FILE) if l.strip() and not l.startswith('#')} if os.path.exists(README_STUB_FILE) else {}
_hidden = {}
_hp = os.path.join(_TOOLS, 'vv', 'hidden_stub.csv')
if os.path.exists(_hp):
    for h in csv.DictReader(open(_hp)):
        if h.get('stub_marked') == 'yes': _hidden[h['folder']] = h['verdict']
def _signal(r):
    if r['folder'] in _hidden: return 'hidden-stub scan: ' + _hidden[r['folder']]
    if r['folder'] in _readme_words: return 'README wording: "' + _readme_words[r['folder']].replace('|', '/')[:160] + '"'
    return '-Stub name'
_cand = sorted((r for r in rows if r['implement_next']), key=lambda r: r['folder'])
_L = ['# Implementation candidates', '',
      'Written by `make proof-index` (tools/proof_index.py); do not edit by hand. Every folder with `stub` = yes in PROOFS.csv '
      'carries `implement_next` = yes: it is a candidate for a full implementation of the named algorithm, which comes before '
      'the SPARK Silver (level 2) work on it. Signals: the folder name ends in `-Stub` (and it is not listed in '
      '`tools/generalised_stubs.txt`), its README calls it a stub (`tools/readme_stubs.txt`), or the hidden-stub scan found that '
      'the code lacks the core step (`tools/vv/hidden_stub.csv`). The core-step notes are in `tools/implement_notes.txt`.', '',
      f'**{len(_cand)} candidate folders** ({sum(1 for r in _cand if not r['duplicate_of'])} with duplicates counted once, the README count).', '']
for cat in sorted({r['folder'].split('/')[0] for r in _cand}):
    grp = [r for r in _cand if r['folder'].split('/')[0] == cat]
    _L += [f'## {cat} ({len(grp)})', '', '| Folder | Signal | Full algorithm needs (core step) |', '|---|---|---|']
    for r in grp:
        k = re.sub(r'-(Stub|Lite)$', '', re.sub(r'^Ada-SPARK-', '', r['algorithm']))
        _L.append(f"| {r['folder']} | {_signal(r)} | {_notes.get(k, 'see README')} |")
    _L.append('')
_ip = os.path.join(a.root, 'docs', 'IMPLEMENT.md')
_new = '\n'.join(_L)
if not os.path.exists(_ip) or open(_ip).read() != _new:
    open(_ip, 'w').write(_new); print('docs/IMPLEMENT.md updated')

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
real = [r for r in uniq if not r['stub'] and r['silver'] not in ('no SPARK',)]
headline = (f"{c(lambda r: r['silver']=='proven' and not r['stub'] and not r['trivial'])} real SPARK folders proven non-trivially, "
            f"{c(lambda r: r['silver']=='proven' and not r['stub'] and r['trivial']=='yes')} proven but trivial (<= {TRIVIAL_MAX} checks), "
            f"{c(lambda r: r['silver']=='proven' and bool(r['stub']))} stubs proven (separate), "
            f"{c(lambda r: r['silver'].endswith('unproved'))} with unproved checks, {c(lambda r: r['silver'] in ('tool crash','timeout'))} gnatprove tool crash/timeout, "
            f"{c(lambda r: r['silver']=='not built')} not built for gnatprove, {c(lambda r: r['silver']=='not run')} not run; "
            f"{c(lambda r: r['silver']=='proven' and not r['stub'] and (r['functional_checks'] or 0) > 0)} proven real folders also prove functional contracts")
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
     f'Folders: {len(rows)}; duplicates (counted once): {len(rows) - len(uniq)}; Ada<->SPARK pairs: {npairs}; stub sheets (name ends in -Stub or README says stub, column `stub`): {sum(1 for r in rows if r["stub"])}.', '',
     f"**Training-ready: {c(lambda r: r['training_ready']=='yes')} folders** (duplicates counted once) - builds and tests pass on GNAT 12 and 14, the folder's own `make test` passes on GNAT 14 and on GNAT 12 (columns `make_test`, `make_test_gnat12`), no open finding in `tools/vv/findings.csv` (column `open_findings`), Silver-proven non-trivially, not a stub, and a known answer (column `known_answer`): a registered known-answer vector, own tests (self-written properties or brute-force reference, `tests/SOURCES.txt`), or an agreeing differential test against its twin - and in every case the do-nothing check must not flag the tests as weak. Stricter rule since 2026-10-08 (column `training_ready`; the old verdict is kept in `training_ready_old`, the reasons for a drop in `tr_drop`): (1) the folder's tests kill at least 90% of the planted mutants (column `mutation_score`; `tools/vv/mutate.py`, 20 seeded mutants per folder; surviving mutants count as non-equivalent until reviewed); (2) the known answer comes from a different method than the code under test - a registered vector or own tests (brute force or an independent property); agreement with the twin alone does not count (columns `ref_independent`, `twin_only`); (3) zero warnings with `-gnatwa` on GNAT 14 and on GNAT 12, fixed in code: a folder with `pragma Warnings (Off ...)` or `-gnatws`/`-gnatwA` is not training-ready (column `warnings_suppressed`, list in `tools/vv/warnings_suppressed.csv`); (4) every `pragma Assume` / `pragma Annotate (GNATprove, ...)` carries a written reason (column `proof_escapes`, list in `tools/vv/proof_escapes.csv`); an unexplained one voids the Silver claim. The column `known_answer_source` says where the expected values come from (own / standard / old_derived / old_unverified); hard-coded answers in old tests count only when they were derived independently (`tools/vv/old_derived.csv`), never when they may have been copied from program output (old_unverified). A sort whose proof rests on a final Bubble_Finish pass that masks the named algorithm (`tools/vv/sweep_masking.csv`, column `masked_by_finish`) is not training-ready either; a surviving mutant counts as equivalent only when `tools/vv/sweep_equivalent.csv` lists it with exhaustive evidence or a written reason. Under the old rule: {c(lambda r: r['training_ready_old']=='yes')} folders.", '',
     f"**Do-nothing check:** {c(lambda r: r['do_nothing'] in ('ok', 'weak') or r['do_nothing'].startswith('unchecked'))} folders checked, {c(lambda r: r['do_nothing']=='weak')} flagged weak (tests still pass when the main subprogram does nothing), {c(lambda r: r['do_nothing'].startswith('unchecked'))} unchecked (no trivial body compiles); {c(lambda r: r['do_nothing']=='weak' and r['silver']=='proven' and not r['trivial'] and not r['stub'])} of the weak ones are Silver-proven non-trivial. Own tests: {c(lambda r: r['own_tests']=='yes')} folders (column `own_tests`).", '',
     '**Silver headline (duplicates counted once):** ' + headline, '',
     '`stub` column: every folder whose name ends in `-Stub` (toy fixed-size versions) is flagged, and so is every folder listed in `tools/readme_stubs.txt` (its README calls it a stub); the 3 near-duplicate stubs also carry `duplicate_of`. Stubs are counted separately and never in the "real" numbers. Folders listed in `tools/generalised_stubs.txt` keep their `-Stub` name but were rewritten for arbitrary-length input; they carry `generalised` = yes instead of `stub` and count as real. `trivial` = proven with at most ' + str(TRIVIAL_MAX) + ' checks in total (gnatprove.out); `functional_checks` = number of functional-contract (post/contract-case) checks proved.', '',
     '| Level | Folders | make test OK | Build 14 | Build 12 | Tests 14 | Tests 12 | 0 warn 14 | 0 warn 12 | Proven (real) | Proven (stub) | Trivial | Unproved | Tool crash | Not built | Not run |',
     '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
for lev in ('Ada', 'SPARK1', 'SPARK2', 'SPARK3', 'SPARK4', 'All'):
    s = [r for r in uniq if lev == 'All' or r['level'] == lev]
    if not s: continue
    L.append(f"| {lev} | {len(s)} | {c(lambda r: r['make_test']=='yes', s)} | {c(lambda r: r['build_gnat14']=='yes', s)} | {c(lambda r: r['build_gnat12']=='yes', s)} | "
             f"{c(lambda r: r['tests_pass_gnat14']=='yes', s)} | {c(lambda r: r['tests_pass_gnat12']=='yes', s)} | "
             f"{c(lambda r: str(r['warnings_gnat14'])=='0' and r['build_gnat14']=='yes', s)} | {c(lambda r: str(r['warnings_gnat12'])=='0' and r['build_gnat12']=='yes', s)} | "
             f"{c(lambda r: r['silver']=='proven' and not r['stub'], s)} | {c(lambda r: r['silver']=='proven' and bool(r['stub']), s)} | {c(lambda r: r['trivial']=='yes', s)} | "
             f"{c(lambda r: r['silver'].endswith('unproved'), s)} | {c(lambda r: r['silver'] in ('tool crash','timeout'), s)} | {c(lambda r: r['silver']=='not built', s)} | {c(lambda r: r['silver']=='not run', s)} |")
vvrows = [r for r in rows if r['diff_test'] or r['mutation'] or r['kat'] or r['own_tests'] or r['do_nothing'] == 'weak']
if vvrows:
    nd = len({d['pair'] for d in _csv(os.path.join(VVD, 'diff.csv'))})
    mparts = []
    for mf in sorted(glob.glob(os.path.join(VVD, 'mutation*.csv'))):
        if mf.endswith('_detail.csv'): continue
        ms = _csv(mf); kk = sum(int(m['killed']) for m in ms); ss = sum(int(m['survived']) for m in ms)
        mparts.append(f"`{os.path.basename(mf)}` {kk} killed / {ss} survived" + (f" ({100*kk//max(1,kk+ss)}%)" if kk + ss else ''))
    dres = _csv(os.path.join(VVD, 'diff.csv'))
    nagree = sum(1 for d in dres if d['result'] == 'agree')
    L += ['', '## V&V (validation) results', '',
          f'Plan and harness: `docs/VV.md`, `make vv`. Differential pairs run: {nd} ({nagree} agree on every case); mutation: '
          + ('; '.join(mparts) or 'not run') + f' (a folder in several files shows the last one: all-sites beats pilot beats sample); folders with registered known-answer vectors: {len(kat_by)}. '
          f'Own tests: {len(own_by)} folders (`tools/vv/own_tests.csv`); do-nothing check: `vv/results/donothing.csv` (rows below: every folder with a V&V result or flagged weak). '
          'Columns `diff_test`, `mutation`, `kat`, `own_tests`, `do_nothing`, `known_answer` in PROOFS.csv.', '',
          '| Folder | Differential test | Mutation (killed/total) | Known-answer source | Own tests | Do-nothing | Known answer |', '|---|---|---|---|---|---|---|']
    for r in vvrows:
        L.append(f"| {r['folder']} | {r['diff_test']} | {r['mutation']} | {r['kat']} | {own_by.get(r['folder'], '')} | {r['do_nothing']} | {r['known_answer']} |")
L += ['', '| Folder | Make | B14 | B12 | T14 | T12 | W14 | W12 | Silver | Checks (func) | Training-ready | Pair | Duplicate of |', '|---|---|---|---|---|---|---|---|---|---|---|---|---|']
for r in rows:
    L.append(f"| {r['folder']}{' (stub)' if r['stub'] else ''} | {r['make_test']} | {r['build_gnat14']} | {r['build_gnat12']} | {r['tests_pass_gnat14']} | {r['tests_pass_gnat12']} | "
             f"{r['warnings_gnat14']} | {r['warnings_gnat12']} | {r['silver']}{' (trivial)' if r['trivial'] else ''} | {r['checks']}{' (%s)' % r['functional_checks'] if r['functional_checks'] else ''} | {r['training_ready']} | {r['pair']} | {r['duplicate_of']} |")
open(os.path.join(R, 'PROOFS.md'), 'w').write('\n'.join(L) + '\n')
print(f'{len(rows)} folders, {len(rows)-len(uniq)} duplicates, {npairs} pairs')

# Headline numbers for the root README.md, written only here, between the proof-index markers.
# No timestamp, so rerunning on the same results leaves README.md byte-identical (idempotent).
BEGIN, END = '<!-- proof-index:begin -->', '<!-- proof-index:end -->'
n_open = sum(1 for f in _csv(os.path.join(a.root, 'tools', 'vv', 'findings.csv')) if f['status'] == 'open')
block = '\n'.join([
    BEGIN,
    '| Headline (written by `make proof-index`) | Folders |',
    '|---|---:|',
    f'| Algorithm folders (duplicates counted once) | {len(uniq)} |',
    f"| Silver-proven, non-trivial (not stubs, more than {TRIVIAL_MAX} checks) | {c(lambda r: r['silver']=='proven' and not r['stub'] and not r['trivial'])} |",
    f"| Training-ready (stricter rule: mutants >= 90% killed, independent reference, 0 warnings without suppression, no unexplained proof escape; PROOFS.md) | {c(lambda r: r['training_ready']=='yes')} |",
    f"| Training-ready under the previous rule | {c(lambda r: r['training_ready_old']=='yes')} |",
    f'| Open findings (`tools/vv/findings.csv`) | {n_open} |',
    f"| Implementation candidates (stubs, column `implement_next`; docs/IMPLEMENT.md) | {c(lambda r: r['implement_next']=='yes')} |",
    END])
readme = os.path.join(R, 'README.md')
if os.path.exists(readme):
    text = open(readme).read()
    if BEGIN in text and END in text and text.index(BEGIN) < text.index(END):
        new = text[:text.index(BEGIN)] + block + text[text.index(END) + len(END):]
        if new != text:
            open(readme, 'w').write(new)
            print('README.md: proof-index block updated')
        else:
            print('README.md: proof-index block unchanged')
    else:
        print('README.md: no proof-index markers; block not written')
