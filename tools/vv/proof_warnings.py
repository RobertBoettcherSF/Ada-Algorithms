#!/usr/bin/env python3
"""Proof-warnings sweep (prove_settings.txt: proof_warnings=on, proof_warnings_timeout).

For every SPARK folder (*/SPARK*/<folder>/): cold copy (obj/ bin/ gnatprove/ proof/ deleted),
  gnatprove -P <gpr> -f --mode=silver --level=0 -k -j2 --output=oneline
with the project's own Proof_Switches (which carry --proof-warnings=on and the timeout), using the
pinned ~/.local/alr/gnatprove_16.1.0_* toolchain. gpr = PROOFS.csv proof_gpr, else proof.gpr, else
the first *.gpr. Every 'warning:' line gnatprove prints is recorded in tools/vv/proof_warnings.csv.

Findings are sticky: rows are keyed by (folder, file, warning text, stripped source line); a row
stays open until someone fixes it in code and sets status=fixed with fix_commit - a later run that
does not raise it again only updates last_seen, it never closes a row.
usage: proof_warnings.py run [-P 3] [--work /tmp/pw_sweep] [--only FILE]
       proof_warnings.py collect [--work /tmp/pw_sweep] [--run-id ID]"""
import argparse, csv, glob, os, re, shutil, subprocess, time
from concurrent.futures import ThreadPoolExecutor
ROOT = subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip()
OUT = os.path.join(ROOT, 'tools/vv/proof_warnings.csv')
ap = argparse.ArgumentParser(); ap.add_argument('cmd', choices=['run', 'collect'])
ap.add_argument('-P', type=int, default=3); ap.add_argument('--work', default='/tmp/pw_sweep')
ap.add_argument('--only'); ap.add_argument('--run-id', default='pw-' + time.strftime('%Y%m%d'))
ap.add_argument('--cap', type=int, default=1800); a = ap.parse_args()
HOME = os.path.expanduser('~')
PATH = ':'.join([glob.glob(HOME + '/.local/alr/gnatprove_16.1.0_*/bin')[0],
                 glob.glob(HOME + '/.local/alr/gprbuild_*/bin')[0], '/usr/bin', '/bin'])
pg = {r['folder']: r['proof_gpr'] for r in csv.DictReader(open(os.path.join(ROOT, 'PROOFS.csv'), newline=''))}
folders = sorted(d.rstrip('/') for d in glob.glob('*/SPARK[0-9]/*/', root_dir=ROOT))
if a.only:
    keep = {l.strip() for l in open(a.only) if l.strip()}; folders = [f for f in folders if f in keep]
def wdir(f): return os.path.join(a.work, f.replace('/', '_'))
def gpr_of(f):
    src = os.path.join(ROOT, f); g = pg.get(f, '')
    if g and os.path.exists(os.path.join(src, g)): return g
    if os.path.exists(os.path.join(src, 'proof.gpr')): return 'proof.gpr'
    gs = sorted(x for x in os.listdir(src) if x.endswith('.gpr')); return gs[0] if gs else ''
def one(f):
    w = wdir(f)
    if os.path.exists(os.path.join(w, 'result.txt')): return
    shutil.rmtree(w, ignore_errors=True); shutil.copytree(os.path.join(ROOT, f), w)
    for dp, dn, _ in os.walk(w, topdown=False):
        for d in dn:
            if d in ('obj', 'bin', 'gnatprove', 'proof'): shutil.rmtree(os.path.join(dp, d), ignore_errors=True)
    g = gpr_of(f); s = time.time()
    if not g: rc = 'no gpr'
    else:
        try:
            p = subprocess.run(['gnatprove', '-P', g, '-f', '--mode=silver', '--level=0', '-k', '-j2', '--output=oneline'],
                               cwd=w, env=dict(os.environ, PATH=PATH), capture_output=True, text=True,
                               errors='replace', timeout=a.cap)
            rc = p.returncode; open(os.path.join(w, 'pw.log'), 'w').write(p.stdout + p.stderr)
        except subprocess.TimeoutExpired:
            rc = 'cap'
    open(os.path.join(w, 'result.txt'), 'w').write('rc=%s secs=%d gpr=%s\n' % (rc, time.time() - s, g))
    print(f, rc, flush=True)
if a.cmd == 'run':
    os.makedirs(a.work, exist_ok=True)
    with ThreadPoolExecutor(a.P) as ex: list(ex.map(one, folders))
W = re.compile(r'^(\S+?\.ad[sb]):(\d+):(\d+): warning: (.*)$')
cols = ['folder', 'file', 'line', 'col', 'warning', 'source_line', 'status', 'first_seen', 'last_seen', 'fix_commit', 'note']
old = list(csv.DictReader(open(OUT, newline=''))) if os.path.exists(OUT) else []
key = lambda r: (r['folder'], r['file'], r['warning'], r['source_line'])
idx = {key(r): r for r in old}
runs = {}
for f in folders:
    w = wdir(f); res = os.path.join(w, 'result.txt')
    if not os.path.exists(res): continue
    runs[f] = open(res).read().strip()
    log = os.path.join(w, 'pw.log')
    if not os.path.exists(log): continue
    for l in open(log, errors='replace'):
        m = W.match(l.strip())
        if not m: continue
        fn, ln, cn, msg = m.groups(); fn = os.path.basename(fn)
        try: src = open(os.path.join(ROOT, f, fn), errors='replace').read().split('\n')[int(ln) - 1].strip()
        except Exception: src = ''
        r = dict(folder=f, file=fn, line=ln, col=cn, warning=msg, source_line=src[:160], status='open',
                 first_seen=a.run_id, last_seen=a.run_id, fix_commit='', note='')
        k = key(r)
        if k in idx: idx[k].update(line=ln, col=cn, last_seen=a.run_id)
        else: idx[k] = r; old.append(r)
with open(OUT, 'w', newline='') as fh:
    wr = csv.DictWriter(fh, cols, lineterminator='\n'); wr.writeheader(); wr.writerows(old)
with open(os.path.join(ROOT, 'tools/vv/proof_warnings_runs.csv'), 'w', newline='') as fh:
    wr = csv.writer(fh, lineterminator='\n'); wr.writerow(['folder', 'run_id', 'result'])
    for f in folders:
        if f in runs: wr.writerow([f, a.run_id, runs[f]])
print('folders run', len(runs), 'warning rows', len(old), 'open', sum(r['status'] == 'open' for r in old),
      'folders with open', len({r['folder'] for r in old if r['status'] == 'open'}))
