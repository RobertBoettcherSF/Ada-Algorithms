#!/usr/bin/env python3
"""Independent recount of the strict training-ready rule (docs/VV.md, "Strict training-ready rule as enforced").

Written separately from tools/proof_index.py (no shared code, no import) as a cross-check: it reads the raw
inputs - the build/prove results (build.jsonl, prove.jsonl[, prove_steps.jsonl] and gnatprove logs, the same
--results/--logs that proof_index.py takes) and the tools/vv record CSVs - never PROOFS.csv, and prints the
folders that meet every condition.
  python3 tools/vv/recount_strict.py --results DIR --logs DIR [--steps-logs DIR] [--list | --why FOLDER]
"""
import argparse, csv, glob, json, os, re, sys
from collections import defaultdict

ap = argparse.ArgumentParser()
ap.add_argument('--root', default='.')
ap.add_argument('--results', required=True)
ap.add_argument('--logs', required=True)
ap.add_argument('--steps-logs', default='')
ap.add_argument('--list', action='store_true', help='print one passing folder per line')
ap.add_argument('--why', default='', help='print the failed conditions of one folder')
A = ap.parse_args()
ROOT = A.root
VV = os.path.join(ROOT, 'tools', 'vv')

def rows(path):
    if not os.path.exists(path): return []
    with open(path, newline='') as f: return list(csv.DictReader(f))

def jsonl(path):
    out = {}
    if os.path.exists(path):
        for line in open(path):
            try: j = json.loads(line)
            except ValueError: continue
            out[j['id']] = j
    return out

def lines(path):
    return [l.rstrip('\n') for l in open(path)] if os.path.exists(path) else []

# --- the folders: <topic>/<level>/<algorithm> ---
LEVELS = {'Ada', 'SPARK1', 'SPARK2', 'SPARK3', 'SPARK4'}
NOT_ALG = {'bin', 'obj', 'src', 'tests', 'gnatprove'}
folders = []
for topic in sorted(os.listdir(ROOT)):
    tdir = os.path.join(ROOT, topic)
    if topic.startswith('.') or topic in NOT_ALG or topic == 'tools' or not os.path.isdir(tdir): continue
    for lev in sorted(os.listdir(tdir)):
        if lev in LEVELS and os.path.isdir(os.path.join(tdir, lev)):
            for alg in sorted(os.listdir(os.path.join(tdir, lev))):
                if alg not in NOT_ALG and os.path.isdir(os.path.join(tdir, lev, alg)):
                    folders.append(f'{topic}/{lev}/{alg}')

build = jsonl(os.path.join(A.results, 'build.jsonl'))
prove = jsonl(os.path.join(A.results, 'prove.jsonl'))
prove_steps = jsonl(os.path.join(A.results, 'prove_steps.jsonl'))

def zero(v): return str(v) == '0'

def spark_mode_on(fid):
    pat = re.compile(r'SPARK_Mode(\s*=>\s*On\b|\s*;|\s*\(\s*On\s*\))', re.I)
    for dp, dn, fn in os.walk(os.path.join(ROOT, fid)):
        dn[:] = [d for d in dn if d not in ('obj', 'bin', 'gnatprove')]
        for f in fn:
            if f.endswith(('.ads', '.adb')) and not f.startswith('test'):
                if pat.search(open(os.path.join(dp, f), errors='replace').read()): return True
    return False

def silver_checks(fid):
    """Number of proved checks when the Silver run is clean, else None."""
    if fid in prove_steps: j, logdir = prove_steps[fid], A.steps_logs
    else: j, logdir = prove.get(fid), A.logs
    if not j or j.get('rc') != 0 or j.get('status') == 'no_sources' or not logdir: return None
    d = os.path.join(logdir, fid.replace('/', '_'))
    log = open(os.path.join(d, 'prove.log'), errors='replace').read() if os.path.exists(os.path.join(d, 'prove.log')) else ''
    if 'GNAT BUG DETECTED' in log or ': error:' in log: return None
    if any(re.match(r'^[\w\-.]+\.ad[sb]:\d+:\d+: (high|medium|low): ', l) for l in log.splitlines()): return None
    for dp, dn, fn in os.walk(d):
        if 'gnatprove.out' in fn:
            m = re.search(r'^Total\s+(\d+)', open(os.path.join(dp, 'gnatprove.out'), errors='replace').read(), re.M)
            return int(m.group(1)) if m else 0
    return None

# --- record CSVs ---
def folder_set(path, pred=lambda x: True):
    return {x['folder'] for x in rows(path) if x.get('folder') and pred(x)}
yes = lambda col: (lambda x: (x.get(col) or '').strip().lower() == 'yes')
open_findings = set()
for name in ('findings.csv', 'findings_sweep.csv', 'findings_flagship.csv'):
    open_findings |= folder_set(os.path.join(VV, name), lambda x: (x.get('status') or '').strip() == 'open')
suppressed = folder_set(os.path.join(VV, 'warnings_suppressed.csv'))
bare_escape = folder_set(os.path.join(VV, 'proof_escapes.csv'), lambda x: (x.get('justified') or '').strip() != 'yes')
silent = folder_set(os.path.join(VV, 'silent_fail.csv'), yes('silent_fail'))
fc_plant = {x['folder']: (x.get('plant_ok') or '').strip() for x in rows(os.path.join(VV, 'silent_fail_plant.csv'))}
ans_plant = {x['folder']: (x.get('answer_plant_ok') or '').strip() for x in rows(os.path.join(VV, 'silent_fail_answer_plant.csv'))}
withdrawn = folder_set(os.path.join(VV, 'checker_scan.csv'), yes('withdraw_functional')) | \
            folder_set(os.path.join(VV, 'contract_scan.csv'), yes('withdraw_functional'))
partial = folder_set(os.path.join(VV, 'contract_scan.csv'),
                     lambda x: (x.get('verdict') or '').strip().lower().startswith('partial') and (x.get('status') or '').strip().lower() not in ('fixed', 'closed'))
demo = folder_set(os.path.join(VV, 'flagship_status.csv'), yes('demo'))
# open handover row about a gap in the folder (categories functional_gap / dead_code / clamp)
handover_gap = set()
for x in rows(os.path.join(VV, 'handover.csv')):
    if (x.get('category') or '').strip() in ('functional_gap', 'dead_code', 'clamp') and (x.get('status') or '').strip().lower().startswith('open'):
        handover_gap |= {f.strip() for f in (x.get('folder') or '').split(';') if '/' in f and not f.strip().startswith('(')}
generalised = {l.strip() for l in lines(os.path.join(ROOT, 'tools', 'generalised_stubs.txt')) if l.strip() and not l.startswith('#')}
stubs = {l.split('\t')[0].strip() for l in lines(os.path.join(ROOT, 'tools', 'readme_stubs.txt')) if l.strip() and not l.startswith('#')}
stubs |= folder_set(os.path.join(VV, 'hidden_stub.csv'), lambda x: (x.get('stub_marked') or '').strip() == 'yes')
stubs |= folder_set(os.path.join(VV, 'flagship_status.csv'), yes('stub_candidate'))
masked = set()
for x in rows(os.path.join(VV, 'sweep_masking.csv')):
    if (x.get('note') or '').strip().upper().startswith('FIXED'): continue
    if (x.get('masked_by_finish') or x.get('masked') or 'yes').strip().lower() in ('yes', 'y', 'true', '1'): masked.add(x['folder'])
live_fallback = set()
for x in rows(os.path.join(VV, 'sweep_fallback.csv')):
    path = os.path.join(ROOT, x.get('folder', ''), x.get('file', ''))
    call = x.get('call') or ''
    if call and os.path.isfile(path) and re.search(r'\b' + re.escape(call) + r'\s*\(', open(path, errors='replace').read()) \
            and not re.search(r'removed|fixed', x.get('verdict') or '', re.I):
        live_fallback.add(x['folder'])
flaky = defaultdict(set)
for x in rows(os.path.join(VV, 'flaky.csv')):
    flaky[x['folder']].add((x.get('flaky') or '').strip())
index_status = defaultdict(set)
for x in rows(os.path.join(VV, 'index_shift.csv')):
    nothing_to_shift = x.get('status') == 'skipped' and (x.get('detail') == 'no unconstrained array type'
                                                          or 'but no public subprogram taking them' in (x.get('detail') or ''))
    index_status[x['folder']].add('ok' if (x.get('status') == 'ok' or x.get('kind') == 'ok') else 'n/a' if nothing_to_shift else x.get('status'))
weak = folder_set(os.path.join(ROOT, 'vv', 'results', 'donothing.csv'), lambda x: x.get('verdict') == 'weak')
own = folder_set(os.path.join(VV, 'own_tests.csv')) | folder_set(os.path.join(VV, 'sweep_progress.csv'), lambda x: bool(x.get('tests_added')))
kat = folder_set(os.path.join(VV, 'kat_registry.csv'))
derived = folder_set(os.path.join(VV, 'old_derived.csv'))

# --- held-out records: one per source family, later rows replace earlier ones inside a family; all must pass ---
held = defaultdict(dict)   # folder -> family -> (k, n, set of labels)
def record(fam, fid, k, n, note='', small=False):
    labels = set()
    low = (note or '').lower()
    if 'not blind' in low: labels.add('not blind')
    if 'does not meet the strict rule' in low: labels.add('invalid')
    if small or n < 20: labels.add('too small')
    held[fid][fam] = (k, n, labels)
def kn(text):
    m = re.match(r'\s*(\d+)\s*/\s*(\d+)', text or '')
    return (int(m.group(1)), int(m.group(2))) if m else None
for x in rows(os.path.join(ROOT, 'vv', 'results', 'mutation_halves.csv')):
    if x.get('half') == 'heldout':
        record('results', x['folder'], int(x['killed']), int(x['killed']) + int(x['survived']) + int(x['timeout']))
for x in rows(os.path.join(VV, 'flagship_mutation_phase2.csv')):
    v = kn(x.get('nonequivalent_score'))
    if v and (x.get('set') or '').strip() in ('held-out', 'heldout'): record('flagship', x['folder'], *v, note=x.get('note', ''))
for x in rows(os.path.join(VV, 'flagship_mutation_phase3.csv')):
    v = kn(x.get('nonequivalent_killed_over_nonequivalent_plus_timeouts'))
    if v and 'held' in (x.get('set') or ''): record('flagship', x['folder'], *v)
for phase in ('flagship_mutation_phase4.csv', 'flagship_mutation_phase5.csv', 'flagship_mutation_phase6.csv'):
    ph = [x for x in rows(os.path.join(VV, phase)) if x.get('folder') and kn(x.get('score_timeouts_as_survivors'))
          and 'held' in (x.get('set') or '') and 'superseded' not in (x.get('set') or '')]
    for fid in dict.fromkeys(x['folder'] for x in ph):
        mine = [x for x in ph if x['folder'] == fid]
        whole = [x for x in mine if 'split half' not in x['set']]
        if whole:     # a fresh, never-seen set replaces the split halves of the same phase
            x = whole[-1]; record('flagship', fid, *kn(x['score_timeouts_as_survivors']), note=x.get('note', ''))
        else:         # split halves (std + alt) of one phase add up
            ks = [kn(x['score_timeouts_as_survivors']) for x in mine]
            record('flagship', fid, sum(k for k, n in ks), sum(n for k, n in ks), note=' '.join(x.get('note', '') for x in mine))
for fam in ('sweep_heldout_alt.csv', 'sweep_heldout_B.csv'):
    for x in rows(os.path.join(VV, fam)):
        k, n = (x.get('mutation_heldout_k') or '').strip(), (x.get('mutation_heldout_n') or '').strip()
        if k.isdigit() and n.isdigit():
            record(fam, x['folder'], int(k), int(n), note=x.get('notes', ''),
                   small=(x.get('heldout_pct') or '').strip().lower().startswith('too small'))
for path in sorted(glob.glob(os.path.join(VV, '*_halves.csv'))):
    for x in rows(path):
        if x.get('half') == 'heldout' and (x.get('killed') or '').isdigit():
            record('halves', x['folder'], int(x['killed']), int(x['killed']) + int(x['survived']) + int(x['timeout']),
                   note=x.get('note', ''), small=(x.get('enough_20') or '').strip().lower() == 'no')

def failures(fid):
    f = []
    b = build.get(fid, {})
    if not (zero(b.get('u14')) and zero(b.get('u12'))): f.append('build')
    if not (zero(b.get('mk14')) and not b.get('fail_mk14') and zero(b.get('mk12')) and not b.get('fail_mk12')): f.append('make test')
    if not ((zero(b.get('r14')) and not b.get('fail_r14')) or zero(b.get('mk14'))): f.append('tests 14')
    if not ((zero(b.get('r12')) and not b.get('fail_r12')) or zero(b.get('mk12'))): f.append('tests 12')
    if not zero(b.get('wall14', b.get('w14'))) or not zero(b.get('wall12', b.get('w12'))): f.append('warnings')
    if fid in suppressed: f.append('warnings suppressed')
    if not str(b.get('ver14', '')).startswith(('GNATLS 14.', 'GNATMAKE 14.')) or not str(b.get('ver12', '')).startswith(('GNATLS 12.2.', 'GNATMAKE 12.')):
        f.append('compiler version')
    n = silver_checks(fid) if spark_mode_on(fid) else None
    if n is None or n <= 3: f.append('silver non-trivial')
    if fid in bare_escape: f.append('unjustified escape')
    alg = fid.split('/')[-1]
    if (re.search(r'(^|-)stub$', alg, re.I) and fid not in generalised) or fid in stubs: f.append('stub')
    if fid in demo: f.append('demo')
    if fid in open_findings: f.append('open finding')
    if fid in weak or not (fid in own or fid in kat or fid in derived
                           or os.path.exists(os.path.join(ROOT, fid, 'tests', 'SOURCES_sweep.txt'))):
        f.append('independent known answer')
    st = index_status.get(fid)
    if st and ('fail' in st or not ('ok' in st or st == {'n/a'})): f.append('index independence')
    fl = flaky.get(fid, set())
    if 'yes' in fl or 'no' not in fl: f.append('flaky')
    recs = list(held.get(fid, {}).values())
    if not recs or any(lab for k, n, lab in recs) or any(10 * k < 9 * n for k, n, lab in recs): f.append('held-out mutation')
    if fid in masked or fid in live_fallback: f.append('masked/fallback')
    if fid in silent: f.append('silent fail')
    if fc_plant.get(fid) == 'no' or ans_plant.get(fid) == 'no' or (fc_plant.get(fid) == 'n/a' and ans_plant.get(fid) != 'yes'):
        f.append('harness cannot fail')
    if fid in withdrawn or fid in partial: f.append('functional claim withdrawn/partial')
    if fid in handover_gap: f.append('open handover gap')
    return f

if A.why:
    print(A.why, failures(A.why) or 'meets the strict rule'); sys.exit(0)
passing = [fid for fid in folders if not failures(fid)]
if A.list:
    print('\n'.join(passing))
else:
    print(f'# {len(passing)} folders meet the strict rule')
    print('\n'.join(passing))
