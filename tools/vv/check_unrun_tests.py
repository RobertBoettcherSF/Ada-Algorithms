#!/usr/bin/env python3
"""Unrun test sources (tools/vv/unrun_tests_ok.csv).

In every folder with a Makefile, a test source (tests.adb, test.adb, own_checks.adb, test_*.adb,
tests_*.adb) must be built and run by `make test`: it is a main (a gpr `for Main use` entry, or
named in the Makefile), or a unit that a run source `with`s (transitively), and, when the gpr lists
Source_Files, it is in that list. A test source that nothing runs is a hit (its checks are described
but never executed; e.g. own_checks.adb that tests.adb never calls). Known hits are listed with a
reason in tools/vv/unrun_tests_ok.csv (folder,file,reason); an unlisted hit, or a listed row that is
no longer a hit, fails. Static check (no build).
  python3 tools/vv/check_unrun_tests.py [--root REPO] [--selftest]   (exit 0 = consistent)
--selftest runs the control: a scratch folder whose tests.adb does not call own_checks.adb must be
a hit, and the same folder with the call added must not.
"""
import argparse, csv, os, re, sys, tempfile

TEST = re.compile(r'^(tests?|own_checks|tests?_\w+)\.adb$', re.I)
WITH = re.compile(r'\bwith\s+([\w.,\s]+);', re.I)
MAIN = re.compile(r'for\s+Main\s+use\s*\(([^)]*)\)', re.I)
SRCF = re.compile(r'for\s+Source_Files\s+use\s*\(([^)]*)\)', re.I)
SKIP = {'.git', 'obj', 'bin', 'gnatprove', 'alire', 'tools', 'docs'}

def strip_comments(t):
    return re.sub(r'--[^\n]*', '', t)

def read(p):
    try:
        return open(p, errors='replace').read()
    except OSError:
        return ''

def hits_in(d):
    files = os.listdir(d)
    adb = {f.lower(): f for f in files if f.endswith('.adb')}
    mk = read(os.path.join(d, 'Makefile'))
    #  only the project files the Makefile builds (-P<name>) decide mains / Source_Files
    used = set()
    for tok in re.findall(r'-P\s*(\$\(\w+\)|[\w./-]+)', mk):
        if tok.startswith('$('):
            m = re.search(r'^\s*' + re.escape(tok[2:-1]) + r'\s*[:?]?=\s*(\S+)', mk, re.M)
            tok = m.group(1) if m else ''
        used.add(os.path.basename(tok).lower().removesuffix('.gpr'))
    gpr_files = [f for f in files if f.endswith('.gpr') and 'proof' not in f.lower()]
    gprs = [read(os.path.join(d, f)) for f in gpr_files if f[:-4].lower() in used]
    mains, srcs = set(), None
    for g in gprs:
        g = strip_comments(g)
        for m in MAIN.findall(g):
            mains |= {x.strip().strip('"').lower() for x in m.split(',') if x.strip()}
        for s in SRCF.findall(g):
            srcs = (srcs or set()) | {x.strip().strip('"').lower() for x in s.split(',') if x.strip()}
    for f in adb:
        stem = f[:-4]
        if re.search(r'(?<![\w/])' + re.escape(stem) + r'(\.adb)?\b', mk, re.I) and TEST.match(f):
            mains.add(f)
    run, todo = set(), [m for m in mains if m in adb]
    while todo:
        f = todo.pop()
        if f in run:
            continue
        run.add(f)
        for grp in WITH.findall(strip_comments(read(os.path.join(d, adb[f])))):
            for u in grp.split(','):
                c = u.strip().lower().replace('.', '-') + '.adb'
                if c in adb and c not in run:
                    todo.append(c)
    out = []
    for f in sorted(adb):
        if not TEST.match(f):
            continue
        if f not in run:
            out.append((adb[f], 'not built or run by make test (no main or run unit with-s it)'))
        elif srcs is not None and f not in srcs:
            out.append((adb[f], 'not in the gpr Source_Files (not compiled)'))
    return out

def scan(root):
    res = {}
    for dp, dirs, files in os.walk(root):
        dirs[:] = sorted(x for x in dirs if x not in SKIP)
        if dp == root or 'Makefile' not in files:
            continue
        for fn, why in hits_in(dp):
            res[(os.path.relpath(dp, root), fn)] = why
    return res

def selftest():
    with tempfile.TemporaryDirectory() as t:
        d = os.path.join(t, 'x', 'F'); os.makedirs(d)
        open(os.path.join(d, 'Makefile'), 'w').write('test:\n\tgprbuild -Pf.gpr\n\t@bin/tests\n')
        open(os.path.join(d, 'f.gpr'), 'w').write('project F is\n   for Main use ("tests.adb");\nend F;\n')
        open(os.path.join(d, 'own_checks.adb'), 'w').write('procedure Own_Checks is begin null; end Own_Checks;\n')
        open(os.path.join(d, 'tests.adb'), 'w').write('procedure Tests is\nbegin\n   null;\nend Tests;\n')
        a = scan(t)
        open(os.path.join(d, 'tests.adb'), 'w').write('with Own_Checks;\nprocedure Tests is\nbegin\n   Own_Checks;\nend Tests;\n')
        b = scan(t)
        open(os.path.join(d, 'f.gpr'), 'w').write('project F is\n   for Main use ("tests.adb");\n   for Source_Files use ("tests.adb");\nend F;\n')
        c = scan(t)
    ok = (list(a) == [('x/F', 'own_checks.adb')] and not b and list(c) == [('x/F', 'own_checks.adb')])
    print(('ok  ' if ok else 'FAIL') + ' unrun-tests control: unwired own_checks found, wired not, missing from Source_Files found')
    return ok

ap = argparse.ArgumentParser()
ap.add_argument('--root', default=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
ap.add_argument('--selftest', action='store_true')
a = ap.parse_args()
good = selftest()
if a.selftest:
    sys.exit(0 if good else 1)
okp = os.path.join(a.root, 'tools/vv/unrun_tests_ok.csv')
listed = {(r['folder'], r['file']): r for r in csv.DictReader(open(okp, newline=''))} if os.path.exists(okp) else {}
hits = scan(a.root)
bad = [f'FAIL {f}/{fn}: {why} (not listed in tools/vv/unrun_tests_ok.csv)' for (f, fn), why in sorted(hits.items()) if (f, fn) not in listed]
bad += [f'FAIL {f}/{fn}: listed in tools/vv/unrun_tests_ok.csv but is run now (drop the row)' for (f, fn) in sorted(listed) if (f, fn) not in hits]
for b in bad:
    print(b)
print(('ok  ' if not bad and good else 'FAIL') + f' unrun test sources: {len(hits)} hit(s), {len(listed)} listed, {len(bad)} problem(s)')
sys.exit(1 if bad or not good else 0)
