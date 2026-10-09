#!/usr/bin/env python3
"""Flakiness scan (docs/VV.md 3j): does a folder's test give the same result every time?

Three passes, each in a scratch copy of the folder, with the compiler pinned by path and
version-checked (GNAT 14 by default; --gnat 12 for the GNAT 12 toolchain):

  repeat  Build once and run the standard test command --runs times (default 10) on the default
          seed. `make test` when the Makefile has a test target; otherwise the test main is built
          with gnatmake -gnat2022 and run. Any change of result (pass/fail/timeout) is flakiness;
          a change of normalised output with the same result is reported as output_varies.
  seeds   Only for folders whose test sources read AA_SEED (tests that use randomness; others get
          n/a): the same build, run once for each AA_SEED=1..--seeds (default 30). Every failing
          seed is listed in failing_seeds.
  init    One extra build of the test main with `pragma Initialize_Scalars` (configuration file
          given with -gnatec) plus -gnatVa (all validity checks) and -gnata, run once, against a
          baseline build with the same switches minus Initialize_Scalars/-gnatVa. init_scalars_ok
          is no when the baseline passes and the Initialize_Scalars build fails; n/a when there is
          no test main or the baseline itself does not build or pass (reason in the note).

A run passes when it exits 0 and prints no FAIL/FAILED line other than zero-failure summaries
and PASS/OK lines; a timeout (whole process group killed) counts as its own result. Output is
compared after removing build-tool lines and lines with wall-clock words (time/elapsed/ms/sec).

Columns: folder, compiler, runs, passes, fails, timeouts, distinct_outputs, repeat_ok,
output_varies, seeds_tried, seeds_failed, failing_seeds, init_scalars_ok, flaky, first_fail_excerpt,
note. flaky = yes when repeat_ok = no, seeds_failed > 0 or init_scalars_ok = no.

usage: flaky.py [--from-file ids.txt] [--passes repeat,seeds,init] [--runs 10] [--seeds 30] [-j 3]
                [--gnat 14|12] [--out tools/vv/flaky.csv]
"""
import argparse, csv, hashlib, os, re, shutil, subprocess, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mutate
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MAINS = ('tests.adb', 'tests/main.adb', 'src/tests.adb')
INIT_ADC = 'pragma Initialize_Scalars;\n'
FAIL = re.compile(r'\bFAIL(ED)?\b', re.I)
ZERO = re.compile(r'FAIL(ED|S|URES?)?\s*[:=]?\s*0\b|\b0\s+(tests?\s+)?FAIL|\bno\s+FAIL', re.I)
PASSLINE = re.compile(r'^\W*(PASS(ED)?|OK)\b', re.I)
CLOCK = re.compile(r'\b(time|elapsed|seconds?|secs?|ms|millisec\w*|duration|clock|speed|throughput|ns)\b', re.I)
BUILD = re.compile(r'^(\S*/)?(\S+-)?(gprbuild|gnatmake|gnatbind|gnatlink|gcc|gnatprove|mkdir|make|rm|Compile|Bind|Link|Phase|Summary logged|\s*\[)', re.I)

def toolchain(v):
    alr = os.environ.get('AA_ALR_DIR', os.path.expanduser('~/.local/alr'))   # docs/TOOLCHAIN.md
    gpr = [os.path.join(alr, d, 'bin') for d in sorted(os.listdir(alr)) if d.startswith('gprbuild')] if os.path.isdir(alr) else []
    if v == '14':
        path = ['/usr/bin', '/bin'] + gpr; gm = '/usr/bin/gnatmake'
    else:
        g12 = [os.path.join(alr, d, 'bin') for d in sorted(os.listdir(alr)) if d.startswith('gnat_native_12')][0]
        path = [g12] + gpr + ['/usr/bin', '/bin']; gm = os.path.join(g12, 'gnatmake')
    e = dict(os.environ); e['PATH'] = ':'.join(path)
    return e, mutate.require_version(int(v), gm)

import silent_fail

def classify(rc, out, fid=None):
    """pass: exit 0 and no failure line by the silent-fail scan's rule (FAIL/FAILED, not zero-failure
    summaries, PASS/OK lines, expected-failure labels, tool lines or reviewed label lines)."""
    if rc is None:
        return 'timeout'
    return 'pass' if rc == 0 and not silent_fail.hits(out, fid) else 'fail'

def norm(out):
    return '\n'.join(l for l in out.splitlines() if not CLOCK.search(l) and not BUILD.match(l))

def has_test_target(mk):
    return bool(re.search(r'^test\s*:', open(mk, errors='replace').read(), re.M))

def uses_seed(work):
    for d, _, fs in os.walk(work):
        for f in fs:
            if f.endswith(('.adb', '.ads')) and 'AA_SEED' in open(os.path.join(d, f), errors='replace').read():
                return True
    return False

def find_main(work):
    for m in MAINS:
        if os.path.exists(os.path.join(work, m)):
            return m
    return next((f for f in sorted(os.listdir(work)) if re.fullmatch(r'test\w*\.adb', f)), None)

def excerpt_of(c, rc, out):
    ls = [l.strip() for l in out.splitlines() if FAIL.search(l) or 'raised' in l or 'rror' in l]
    return (ls[0] if ls else ('timeout' if c == 'timeout' else f'exit {rc}'))[:160]

def run_once(cmd, work, timeout, env, fid=None):
    r = mutate.run_limited(cmd, work, timeout, env=env)
    rc, out = (None, '') if r is None else (r.returncode, r.stdout + r.stderr)
    return classify(rc, out, fid), rc, out

def init_pass(src, work_root, env, timeout, fid=None):
    """Baseline (-gnata) and Initialize_Scalars (-gnata -gnatVa, -gnatec=init.adc) builds of the test main, one run each,
    in a fresh copy (objects left by another build in the source directory would otherwise be reused)."""
    work = tempfile.mkdtemp(prefix='init_', dir=work_root)
    try:
        shutil.copytree(src, work, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns('obj', 'bin', 'gnatprove', '*.o', '*.ali'))
        return _init_pass(work, env, timeout, fid)
    finally:
        shutil.rmtree(work, ignore_errors=True)

def _init_pass(work, env, timeout, fid=None):
    m = find_main(work)
    if not m:
        return 'n/a', 'init: no test main'
    adc = os.path.join(work, 'fl_init.adc'); open(adc, 'w').write(INIT_ADC)
    inc = [f'-I{d}' for d in ('src', 'tests') if os.path.isdir(os.path.join(work, d))]
    res = {}
    for tag, extra in (('base', []), ('init', ['-gnatVa', f'-gnatec={adc}'])):
        od = os.path.join(work, f'fl_o_{tag}'); os.makedirs(od, exist_ok=True)
        b = mutate.run_limited(['gnatmake', '-q', '-f', '-gnat2022', '-gnata'] + extra + inc + ['-D', od, '-o', f'fl_{tag}', m],
                               work, 900, env=env)
        if b is None or b.returncode:
            res[tag] = ('nobuild', (b.stdout + b.stderr)[-300:] if b else 'build timeout')
            continue
        c, rc, out = run_once([f'./fl_{tag}'], work, timeout, env, fid)
        res[tag] = (c, excerpt_of(c, rc, out) if c != 'pass' else '')
    if res['base'][0] != 'pass':
        return 'n/a', f"init: baseline -gnata build {res['base'][0]}: {res['base'][1][:120]}".replace('\n', ' ')
    if res['init'][0] == 'pass':
        return 'yes', ''
    return 'no', f"init: Initialize_Scalars build {res['init'][0]}: {res['init'][1][:120]}".replace('\n', ' ')

def scan(fid, passes, runs, seeds, env, ver, work_root, timeout):
    src = os.path.join(ROOT, fid)
    work = tempfile.mkdtemp(prefix=fid.replace('/', '_') + '_', dir=work_root)
    row = dict(folder=fid, compiler=ver, runs=0, passes=0, fails=0, timeouts=0, distinct_outputs=0, repeat_ok='',
               output_varies='', seeds_tried='', seeds_failed='', failing_seeds='', init_scalars_ok='', flaky='',
               first_fail_excerpt='', note='')
    notes = []
    try:
        shutil.copytree(src, work, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns('obj', 'bin', 'gnatprove', '*.o', '*.ali'))
        cmd = None
        if 'repeat' in passes or 'seeds' in passes:
            mk = os.path.join(work, 'Makefile')
            if os.path.exists(mk) and has_test_target(mk):
                mtxt = open(mk, errors='replace').read()
                mutate.run_limited(['make', 'all'] if re.search(r'^all\s*:', mtxt, re.M) else ['true'], work, 900, env=env)
                cmd = ['make', '-s', 'test']
            else:
                m = find_main(work)
                if not m:
                    notes.append('no test target and no test main')
                else:
                    inc = [f'-I{d}' for d in ('src', 'tests') if os.path.isdir(os.path.join(work, d))]
                    b = mutate.run_limited(['gnatmake', '-q', '-gnat2022'] + inc + ['-o', 'fl_test', m], work, 900, env=env)
                    if b is None or b.returncode:
                        notes.append('test main does not build')
                    else:
                        cmd = ['./fl_test']; notes.append('no make test: gnatmake test main')
        if cmd and 'repeat' in passes:
            #  one run first: a test that hangs is not repeated (it is not flaky, it is slow)
            c, rc, out = run_once(cmd, work, timeout, {k: v for k, v in env.items() if k != 'AA_SEED'}, fid)
            if c == 'timeout':
                row.update(runs=1, passes=0, fails=0, timeouts=1, distinct_outputs=1, repeat_ok='yes', output_varies='no',
                           first_fail_excerpt='timeout')
                notes.append('timed out once, not repeated (slow, not flaky)')
                cmd = None
        if cmd and 'repeat' in passes:
            res, outs = [], []
            renv = dict(env); renv.pop('AA_SEED', None)
            for _ in range(runs):
                c, rc, out = run_once(cmd, work, timeout, renv, fid)
                res.append(c); outs.append(hashlib.sha1(norm(out).encode()).hexdigest())
                if c != 'pass' and not row['first_fail_excerpt']:
                    row['first_fail_excerpt'] = excerpt_of(c, rc, out)
                if res == ['timeout', 'timeout']:       # a test that hangs every time: not repeated further
                    notes.append('timed out twice, not repeated further'); break
            row.update(runs=len(res), passes=res.count('pass'), fails=res.count('fail'), timeouts=res.count('timeout'),
                       distinct_outputs=len(set(outs)), repeat_ok='no' if len(set(res)) > 1 else 'yes',
                       output_varies='yes' if (len(set(res)) == 1 and len(set(outs)) > 1) else 'no')
        if 'seeds' in passes:
            if not uses_seed(work):
                row.update(seeds_tried='n/a', seeds_failed='n/a')
            elif cmd:
                bad = []
                for k in range(1, seeds + 1):
                    senv = dict(env); senv['AA_SEED'] = str(k)
                    c, rc, out = run_once(cmd, work, timeout, senv, fid)
                    if c == 'timeout' and k == 2 and bad == ['1:timeout']:
                        bad.append('2:timeout'); notes.append('seed runs timed out twice, not continued'); break
                    if c != 'pass':
                        bad.append(f'{k}:{c}')
                        if not row['first_fail_excerpt']:
                            row['first_fail_excerpt'] = f'AA_SEED={k}: ' + excerpt_of(c, rc, out)
                row.update(seeds_tried=seeds, seeds_failed=len(bad), failing_seeds=' '.join(bad))
        if 'init' in passes:
            ok, n = init_pass(src, work_root, env, timeout, fid)
            row['init_scalars_ok'] = ok
            if n:
                notes.append(n)
    finally:
        shutil.rmtree(work, ignore_errors=True)
    sf = row['seeds_failed']
    row['flaky'] = 'yes' if (row['repeat_ok'] == 'no' or (isinstance(sf, int) and sf > 0)
                             or row['init_scalars_ok'] == 'no') else 'no'
    row['note'] = '; '.join(notes)
    return row

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--from-file'); ap.add_argument('--runs', type=int, default=10); ap.add_argument('-j', type=int, default=3)
    ap.add_argument('--passes', default='repeat,seeds,init'); ap.add_argument('--seeds', type=int, default=30)
    ap.add_argument('--gnat', choices=('14', '12'), default='14'); ap.add_argument('--timeout', type=int, default=300)
    ap.add_argument('--out', default=os.path.join(ROOT, 'tools/vv/flaky.csv')); ap.add_argument('--work')
    a = ap.parse_args()
    ids = ([l.strip() for l in open(a.from_file) if l.strip()] if a.from_file else
           sorted(r['folder'] for r in csv.DictReader(open(os.path.join(ROOT, 'PROOFS.csv')))))
    env, ver = toolchain(a.gnat)
    wr = a.work or tempfile.mkdtemp(prefix='flaky_'); os.makedirs(wr, exist_ok=True)
    passes = set(a.passes.split(','))
    fields = ['folder', 'compiler', 'runs', 'passes', 'fails', 'timeouts', 'distinct_outputs', 'repeat_ok', 'output_varies',
              'seeds_tried', 'seeds_failed', 'failing_seeds', 'init_scalars_ok', 'flaky', 'first_fail_excerpt', 'note']
    with open(a.out, 'w', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=fields, lineterminator='\n'); w.writeheader()
        with ThreadPoolExecutor(a.j) as ex:
            for row in ex.map(lambda f: scan(f, passes, a.runs, a.seeds, env, ver, wr, a.timeout), ids):
                w.writerow(row); fh.flush()
                if row['flaky'] == 'yes':
                    print('FLAKY', row['folder'], f"repeat {row['passes']}/{row['runs']}", f"seeds_failed {row['seeds_failed']}",
                          f"init {row['init_scalars_ok']}", row['first_fail_excerpt'], flush=True)

if __name__ == '__main__':
    main()
