#!/usr/bin/env python3
"""Sampled mutation testing (see docs/VV.md).

For each sampled folder: pick up to K operator sites in the non-test .adb
sources (seeded), apply one mutation at a time in a scratch copy, rebuild
the folder's tests with GNAT 14 (-gnat2022 -gnata) and run them.
  killed      tests fail (nonzero exit status, or a FAIL line not reporting 0 failures) or hang;
              'raised' text alone is not a kill. Only tracked library .adb files are mutated
              (no tests, own checks, demo mains, harness or binder files).
  survived    tests still pass  -> the tests do not pin that operator
  stillborn   mutant does not compile (not counted)
Score = killed / (killed + survived).

usage: mutate.py [--seed S] [--per-folder K] [--sample N | --folders F ...] [--out results.csv]
"""
import argparse, csv, glob, os, random, re, shutil, subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GNATMAKE = os.environ.get('VV_GNATMAKE', 'gnatmake')

# (name, regex, replacement); applied to one match at a time, code part of a line only
OPS = [
    ('+ -> -',        r'(?<=[\w)\s])\+(?=[\s\w(])', '-'),
    ('- -> +',        r'(?<=[\w)]\s)-(?=\s[\w(])', '+'),
    ('< -> <=',       r'(?<![<>/=])<(?![=>])', '<='),
    ('<= -> <',       r'<=', '<'),
    ('> -> >=',       r'(?<![=<>-])>(?![=>])', '>='),
    ('>= -> >',       r'>=', '>'),
    ('= -> /=',       r'(?<![:/<>=])=(?![=>])', '/='),
    ('/= -> =',       r'/=', '='),
    ('and then -> or else', r'\band then\b', 'or else'),
    ('or else -> and then', r'\bor else\b', 'and then'),
    ('* -> +',        r'(?<=[\w)]\s)\*(?=\s[\w(])', '+'),
    ('+ 1 -> + 0',    r'\+ 1\b', '+ 0'),
    ('- 1 -> - 0',    r'- 1\b', '- 0'),
]
SKIP_LINE = re.compile(r'^\s*(pragma|with|use|--)|Loop_Invariant|Loop_Variant|Assert|=>\s*$|\bPre\b|\bPost\b', re.I)

def sites(path):
    out = []
    in_pragma = False   # continuation lines of a multi-line pragma (invariants, asserts) are skipped too
    for ln, line in enumerate(open(path, errors='replace').read().split('\n')):
        code = line.split('--')[0]
        starts = bool(re.match(r'\s*pragma\b', code, re.I))
        skip = in_pragma or starts
        if (in_pragma or starts) and ';' not in code:
            in_pragma = True
        elif ';' in code:
            in_pragma = False
        if skip or SKIP_LINE.search(code) or code.count('"'):
            continue
        for name, rx, rep in OPS:
            for m in re.finditer(rx, code):
                out.append((ln, m.start(), m.end(), name, rep))
    return out

def make_dummy(work):
    """Control (a): replace the test main by one that only withs the library units and checks nothing."""
    main = next((m for m in ('tests.adb', 'tests/main.adb', 'src/tests.adb') if os.path.exists(os.path.join(work, m))), None)
    if not main:
        return
    units = []
    for spec in sorted(glob.glob(os.path.join(work, '**', '*.ads'), recursive=True)):
        b = os.path.basename(spec)
        if b.startswith(('test', 'own_checks', 'b~', 'b__')) or '/obj/' in spec:
            continue
        m = re.search(r'^\s*(?:private\s+)?(?:generic\b[\s\S]*?)?package\s+([\w.]+)\s+(?:is|with)\b', open(spec, errors='replace').read(), re.M | re.I)
        if m and m.group(1).lower() not in units:
            units.append(m.group(1))
    name = os.path.splitext(os.path.basename(main))[0]
    proc = 'Tests' if name == 'tests' else 'Main'
    body = ''.join(f'with {u};\n' for u in units) + f'procedure {proc} is\nbegin\n   null;\nend {proc};\n'
    open(os.path.join(work, main), 'w').write(body)

def run_tests(work):
    main = next((m for m in ('tests.adb', 'tests/main.adb', 'src/tests.adb') if os.path.exists(os.path.join(work, m))), None)
    if not main:
        return 'no tests'
    os.makedirs(os.path.join(work, 'obj'), exist_ok=True)
    inc = [f'-I{d}' for d in ('src', 'tests') if os.path.isdir(os.path.join(work, d))]
    b = subprocess.run([GNATMAKE, '-q', '-gnat2022', '-gnata', *inc, '-D', 'obj', main, '-o', 'tbin'],
                       cwd=work, capture_output=True, text=True)
    if b.returncode != 0:
        return 'stillborn'
    try:
        r = subprocess.run(['./tbin'], cwd=work, capture_output=True, text=True, timeout=30)
    except subprocess.TimeoutExpired:
        return 'timeout'   # reported separately; not a kill for the 90% bar
    out = r.stdout + r.stderr
    # a kill is a test failure: nonzero exit status, or a FAIL line that does not report zero failures.
    # Text such as 'raised' is not a kill (expected-exception tests print it on success).
    fails = [l for l in out.split('\n') if re.search(r'\bFAIL', l)
             and not re.search(r'FAIL(ED|S|URES?)?\s*[:=]?\s*0\b|\b0\s+FAIL|0 failed', l, re.I)]
    if r.returncode != 0 or fails:
        return 'killed'
    return 'survived'

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--seed', type=int, default=20261008)
    ap.add_argument('--per-folder', type=int, default=6)
    ap.add_argument('--sample', type=int, default=8)
    ap.add_argument('--folders', nargs='*')
    ap.add_argument('--out', default=os.path.join(ROOT, 'vv', 'results', 'mutation.csv'))
    ap.add_argument('--work', default='/tmp/vv_mut')
    ap.add_argument('--dummy', action='store_true', help='control (a): always-passing test that checks nothing; must score 0')
    a = ap.parse_args()
    rng = random.Random(a.seed)
    if a.folders:
        folders = a.folders
    else:
        allf = sorted(os.path.relpath(os.path.dirname(t), ROOT) for t in glob.glob(os.path.join(ROOT, '*', '*', '*', 'tests.adb')))
        folders = rng.sample(allf, min(a.sample, len(allf)))
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    rows, detail = [], []
    for fid in folders:
        src = os.path.join(ROOT, fid)
        work0 = os.path.join(a.work, fid.replace('/', '_'))
        shutil.rmtree(work0, ignore_errors=True); shutil.copytree(src, work0 + '/base')
        if a.dummy:
            make_dummy(work0 + '/base')
        base = run_tests(work0 + '/base')
        cand = []
        tracked = subprocess.run(['git', 'ls-files', '--', fid], cwd=ROOT, capture_output=True, text=True).stdout.split()
        for f in sorted(os.path.join(ROOT, t) for t in tracked if t.endswith('.adb')):
            rel = os.path.relpath(f, src)
            b = os.path.basename(f)
            # only library code under test (tracked files): skip test mains, own checks, demo mains, harness and
            # tests/ trees; binder files (b~*/b__*) and obj/bin output are never tracked
            if (b.startswith(('test', 'own_checks', 'b~', 'b__', 'harness')) or b == 'main.adb'
                    or any(part in ('tests', 'test', 'obj', 'bin') for part in rel.split(os.sep)[:-1])):
                continue
            cand += [(os.path.relpath(f, src),) + s for s in sites(f)]
        pick = rng.sample(cand, min(a.per_folder, len(cand))) if base == 'survived' else []
        k = s_ = sb = to = 0
        for i, (rel, ln, c0, c1, name, rep) in enumerate(pick):
            w = f'{work0}/m{i}'
            shutil.copytree(src, w)
            lines = open(os.path.join(w, rel), errors='replace').read().split('\n')
            orig = lines[ln]; lines[ln] = orig[:c0] + rep + orig[c1:]
            open(os.path.join(w, rel), 'w').write('\n'.join(lines))
            if a.dummy:
                make_dummy(w)
            res = run_tests(w)
            k += res == 'killed'; s_ += res == 'survived'; sb += res == 'stillborn'; to += res == 'timeout'
            detail.append(dict(folder=fid, file=rel, line=ln + 1, op=name, before=orig.strip()[:100], after=lines[ln].strip()[:100], result=res))
            shutil.rmtree(w, ignore_errors=True)
        # score: timeouts are not kills (they count in the denominator); score_with_timeouts counts them as kills
        score = '' if k + s_ + to == 0 else f'{k}/{k + s_ + to}'
        score_t = '' if k + s_ + to == 0 else f'{k + to}/{k + s_ + to}'
        rows.append(dict(folder=fid, baseline=('pass' if base == 'survived' else base), sites=len(cand), mutants=len(pick),
                         killed=k, survived=s_, timeout=to, stillborn=sb, score=score, score_with_timeouts=score_t))
        print(f"{fid:60s} base={rows[-1]['baseline']:8s} sites={len(cand):4d} killed={k} survived={s_} timeout={to} stillborn={sb} score={score}", flush=True)
    with open(a.out, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
    if detail:
        with open(a.out.replace('.csv', '_detail.csv'), 'w', newline='') as f:
            w = csv.DictWriter(f, fieldnames=list(detail[0].keys())); w.writeheader(); w.writerows(detail)
    print('wrote', a.out)

if __name__ == '__main__':
    main()
