#!/usr/bin/env python3
"""Cold re-proof of every PROOFS.csv row marked silver=proven with the canonical
settings of tools/vv/prove_settings.txt (tools/vv/reproof.sh per folder).
Writes tools/vv/reproof.csv: one row per folder, holds / stale, failing VCs.
A row is 'holds' only if gnatprove exits 0 within the wall cap and reports no
unproved check (low/medium/high/error line).  usage:
  reproof.py run  [-P 2] [--work /tmp/reproof] [--only FILE]
  reproof.py collect [--work /tmp/reproof] [--retry-work /tmp/reproof_j4]
Wall-cap retry: rows that hit the cap at jobs_per_folder are re-run (same steps,
same provers, same cap) with AA_REPROOF_JOBS=4 into --retry-work; collect then
reports the retry result and keeps the first-pass outcome in the note column.
Snapshot run (what the 2026-10-09 run used):
  git archive <commit> | tar -x -C /tmp/reproof_src
  AA_REPROOF_SRC=/tmp/reproof_src AA_REPROOF_COMMIT=<commit> reproof.py run -P 2"""
import argparse, csv, os, re, subprocess, sys
from concurrent.futures import ThreadPoolExecutor
ROOT = subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip()
SET = os.path.join(ROOT, 'tools/vv/prove_settings.txt')
ap = argparse.ArgumentParser(); ap.add_argument('cmd', choices=['run', 'collect'])
ap.add_argument('-P', type=int, default=2); ap.add_argument('--work', default='/tmp/reproof')
ap.add_argument('--only'); ap.add_argument('--retry-work'); a = ap.parse_args()
settings = dict(l.rstrip('\n').split('=', 1) for l in open(SET) if '=' in l and not l.startswith('#'))
SRC = os.environ.get('AA_REPROOF_SRC', ROOT)   # snapshot: PROOFS.csv and sources of one commit
rows = [r for r in csv.DictReader(open(os.path.join(SRC, 'PROOFS.csv'), newline=''))
        if r['silver'] == 'proven']
if a.only:
    keep = set(l.strip() for l in open(a.only) if l.strip()); rows = [r for r in rows if r['folder'] in keep]
os.makedirs(a.work, exist_ok=True)
def wdir(f, root=None): return os.path.join(root or a.work, f.replace('/', '_'))
def one(r):
    if os.path.exists(os.path.join(wdir(r['folder']), 'result.txt')): return
    subprocess.run([os.path.join(ROOT, 'tools/vv/reproof.sh'), r['folder'], r['proof_gpr'], a.work], cwd=ROOT)
    print(r['folder'], open(os.path.join(wdir(r['folder']), 'result.txt')).read().strip(), flush=True)
if a.cmd == 'run':
    with ThreadPoolExecutor(a.P) as ex: list(ex.map(one, rows))
BAD = re.compile(r'^(\S+?:\d+:\d+): (low|medium|high|error): (.*)$')
STEP = re.compile(r'(\d+) steps?\)')
MAXS = re.compile(r'max steps used for successful proof: (\d+)')
out = []
for r in rows:
    d = wdir(r['folder']); res = os.path.join(d, 'result.txt')
    if not os.path.exists(res):
        out.append({'folder': r['folder'], 'result': 'not run'}); continue
    kv = dict(x.split('=', 1) for x in open(res).read().split())
    note = ''
    if a.retry_work and kv['rc'] == '124':
        d2 = wdir(r['folder'], a.retry_work)
        if os.path.exists(os.path.join(d2, 'result.txt')):
            note = 'first pass -j%s: wall cap hit after %ss; retry -j%s' % (
                kv.get('j', settings['jobs_per_folder']), kv['secs'],
                dict(x.split('=', 1) for x in open(os.path.join(d2, 'result.txt')).read().split()).get('j', '?'))
            d = d2; kv = dict(x.split('=', 1) for x in open(os.path.join(d, 'result.txt')).read().split())
    log = open(os.path.join(d, 'prove.log'), errors='replace').read().splitlines()
    bad = [m.group(1) + ' ' + m.group(2) + ': ' + m.group(3) for m in map(BAD.match, log) if m]
    steps = [int(x) for l in log for x in STEP.findall(l)]
    tot = ''
    go = os.path.join(d, 'obj', 'gnatprove', 'gnatprove.out')
    for dp, _, fs in os.walk(d):
        if 'gnatprove.out' in fs: go = os.path.join(dp, 'gnatprove.out'); break
    if os.path.exists(go):
        txt = open(go, errors='replace').read()
        m = re.search(r'^Total\s+(\d+)', txt, re.M); tot = m.group(1) if m else ''
        steps += [int(x) for x in MAXS.findall(txt)]
    rc = int(kv['rc'])
    if rc == 0 and not bad: verdict = 'holds'
    elif rc == 124: verdict = 'stale (wall cap %ss hit)' % settings['wall_cap_seconds']
    elif bad: verdict = 'stale (%d unproved)' % len(bad)
    else: verdict = 'stale (gnatprove rc=%d: %s)' % (rc, (log[-1] if log else '')[:120])
    out.append({'folder': r['folder'], 'result': verdict, 'rc': rc, 'secs': kv['secs'], 'gpr': kv['gpr'],
                'jobs': kv.get('j', settings['jobs_per_folder']), 'note': note,
                'checks_total': tot, 'max_steps_used': max(steps) if steps else '',
                'failing_vcs': ' | '.join(bad[:20]) + (' | ...' if len(bad) > 20 else ''),
                'run_id': settings['run_id'], 'commit': os.environ.get('AA_REPROOF_COMMIT', ''),
                'toolchain': settings['toolchain']})
cols = ['folder', 'result', 'rc', 'secs', 'jobs', 'gpr', 'checks_total', 'max_steps_used', 'failing_vcs', 'note', 'run_id', 'commit', 'toolchain']
with open(os.path.join(ROOT, 'tools/vv/reproof.csv'), 'w', newline='') as fh:
    w = csv.DictWriter(fh, cols, lineterminator='\n'); w.writeheader(); w.writerows(out)
c = lambda p: sum(1 for o in out if p(o['result']))
print('holds', c(lambda s: s == 'holds'), 'stale', c(lambda s: s.startswith('stale')), 'not run', c(lambda s: s == 'not run'))
