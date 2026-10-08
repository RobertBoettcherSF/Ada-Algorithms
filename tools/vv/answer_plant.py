#!/usr/bin/env python3
"""Plant a wrong answer in library code for folders whose Fail_Count plant is n/a.

Room 2026-10-08: plant_ok=n/a means no failure counter to bump. Until an answer
plant shows that make test exits non-zero when the library returns a wrong
answer, treat the folder as 'harness cannot fail' (not a pass).

Mutations (first that applies, then make test):
  - flip `return True` / `return False` in a non-test .adb
  - off-by-one: `return <expr>` where expr is a simple integer/Natural form
    becomes `return (<expr>) + 1` (or - 1 if already `... + 1`)

Writes tools/vv/silent_fail_answer_plant.csv
"""
from __future__ import annotations
import argparse, csv, os, re, shutil, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from collections import Counter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'tools', 'vv'))
import mutate  # noqa: E402

SKIP_NAME = re.compile(r'(^|/)(tests?|own_checks?|demo|harness|binder)', re.I)
BOOL_RET = re.compile(r'^(\s*)return\s+(True|False)\s*;', re.I | re.M)
BOOL_ASSIGN = re.compile(
    r'^(\s*)((?:Result|Ok|Found|Success|Valid|Is_\w+|Has_\w+)\s*:=\s*)(True|False)\s*;',
    re.I | re.M)
INT_ASSIGN = re.compile(
    r'^(\s*)((?:Result|Count|Length|Size|Index|N|K)\s*:=\s*)(\d+)\s*;',
    re.I | re.M)
# simple return of identifier or literal or ident +/- literal
INT_RET = re.compile(
    r'^(\s*)return\s+((?:\(?\s*)?(?:\w+(?:\s*[\+\-]\s*\d+)?|\d+)(?:\s*\)?)?)\s*;',
    re.I | re.M)

def env14():
    p = os.environ.get('PATH', '')
    parts = [x for x in p.split(':') if 'gnat_native' not in x and 'gprbuild_' not in x]
    e = dict(os.environ); e['PATH'] = ':'.join(parts) if parts else p
    return e

def lib_adbs(fid):
    base = os.path.join(ROOT, fid)
    out = []
    for dp, dns, fns in os.walk(base):
        dns[:] = [d for d in dns if d not in ('obj', 'bin', 'gnatprove', '.git')]
        for fn in fns:
            if not fn.endswith('.adb'): continue
            rel = os.path.relpath(os.path.join(dp, fn), base)
            if SKIP_NAME.search(rel.replace('\\', '/')): continue
            out.append(rel)
    return sorted(out)

def candidates(text):
    """Yield (start, end, new_text_fragment, kind, detail) for one mutation site."""
    for m in BOOL_RET.finditer(text):
        flip = 'False' if m.group(2).lower() == 'true' else 'True'
        # preserve original casing style lightly
        if m.group(2)[0].isupper():
            flip = flip.capitalize() if flip != 'True' else 'True'
            if flip == 'false': flip = 'False'
        yield m.start(), m.end(), f'{m.group(1)}return {flip};', 'flip_bool', m.group(0).strip()
    for m in INT_RET.finditer(text):
        expr = m.group(2).strip()
        if expr.lower() in ('true', 'false'): continue
        # skip returns that look like access/null/stringish
        if re.search(r'[."]|null', expr, re.I): continue
        if re.search(r'\+\s*1\s*$', expr):
            new_expr = re.sub(r'\+\s*1\s*$', '- 1', expr)
            kind = 'off_by_one_minus'
        else:
            new_expr = f'({expr}) + 1'
            kind = 'off_by_one_plus'
        yield m.start(), m.end(), f'{m.group(1)}return {new_expr};', kind, m.group(0).strip()
    for m in BOOL_ASSIGN.finditer(text):
        flip = 'False' if m.group(3).lower() == 'true' else 'True'
        if m.group(3)[0].isupper():
            flip = 'True' if flip.lower() == 'true' else 'False'
        yield (m.start(), m.end(), f'{m.group(1)}{m.group(2)}{flip};',
               'flip_bool_assign', m.group(0).strip())
    for m in INT_ASSIGN.finditer(text):
        n = int(m.group(3))
        yield (m.start(), m.end(), f'{m.group(1)}{m.group(2)}{n + 1};',
               'off_by_one_assign', m.group(0).strip())

def plant_one(fid, work_root, timeout):
    row = dict(folder=fid, file='', kind='', detail='', planted_rc='',
               answer_plant_ok='n/a', note='')
    libs = lib_adbs(fid)
    if not libs:
        row['note'] = 'no library .adb'; return row
    src = os.path.join(ROOT, fid)
    # try sites in order across files
    sites = []
    for rel in libs:
        text = open(os.path.join(src, rel), errors='replace').read()
        for a, b, repl, kind, detail in candidates(text):
            sites.append((rel, text, a, b, repl, kind, detail))
    if not sites:
        row['note'] = 'no flip_bool/off_by_one site'; return row

    for rel, text, a, b, repl, kind, detail in sites:
        work = tempfile.mkdtemp(prefix='ap_', dir=work_root)
        try:
            shutil.copytree(src, work, dirs_exist_ok=True,
                            ignore=shutil.ignore_patterns('obj', 'bin', 'gnatprove', '*.o', '*.ali'))
            nl = '\r\n' if '\r\n' in text else '\n'
            new = text[:a] + repl + text[b:]
            open(os.path.join(work, rel), 'w', newline='').write(new)
            if not os.path.exists(os.path.join(work, 'Makefile')):
                row.update(file=rel, kind=kind, detail=detail[:80], note='no Makefile')
                continue
            r = mutate.run_limited(['make', 'test'], work, timeout, env=env14())
            if r is None:
                rc, note = 'timeout', 'timeout'
            else:
                rc, note = r.returncode, ''
            ok = 'yes' if isinstance(rc, int) and rc != 0 else ('no' if rc == 0 else 'n/a')
            row.update(file=rel, kind=kind, detail=detail[:120], planted_rc=rc,
                       answer_plant_ok=ok, note=note)
            if ok == 'yes':
                return row
            # try next site if this one still exits 0 (mutation may be dead/equivalent)
        finally:
            shutil.rmtree(work, ignore_errors=True)
    if row['answer_plant_ok'] == 'n/a' and not row['note']:
        row['note'] = 'all candidate plants still exit 0 or did not run'
    return row

def load_na_folders(plant_csv):
    out = []
    with open(plant_csv, newline='') as f:
        for r in csv.DictReader(f):
            if r.get('plant_ok') == 'n/a':
                out.append(r['folder'])
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--plant-csv', default=os.path.join(ROOT, 'tools/vv/silent_fail_plant.csv'))
    ap.add_argument('--out', default=os.path.join(ROOT, 'tools/vv/silent_fail_answer_plant.csv'))
    ap.add_argument('--folders', nargs='*')
    ap.add_argument('--sample', type=int, default=0, help='first N n/a folders (0=all)')
    ap.add_argument('--seed-sample', type=int, default=20261008)
    ap.add_argument('-j', type=int, default=4)
    ap.add_argument('--timeout', type=int, default=120)
    ap.add_argument('--work', default='/tmp/flk/answer_plant')
    args = ap.parse_args()
    os.makedirs(args.work, exist_ok=True)
    if args.folders:
        folders = args.folders
    else:
        folders = load_na_folders(args.plant_csv)
        if args.sample and args.sample < len(folders):
            # deterministic sample
            import random
            rng = random.Random(args.seed_sample)
            folders = sorted(rng.sample(folders, args.sample))
    print(f'answer-plant {len(folders)} folders, j={args.j}', flush=True)
    rows = []
    with ThreadPoolExecutor(max_workers=args.j) as ex:
        futs = {ex.submit(plant_one, fid, args.work, args.timeout): fid for fid in folders}
        for i, fut in enumerate(as_completed(futs), 1):
            row = fut.result()
            rows.append(row)
            if i % 10 == 0 or row['answer_plant_ok'] != 'yes':
                print(f"  [{i}/{len(folders)}] {row['folder']} -> {row['answer_plant_ok']} {row.get('kind','')} {row.get('note','')}", flush=True)
    rows.sort(key=lambda r: r['folder'])
    cols = ['folder', 'file', 'kind', 'detail', 'planted_rc', 'answer_plant_ok', 'note']
    with open(args.out, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader(); w.writerows(rows)
    print('wrote', args.out, 'counts', dict(Counter(r['answer_plant_ok'] for r in rows)))

if __name__ == '__main__':
    main()
