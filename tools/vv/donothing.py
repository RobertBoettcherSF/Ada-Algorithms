#!/usr/bin/env python3
"""'Do-nothing' check (docs/VV.md 3d): would the folder's tests notice if the
main subprogram did nothing?

For each folder with a tests.adb, every public subprogram (declared in a
non-test .ads, body in the matching .adb) is replaced, one at a time and in a
scratch copy, by a trivial body that still compiles:
  procedure       -> null;  (in out parameters come back unchanged)
  Boolean function-> return False / return True  (two variants)
  other function  -> return the first parameter of the same type (identity),
                     else a default object (scalars zero-filled), else [].
Then the folder's tests are built (GNAT 14, -gnat2022 -gnata) and run.
Postconditions, contract cases and type invariants are switched off
(Assertion_Policy Ignore) so the tests themselves, not the spec, must notice;
preconditions and the tests' own pragma Assert stay on. Scalars are
zero-filled (pragma Initialize_Scalars + gnatbind -S00).

Result per subprogram: killed (tests fail, raise, or hang), survived (tests
still pass), stillborn (no trivial body compiles). The *main* subprogram is
the public one whose name shares a word with the folder name
(Sort, Run_Chinese_Whispers; subprograms with parameters first, since a
zero-filled constructor result is often the right answer), else the one the tests name most often; Boolean
predicates such as Is_Sorted only when nothing else is called; a folder is flagged 'weak' when the
do-nothing version of its main subprogram survives. Other survivors are listed
for information.

usage: donothing.py [--folders F ...] [--from-file ids.txt] [-j N] [--out vv/results/donothing.csv]
"""
import argparse, csv, glob, os, re, shutil, subprocess, tempfile
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GNATMAKE = os.environ.get('VV_GNATMAKE', 'gnatmake')
ADC = ('pragma Initialize_Scalars;\n'
       'pragma Assertion_Policy (Post => Ignore, Contract_Cases => Ignore, Type_Invariant => Ignore,\n'
       '                         Type_Invariant\'Class => Ignore, Post\'Class => Ignore);\n')
MAINS = ('tests.adb', 'tests/main.adb', 'src/tests.adb')

def strip(text):
    """Blank out comments and string/char literals (same length, so offsets stay valid)."""
    out = []
    for line in text.split('\n'):
        s = re.sub(r'"([^"]|"")*"', lambda m: '"' + ' ' * (len(m.group()) - 2) + '"', line)
        s = re.sub(r"'.'", lambda m: "' '" if not re.match(r"\w", s[max(0, m.start()-1):m.start()] or ' ') else m.group(), s)
        i = s.find('--')
        out.append(s if i < 0 else s[:i] + ' ' * (len(s) - i))
    return '\n'.join(out)

HDR = re.compile(r'^([ \t]*)(?:overriding\s+|not\s+overriding\s+)?(function|procedure)\s+(\w+)\b', re.M | re.I)

def top_level_is(code, start):
    """Index just after the header's top-level 'is' (body start), or None if the header ends in ';' first,
    or it is an expression function / renames / separate / generic instance."""
    depth = 0
    for m in re.finditer(r'\(|\)|;|\bis\b|\brenames\b', code[start:], re.I):
        t = m.group().lower()
        if t == '(':
            depth += 1
        elif t == ')':
            depth -= 1
        elif depth == 0:
            if t in (';', 'renames'):
                return None
            if t == 'is':
                after = code[start + m.end():].lstrip()
                if after[:1] == '(' or re.match(r'(separate|new|abstract|null)\b', after, re.I):
                    return None
                return start + m.end()
    return None

def sig(code, start, body):
    h = code[start:body]
    params = []
    pm = re.search(r'\((.*)\)', h, re.S)
    if pm:
        for part in pm.group(1).split(';'):
            if ':' in part:
                names, typ = part.split(':', 1)
                typ = re.sub(r'^\s*(in\s+out|in|out|access|aliased)\s+', '', typ.strip(), flags=re.I)
                typ = re.sub(r'\s*:=.*$', '', typ, flags=re.S).strip()
                mode = re.match(r'\s*(in\s+out|out)\b', part.split(':', 1)[1], re.I)
                for n in names.split(','):
                    params.append((n.strip(), typ, (mode.group(1).lower() if mode else 'in')))
    rm = re.search(r'\breturn\s+([\w.]+(?:\'Class)?)', h[pm.end() if pm else 0:], re.I)
    return params, (rm.group(1) if rm else None)

def bodies(adb_text, public):
    """[(name, kind, header_start, body_start, end_start, end_stop, params, rtype)] for package-level bodies of public subprograms."""
    code = strip(adb_text)
    pk = re.search(r'\bpackage\s+body\s+[\w.]+\b[^;]*?\bis\b', code, re.I | re.S)
    if not pk:
        return []
    out = []
    for m in HDR.finditer(code, pk.end()):
        name, kind, ind = m.group(3), m.group(2).lower(), m.group(1)
        if name.lower() not in public:
            continue
        b = top_level_is(code, m.start())
        if b is None:
            continue
        e = (re.compile(r'^' + re.escape(ind) + r'end\s+' + re.escape(name) + r'\s*;', re.M | re.I).search(code, b)
             or re.compile(r'\bend\s+' + re.escape(name) + r'\s*;', re.I).search(code, b))   # one-line bodies
        if not e:
            continue
        params, rt = sig(code, m.start(), b)
        out.append((name, kind, m.start(), b, e.start(), e.end(), params, rt))
    return out

def public_names(ads_text):
    code = strip(ads_text)
    priv = re.search(r'^\s*private\b', code, re.M | re.I)
    vis = code[:priv.start()] if priv else code
    return {m.group(3).lower() for m in HDR.finditer(vis)}

def variants(kind, params, rt):
    if kind == 'procedure':
        return [('null', 'begin\n      null;\n   ')]
    if rt and rt.lower() in ('boolean', 'standard.boolean'):
        return [('False', 'begin\n      return False;\n   '), ('True', 'begin\n      return True;\n   ')]
    v = [('identity ' + n, f'begin\n      return {n};\n   ') for n, t, mode in params if t.lower() == (rt or '').lower() and mode == 'in'][:1]
    v.append(('default', f'begin\n      return R : {rt} do\n         null;\n      end return;\n   '))
    v.append(('empty', 'begin\n      return [];\n   '))
    return v

def run_tests(work, timeout=20):
    main = next((m for m in MAINS if os.path.exists(os.path.join(work, m))), None)
    os.makedirs(os.path.join(work, 'obj'), exist_ok=True)
    inc = [f'-I{d}' for d in ('src', 'tests') if os.path.isdir(os.path.join(work, d))]
    b = subprocess.run([GNATMAKE, '-q', '-f', '-gnat2022', '-gnata', '-gnatec=' + os.path.join(work, 'dn.adc'), *inc,
                        '-D', 'obj', main, '-o', 'tbin', '-bargs', '-S00'], cwd=work, capture_output=True, text=True)
    if b.returncode != 0:
        return 'stillborn'
    try:
        r = subprocess.run(['./tbin'], cwd=work, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return 'killed'
    out = r.stdout + r.stderr
    if r.returncode != 0 or re.search(r'^\s*FAIL|\b[1-9]\d* FAIL|raised ', out, re.M):
        return 'killed'
    return 'survived'

def check_folder(fid, work_root):
    src = os.path.join(ROOT, fid)
    main = next((m for m in MAINS if os.path.exists(os.path.join(src, m))), None)
    row = dict(folder=fid, baseline='', main='', main_result='', verdict='', subprograms=0, survived='', killed=0, stillborn=0)
    if not main:
        row['verdict'] = 'no tests'; return row, []
    work = tempfile.mkdtemp(prefix=fid.replace('/', '_') + '_', dir=work_root)
    try:
        shutil.copytree(src, work, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns('obj', 'bin', 'gnatprove', '*.o', '*.ali'))
        open(os.path.join(work, 'dn.adc'), 'w').write(ADC)
        row['baseline'] = run_tests(work, timeout=60)
        if row['baseline'] != 'survived':
            row['verdict'] = 'baseline ' + ('fails' if row['baseline'] == 'killed' else 'does not build'); return row, []
        tests_text = ''.join(open(f, errors='replace').read() for f in glob.glob(os.path.join(work, '**', 'test*.ad[sb]'), recursive=True)
                             + [os.path.join(work, main)])
        tests_code = strip(tests_text).lower()
        targets = []
        for ads in sorted(glob.glob(os.path.join(work, '**', '*.ads'), recursive=True)):
            if os.path.basename(ads).startswith(('test', 'main')):
                continue
            adb = ads[:-1] + 'b'
            if not os.path.exists(adb):
                continue
            pub = public_names(open(ads, errors='replace').read())
            for bd in bodies(open(adb, errors='replace').read(), pub):
                targets.append((adb, bd))
        details = []
        uses = {}
        for adb, (name, kind, hs, bs, es, ee, params, rt) in targets:
            uses[name] = len(re.findall(r'\b' + re.escape(name.lower()) + r'\b', tests_code))
        called = [t for t in targets if uses[t[1][0]] > 0]
        row['subprograms'] = len(called)
        if not called:
            row['verdict'] = 'no public subprogram body called by tests'; return row, []
        # main = the most-mentioned subprogram that is not a Boolean predicate (Is_Sorted etc. are usually
        # the tests' own checkers); only if every called subprogram is a predicate, the most-mentioned one
        def is_pred(t): return t[1][1] == 'function' and (t[1][7] or '').lower().endswith('boolean')
        # prefer a subprogram whose name shares a word with the folder name (Run_Chinese_Whispers, Sort, Find)
        stop = {'ada', 'spark', 'algorithm', 'stub', 'lite', 'the', 'of', 'and', 'with', 'a'}
        ftoks = [w for w in re.split(r'[^a-z0-9]+', fid.split('/')[-1].lower()) if w and w not in stop]
        def name_score(t):
            parts = t[1][0].lower().split('_')
            return sum(1 for w in ftoks if any(p[:4] == w[:4] and len(p) >= 3 for p in parts))
        pool = [t for t in called if not is_pred(t)] or called
        main_name = max(pool, key=lambda t: (bool(t[1][6]), name_score(t) > 0, uses[t[1][0]]))[1][0]   # constructors without parameters last
        row['main'] = main_name
        surv = []
        for adb, (name, kind, hs, bs, es, ee, params, rt) in called:
            orig = open(adb, errors='replace').read()
            res, used = 'stillborn', ''
            for vname, vbody in variants(kind, params, rt):      # every variant that compiles; survived if any survives
                open(adb, 'w').write(orig[:bs] + '\n   ' + vbody + orig[es:])
                r = run_tests(work)
                if r == 'stillborn':
                    continue
                if res != 'survived':
                    res, used = r, vname
                if r == 'survived':
                    break
            open(adb, 'w').write(orig)
            details.append(dict(folder=fid, file=os.path.relpath(adb, work), subprogram=name, kind=kind,
                                test_mentions=uses[name], trivial_body=used, result=res))
            if res == 'survived': surv.append(name)
            elif res == 'killed': row['killed'] += 1
            else: row['stillborn'] += 1
            if name == main_name: row['main_result'] = res
        row['survived'] = ' '.join(surv)
        row['verdict'] = ('weak' if row['main_result'] == 'survived' else
                          'unchecked (main stillborn)' if row['main_result'] == 'stillborn' else 'ok')
        return row, details
    finally:
        shutil.rmtree(work, ignore_errors=True)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--folders', nargs='*')
    ap.add_argument('--from-file')
    ap.add_argument('-j', '--jobs', type=int, default=4)
    ap.add_argument('--out', default=os.path.join(ROOT, 'vv', 'results', 'donothing.csv'))
    ap.add_argument('--work', default='/tmp/vv_dn')
    a = ap.parse_args()
    ids = list(a.folders or [])
    if a.from_file:
        ids += [l.strip() for l in open(a.from_file) if l.strip()]
    os.makedirs(a.work, exist_ok=True)
    rows, det = [], []
    det_path = a.out.replace('.csv', '_detail.csv')
    with ThreadPoolExecutor(max(1, a.jobs)) as ex:
        for row, d in ex.map(lambda f: check_folder(f, a.work), ids):
            rows.append(row); det += d
            print(f"{row['folder']:60s} {row['verdict']:12s} main={row['main']}:{row['main_result']} survived=[{row['survived']}]", flush=True)
            # write incrementally so an interruption keeps what is done
            with open(a.out, 'w', newline='') as f:
                w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
            if det:
                with open(det_path, 'w', newline='') as f:
                    w = csv.DictWriter(f, fieldnames=list(det[0].keys())); w.writeheader(); w.writerows(det)
    print('wrote', a.out)

if __name__ == '__main__':
    main()
