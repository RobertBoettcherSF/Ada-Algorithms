#!/usr/bin/env python3
"""Answer plant for folders whose Fail_Count plant is n/a (room 2026-10-08).

plant_ok=n/a means there is no failure counter to bump, so it says nothing
about whether make test can go red. This tool plants a WRONG ANSWER and
requires `make test` to exit non-zero *after the planted code built*.

Site order (first red wins):
  1. library .adb: flip `return True/False`, flip Result/Ok/Found := Bool,
     off-by-one on simple `return <int expr>` / Result|Count := <lit>
  2. library .adb: operator mutations (tools/vv/mutate.py OPS), spread sample
  3. test / demo main (logic lives there when there is no library unit):
     same flip / off-by-one, then operator mutations
A plant whose build fails (compile error) is NOT red; it is skipped.

answer_plant_ok:
  yes      - some plant built and make test exited non-zero (gate cleared)
  no       - >=1 plant built and every built plant still exited 0 (finding)
  pending  - nothing could be planted / built / ran in time (not measured)
Only `yes` clears the gate. Writes tools/vv/silent_fail_answer_plant.csv.
"""
from __future__ import annotations
import argparse, csv, os, re, shutil, sys, tempfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from collections import Counter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'tools', 'vv'))
import mutate  # noqa: E402

MAIN_NAME = re.compile(r'(^|/)(tests?(_\w+)?|main|demo\w*|own_checks?)\.adb$', re.I)
SKIP_DIR = {'obj', 'bin', 'gnatprove', '.git', 'alire'}
BOOL_RET = re.compile(r'^(\s*)return\s+(True|False)\s*;', re.I | re.M)
BOOL_ASSIGN = re.compile(
    r'^(\s*)((?:Result|Ok|Found|Success|Valid|Is_\w+|Has_\w+)\s*:=\s*)(True|False)\s*;', re.I | re.M)
INT_RET = re.compile(r'^(\s*)return\s+(\(?\s*\w+(?:\s*[\+\-]\s*\d+)?\s*\)?|\d+)\s*;', re.I | re.M)
INT_ASSIGN = re.compile(r'^(\s*)((?:Result|Count|Length|Size|Index|Total|Sum)\s*:=\s*)(\d+)\s*;', re.I | re.M)
BUILD_FAIL = re.compile(
    r'\.ad[sb]:\d+:\d+:\s*(error|\(style\))|compilation phase failed|compilation of .* failed'
    r'|bind(ing)? (phase )?failed|link(ing)? (phase )?failed|gnatmake: .* (failed|not found)'
    # linker / driver only — do not match test prose like "cannot find target"
    r'|cannot find -l|cannot find file|ld: .*cannot find|undefined reference', re.I)
OPS_PER_FILE = 6
MAX_LIB = 10
MAX_TRIES = 20


def env14():
    parts = [x for x in os.environ.get('PATH', '').split(':') if 'gnat_native' not in x and 'gprbuild_' not in x]
    e = dict(os.environ); e['PATH'] = ':'.join(parts)
    return e


def adb_files(fid):
    base = os.path.join(ROOT, fid); lib, main = [], []
    for dp, dns, fns in os.walk(base):
        dns[:] = [d for d in dns if d not in SKIP_DIR]
        for fn in fns:
            if fn.endswith('.adb'):
                rel = os.path.relpath(os.path.join(dp, fn), base).replace('\\', '/')
                (main if MAIN_NAME.search(rel) or rel.startswith('tests/') else lib).append(rel)
    return sorted(lib), sorted(main)


def simple_sites(text):
    for m in BOOL_RET.finditer(text):
        flip = 'False' if m.group(2).lower() == 'true' else 'True'
        yield m.start(), m.end(), f'{m.group(1)}return {flip};', 'flip_bool', m.group(0).strip()
    for m in BOOL_ASSIGN.finditer(text):
        flip = 'False' if m.group(3).lower() == 'true' else 'True'
        yield m.start(), m.end(), f'{m.group(1)}{m.group(2)}{flip};', 'flip_bool_assign', m.group(0).strip()
    for m in INT_RET.finditer(text):
        expr = m.group(2).strip()
        if expr.lower() in ('true', 'false', 'null') or re.search(r'[."]', expr):
            continue
        if re.search(r'\+\s*1\s*\)?$', expr):
            new, kind = re.sub(r'\+\s*1(\s*\)?)$', r'- 1\1', expr), 'off_by_one_minus'
        elif re.fullmatch(r'\d+', expr) and int(expr) >= 1:
            # Prefer -1 for bare literals so Result/Index subtypes still compile
            # (return Max_Length + 1 is a compile-time CE under GNAT).
            new, kind = str(int(expr) - 1), 'off_by_one_minus'
        else:
            new, kind = f'({expr}) + 1', 'off_by_one_plus'
        yield m.start(), m.end(), f'{m.group(1)}return {new};', kind, m.group(0).strip()
    for m in INT_ASSIGN.finditer(text):
        yield (m.start(), m.end(), f'{m.group(1)}{m.group(2)}{int(m.group(3)) + 1};',
               'off_by_one_assign', m.group(0).strip())


CHECK_LINE = re.compile(r'Expect|Check|Assert|Verify|Report|Want|Ref\w*\s*:=|\b=\s*-?\d|/=\s*-?\d', re.I)
INT_LIT = re.compile(r'(?<![\w.#])(-?\d+)(?![\w.#])')


def literal_sites(text):
    """Perturb an integer literal on a check / expected-value line of the test main
    (flips the answer the harness compares against; it must then go red)."""
    out, pos = [], 0
    for line in text.split('\n'):
        code = line.split('--')[0]
        if CHECK_LINE.search(code) and '"' not in code and not re.match(r'\s*(with|use|pragma\s+Ada|procedure|function|package|for\s+\w+\s+in)\b', code, re.I):
            for m in INT_LIT.finditer(code):
                v = int(m.group(1))
                out.append((pos + m.start(), pos + m.end(), str(v + 1) if v >= 0 else f'({v + 1})',
                            'main_expected_literal', line.strip()[:100]))
                break
        pos += len(line) + 1
    return out[:4]


def op_sites(path, text):
    """Spread sample of mutate.py operator sites -> (start, end, repl, kind, detail)."""
    try:
        s = mutate.sites(path)
    except Exception:
        return []
    if not s:
        return []
    step = max(1, len(s) // OPS_PER_FILE)
    pick = s[::step][:OPS_PER_FILE]
    lines = text.split('\n'); offs = [0]
    for L in lines:
        offs.append(offs[-1] + len(L) + 1)
    out = []
    for ln, a, b, name, rep in pick:
        out.append((offs[ln] + a, offs[ln] + b, rep, 'op ' + name, lines[ln].strip()[:100]))
    return out


def plan(fid):
    src = os.path.join(ROOT, fid)
    lib, main = adb_files(fid)
    lib_simple, lib_ops, m_lit, m_simple, m_ops = [], [], [], [], []
    for rel in lib:
        text = open(os.path.join(src, rel), errors='replace').read()
        lib_simple += [('lib', rel, text) + s for s in simple_sites(text)]
        lib_ops += [('lib', rel, text) + s for s in op_sites(os.path.join(src, rel), text)]
    for rel in main:
        text = open(os.path.join(src, rel), errors='replace').read()
        m_lit += [('main', rel, text) + s for s in literal_sites(text)]
        m_simple += [('main', rel, text) + s for s in simple_sites(text)]
        m_ops += [('main', rel, text) + s for s in op_sites(os.path.join(src, rel), text)]
    # interleave library plants (simple, op, simple, op, ...) so dead early-return
    # sites do not use up the budget; then the test/demo main.
    lib_mix = []
    for i in range(max(len(lib_simple), len(lib_ops))):
        if i < len(lib_simple): lib_mix.append(lib_simple[i])
        if i < len(lib_ops): lib_mix.append(lib_ops[i])
    plans = lib_mix[:MAX_LIB] + m_lit + m_simple[:3] + m_ops[:4]
    return plans, bool(lib), bool(main)


def run_plant(fid, group, rel, text, a, b, repl, work_root, timeout):
    src = os.path.join(ROOT, fid)
    work = tempfile.mkdtemp(prefix='ap_', dir=work_root)
    try:
        shutil.copytree(src, work, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns('obj', 'bin', 'gnatprove', '*.o', '*.ali'))
        open(os.path.join(work, rel), 'w', newline='').write(text[:a] + repl + text[b:])
        if os.path.exists(os.path.join(work, 'Makefile')):
            r = mutate.run_limited(['make', 'test'], work, timeout, env=env14())
        else:
            m = next((x for x in ('tests.adb', 'tests/main.adb', 'src/tests.adb', 'main.adb')
                      if os.path.exists(os.path.join(work, x))), None)
            if not m:
                return 'nobuild'
            inc = [f'-I{d}' for d in ('src', 'tests') if os.path.isdir(os.path.join(work, d))]
            b = mutate.run_limited(['gnatmake', '-q', '-gnat2022', '-gnata'] + inc + ['-o', 'ap_test', m],
                                   work, timeout, env=env14())
            if b is None or b.returncode != 0:
                return 'nobuild'
            r = mutate.run_limited(['./ap_test'], work, timeout, env=env14())
        if r is None:
            return 'timeout'
        out = (r.stdout or '') + (r.stderr or '')
        if r.returncode != 0 and BUILD_FAIL.search(out):
            return 'nobuild'
        return r.returncode
    finally:
        shutil.rmtree(work, ignore_errors=True)


def plant_one(fid, work_root, timeout):
    row = dict(folder=fid, where='', file='', kind='', detail='', planted_rc='',
               tried=0, built=0, answer_plant_ok='pending', note='')
    plans, has_lib, has_main = plan(fid)
    if not plans:
        row['note'] = 'no plant site (lib=%s main=%s)' % (has_lib, has_main); return row
    survived = None
    for group, rel, text, a, b, repl, kind, detail in plans[:MAX_TRIES]:
        row['tried'] += 1
        rc = run_plant(fid, group, rel, text, a, b, repl, work_root, timeout)
        if rc in ('nobuild', 'timeout'):
            continue
        row['built'] += 1
        if isinstance(rc, int) and rc != 0:
            row.update(where=group, file=rel, kind=kind, detail=detail[:120], planted_rc=rc,
                       answer_plant_ok='yes', note='')
            return row
        if survived is None:
            survived = (group, rel, kind, detail)
    if row['built'] and survived:
        g, rel, kind, detail = survived
        row.update(where=g, file=rel, kind=kind, detail=detail[:120], planted_rc=0, answer_plant_ok='no',
                   note=f"{row['built']} built plants all exited 0")
    else:
        row['note'] = f"{row['tried']} plants tried, none built/ran"
    return row


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--plant-csv', default=os.path.join(ROOT, 'tools/vv/silent_fail_plant.csv'))
    ap.add_argument('--out', default=os.path.join(ROOT, 'tools/vv/silent_fail_answer_plant.csv'))
    ap.add_argument('--folders', nargs='*')
    ap.add_argument('-j', type=int, default=4)
    ap.add_argument('--timeout', type=int, default=120)
    ap.add_argument('--work', default=os.path.join(tempfile.gettempdir(), 'flk', 'answer_plant'))
    args = ap.parse_args()
    os.makedirs(args.work, exist_ok=True)
    folders = args.folders or [r['folder'] for r in csv.DictReader(open(args.plant_csv)) if r.get('plant_ok') == 'n/a']
    print(f'answer-plant {len(folders)} folders, j={args.j}', flush=True)
    rows = []
    with ThreadPoolExecutor(max_workers=args.j) as ex:
        futs = {ex.submit(plant_one, f, args.work, args.timeout): f for f in folders}
        for i, fut in enumerate(as_completed(futs), 1):
            try:
                row = fut.result()
            except Exception as e:  # never let one folder kill the run
                row = dict(folder=futs[fut], answer_plant_ok='pending', note=f'error {e!r}'[:120])
            rows.append(row)
            if row['answer_plant_ok'] != 'yes' or i % 50 == 0:
                print(f"  [{i}/{len(folders)}] {row['folder']} -> {row['answer_plant_ok']} "
                      f"{row.get('where','')} {row.get('kind','')} {row.get('note','')}", flush=True)
    rows.sort(key=lambda r: r['folder'])
    cols = ['folder', 'answer_plant_ok', 'where', 'file', 'kind', 'detail', 'planted_rc', 'tried', 'built', 'note']
    if args.folders and os.path.exists(args.out):
        # Partial run (--folders): update those rows in place, keep all others.
        new_by = {r['folder']: r for r in rows}
        old_rows = list(csv.DictReader(open(args.out)))
        seen = set()
        merged = []
        for r in old_rows:
            if r['folder'] in new_by:
                merged.append(new_by[r['folder']]); seen.add(r['folder'])
            else:
                merged.append(r)
        merged += [r for f, r in new_by.items() if f not in seen]
        rows = merged
    with open(args.out, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction='ignore'); w.writeheader(); w.writerows(rows)
    print('wrote', args.out, dict(Counter(r['answer_plant_ok'] for r in rows)), flush=True)


if __name__ == '__main__':
    main()
