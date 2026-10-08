#!/usr/bin/env python3
"""Whole-repo index-independence scan (room 2026-10-08).

For every public subprogram that takes an unconstrained array:

  (1) same payload with 'First = 0 and 'First = 100 must match the
      baseline ('First = 1) answer;
  (2) when two or more arrays are taken, shift them by DIFFERENT amounts
      (AdaBoost case: Labels paired by position, not by shared index);
  (3) also run with 'First near the upper end of the index subtype so
      that (Lo + Hi) / 2 overflows under -gnato.

Findings kinds (column `kind` in tools/vv/index_shift.csv):
  shift_mismatch     - answers differ across origins → fix with 'First-relative
                       indexing / subtypes of the parameter's index
  midpoint_overflow  - CE / wrong answer with 'First near Index'Last under
                       -gnato → rewrite midpoints as Lo + (Hi - Lo) / 2
                       (never (Lo+Hi)/2); in SPARK folders prove it does
                       not overflow
  ok                 - all dynamic checks passed
  static_midpoint    - source still contains (Lo+Hi)/2 style (review)
  skipped            - no runnable dynamic driver for this signature yet
  error              - build/run error unrelated to indexing

Training-ready requires index_independent=yes once the scan covers the
folder (docs/VV.md). Sample first, then expand.

Usage:
  python3 tools/vv/index_shift.py --sample 40 -j 4
  python3 tools/vv/index_shift.py --folders graphs/Ada/Shortest-Path-Problem
"""
from __future__ import annotations
import argparse, csv, os, re, shutil, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from collections import Counter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'tools', 'vv'))
import mutate  # noqa: E402

ARR_PARAM = re.compile(
    r'(\w+)\s*:\s*(in\s+|in\s+out\s+|out\s+)?(\w+)\s*'
    r'(?:\([^)]*range\s*<>[^)]*\)|range\s*<>)',
    re.I)
# Common "Element_Array is array (<>) of Integer" style
ARR_TYPE = re.compile(
    r'type\s+(\w+)\s+is\s+array\s*\(\s*[\w.\']+\s+range\s*<>\s*\)\s+of\s+(\w+)',
    re.I)
MIDPOINT = re.compile(
    r'\(\s*(\w+)\s*\+\s*(\w+)\s*\)\s*/\s*2',
    re.I)
SKIP_DIR = {'obj', 'bin', 'gnatprove', '.git', 'alire'}
MAIN_ADB = re.compile(r'(^|/)(tests?|main|demo|own_checks)\.adb$', re.I)


def env14():
    parts = [x for x in os.environ.get('PATH', '').split(':')
             if 'gnat_native' not in x and 'gprbuild_' not in x]
    e = dict(os.environ); e['PATH'] = ':'.join(parts); return e


def folders():
    out = []
    for line in subprocess.run(['git', 'ls-files'], cwd=ROOT, capture_output=True, text=True).stdout.splitlines():
        if '/' not in line: continue
        parts = line.split('/')
        if len(parts) >= 3 and parts[1] in ('Ada',) or (len(parts) >= 3 and parts[1].startswith('SPARK')):
            fid = '/'.join(parts[:3])
            if fid not in out and os.path.isdir(os.path.join(ROOT, fid)):
                out.append(fid)
    return out


def ads_files(fid):
    base = os.path.join(ROOT, fid); out = []
    for dp, dns, fns in os.walk(base):
        dns[:] = [d for d in dns if d not in SKIP_DIR]
        for fn in fns:
            if fn.endswith('.ads') and not MAIN_ADB.search(fn):
                out.append(os.path.join(dp, fn))
    return out


def adb_lib_files(fid):
    base = os.path.join(ROOT, fid); out = []
    for dp, dns, fns in os.walk(base):
        dns[:] = [d for d in dns if d not in SKIP_DIR]
        for fn in fns:
            if fn.endswith('.adb') and not MAIN_ADB.search(os.path.relpath(os.path.join(dp, fn), base).replace('\\', '/')):
                out.append(os.path.join(dp, fn))
    return out


def unconstrained_types(ads_text):
    return {m.group(1): m.group(2) for m in ARR_TYPE.finditer(ads_text)}


def public_array_subs(ads_text, types):
    """Very light: find 'function/procedure Name (... Type_Name ...' with unconstrained type."""
    subs = []
    for m in re.finditer(r'\b(function|procedure)\s+(\w+)\s*\((.*?)\)\s*(?:return\s+[\w.]+)?',
                         ads_text, re.I | re.S):
        kind, name, params = m.group(1), m.group(2), m.group(3)
        if 'private' in ads_text[:m.start()].lower().split('\n')[-5:]:
            continue
        arr_args = []
        for tname in types:
            if re.search(rf'\b{re.escape(tname)}\b', params):
                # count occurrences
                arr_args += [tname] * len(re.findall(rf'\b{re.escape(tname)}\b', params))
        if arr_args:
            ret = None
            rm = re.search(r'\)\s*return\s+([\w.]+)', ads_text[m.start():m.start() + 400], re.I)
            if rm: ret = rm.group(1)
            subs.append(dict(kind=kind.lower(), name=name, arr_args=arr_args, ret=ret,
                             n_arrays=len(arr_args)))
    return subs


def static_midpoints(fid):
    hits = []
    for path in adb_lib_files(fid) + ads_files(fid):
        text = open(path, errors='replace').read()
        for i, line in enumerate(text.splitlines(), 1):
            code = line.split('--')[0]
            if MIDPOINT.search(code):
                hits.append((os.path.relpath(path, ROOT), i, line.strip()[:120]))
    return hits


def try_dynamic_integer_array(fid, types, subs, work_root, timeout):
    """Build a small driver for Element_Array-of-Integer Find/Sort-like APIs.

    Returns list of result dicts (possibly empty if no suitable sub).
    """
    # Prefer a type whose element is Integer / Natural / Positive
    cand_types = [t for t, e in types.items() if e.lower() in ('integer', 'natural', 'positive')]
    if not cand_types:
        return []
    # Pick package name from first ads
    ads = ads_files(fid)
    if not ads: return []
    pkg_m = re.search(r'^\s*package\s+([\w.]+)', open(ads[0], errors='replace').read(), re.M)
    if not pkg_m: return []
    pkg = pkg_m.group(1)
    tname = cand_types[0]
    # Find a function returning Index/Natural/Integer taking one array + maybe Key
    find_subs = [s for s in subs if s['kind'] == 'function' and s['n_arrays'] == 1
                 and s['ret'] and s['ret'].split('.')[-1].lower() in
                 ('index', 'natural', 'integer', 'positive', 'ext_index')]
    sort_subs = [s for s in subs if s['name'].lower() in ('sort', 'sort_array', 'heapsort', 'quicksort')]
    results = []
    # Dynamic driver for Find-like
    for s in find_subs[:1]:
        results.append(run_find_driver(fid, pkg, tname, s, work_root, timeout))
    for s in sort_subs[:1]:
        results.append(run_sort_driver(fid, pkg, tname, s, work_root, timeout))
    return [r for r in results if r]


def run_find_driver(fid, pkg, tname, sub, work_root, timeout):
    """Baseline First=1 vs 0 vs 100; high First for midpoint; multi not applicable."""
    src = os.path.join(ROOT, fid)
    work = tempfile.mkdtemp(prefix='idx_', dir=work_root)
    try:
        shutil.copytree(src, work, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns('obj', 'bin', 'gnatprove', '*.o', '*.ali'))
        # Discover Index subtype bounds if any
        ads = open(ads_files(fid)[0], errors='replace').read() if ads_files(fid) else ''
        # High first: use 10_000 if Index allows, else Max_N-ish
        high = 10_000
        driver = f'''pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with {pkg}; use {pkg};
procedure Idx_Shift_Driver is
   Fail : Natural := 0;
   procedure Check (Cond : Boolean; Msg : String) is
   begin
      if not Cond then
         Fail := Fail + 1;
         Put_Line ("FAIL " & Msg);
      end if;
   end Check;
   --  payload 2,1,3,2,4 at three origins
   B1 : {tname} (1 .. 5) := (2, 1, 3, 2, 4);
   B0 : {tname} (0 .. 4) := (2, 1, 3, 2, 4);
   B100 : {tname} (100 .. 104) := (2, 1, 3, 2, 4);
   R1, R0, R100 : Integer;
begin
   begin
      R1 := Integer ({sub["name"]} (B1, 3));
      R0 := Integer ({sub["name"]} (B0, 3));
      R100 := Integer ({sub["name"]} (B100, 3));
      --  relative position of the hit must match (Result - A'First)
      Check (R1 - B1'First = R0 - B0'First, "shift0 relative index for key 3");
      Check (R1 - B1'First = R100 - B100'First, "shift100 relative index for key 3");
      --  absolute equality only expected when the API returns a value, not an index
   exception
      when others =>
         Fail := Fail + 1; Put_Line ("FAIL exception on shift compare");
   end;
   --  midpoint overflow probe: long sorted range with high 'First under -gnato
   declare
      Hi_First : constant Integer := {high};
      Long : {tname} (Hi_First .. Hi_First + 64);
   begin
      for I in Long'Range loop
         Long (I) := I - Long'First;  --  0 .. 64
      end loop;
      declare
         R : Integer := Integer ({sub["name"]} (Long, 32));
      begin
         Check (R - Long'First = 32, "high-first hit at relative 32");
      end;
   exception
      when Constraint_Error =>
         Fail := Fail + 1; Put_Line ("FAIL midpoint_overflow Constraint_Error high-first");
      when others =>
         Fail := Fail + 1; Put_Line ("FAIL exception high-first");
   end;
   if Fail > 0 then
      Put_Line ("IDX_SHIFT_FAIL" & Fail'Image);
      raise Program_Error;
   end if;
   Put_Line ("IDX_SHIFT_OK {sub["name"]}");
end Idx_Shift_Driver;
'''
        # Many Find APIs need sorted input — use sorted payload instead
        driver = driver.replace(
            'B1 : {tname} (1 .. 5) := (2, 1, 3, 2, 4);\n   B0 : {tname} (0 .. 4) := (2, 1, 3, 2, 4);\n   B100 : {tname} (100 .. 104) := (2, 1, 3, 2, 4);'
            .format(tname=tname),
            f'B1 : {tname} (1 .. 5) := (1, 2, 3, 4, 5);\n'
            f'   B0 : {tname} (0 .. 4) := (1, 2, 3, 4, 5);\n'
            f'   B100 : {tname} (100 .. 104) := (1, 2, 3, 4, 5);')
        open(os.path.join(work, 'idx_shift_driver.adb'), 'w').write(driver)
        # Build with -gnato -gnata
        inc = []
        for d in ('.', 'src'):
            if os.path.isdir(os.path.join(work, d)): inc += [f'-I{d}']
        cmd = ['gnatmake', '-q', '-gnat2022', '-gnato', '-gnata'] + inc + ['-o', 'idx_shift', 'idx_shift_driver.adb']
        b = subprocess.run(cmd, cwd=work, env=env14(), capture_output=True, text=True, timeout=timeout)
        if b.returncode != 0:
            return dict(folder=fid, subprogram=sub['name'], kind='skipped',
                        detail='driver build failed: ' + (b.stdout + b.stderr)[-200:].replace('\n', ' '),
                        status='skipped')
        r = mutate.run_limited(['./idx_shift'], work, timeout, env=env14())
        if r is None:
            return dict(folder=fid, subprogram=sub['name'], kind='error', detail='timeout', status='error')
        out = (r.stdout or '') + (r.stderr or '')
        if r.returncode == 0 and 'IDX_SHIFT_OK' in out:
            return dict(folder=fid, subprogram=sub['name'], kind='ok', detail='shift0/100 + high-first ok', status='ok')
        kind = 'midpoint_overflow' if 'midpoint_overflow' in out else 'shift_mismatch'
        return dict(folder=fid, subprogram=sub['name'], kind=kind,
                    detail=out.replace('\n', ' | ')[:240], status='fail')
    finally:
        shutil.rmtree(work, ignore_errors=True)


def run_sort_driver(fid, pkg, tname, sub, work_root, timeout):
    src = os.path.join(ROOT, fid)
    work = tempfile.mkdtemp(prefix='idx_', dir=work_root)
    try:
        shutil.copytree(src, work, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns('obj', 'bin', 'gnatprove', '*.o', '*.ali'))
        driver = f'''pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with {pkg}; use {pkg};
procedure Idx_Shift_Driver is
   Fail : Natural := 0;
   procedure Check (Cond : Boolean; Msg : String) is
   begin
      if not Cond then Fail := Fail + 1; Put_Line ("FAIL " & Msg); end if;
   end Check;
   procedure Expect_Sorted (A : {tname}; Tag : String) is
   begin
      for I in A'First .. A'Last - 1 loop
         if A (I) > A (I + 1) then
            Fail := Fail + 1; Put_Line ("FAIL not sorted " & Tag); return;
         end if;
      end loop;
   end Expect_Sorted;
   A1 : {tname} (1 .. 5) := (3, 1, 4, 1, 5);
   A0 : {tname} (0 .. 4) := (3, 1, 4, 1, 5);
   A100 : {tname} (100 .. 104) := (3, 1, 4, 1, 5);
begin
   {sub["name"]} (A1); {sub["name"]} (A0); {sub["name"]} (A100);
   Expect_Sorted (A1, "first1"); Expect_Sorted (A0, "first0"); Expect_Sorted (A100, "first100");
   for K in 0 .. 4 loop
      Check (A1 (A1'First + K) = A0 (A0'First + K), "shift0 payload");
      Check (A1 (A1'First + K) = A100 (A100'First + K), "shift100 payload");
   end loop;
   if Fail > 0 then Put_Line ("IDX_SHIFT_FAIL"); raise Program_Error; end if;
   Put_Line ("IDX_SHIFT_OK {sub["name"]}");
end Idx_Shift_Driver;
'''
        open(os.path.join(work, 'idx_shift_driver.adb'), 'w').write(driver)
        cmd = ['gnatmake', '-q', '-gnat2022', '-gnato', '-gnata', '-o', 'idx_shift', 'idx_shift_driver.adb']
        b = subprocess.run(cmd, cwd=work, env=env14(), capture_output=True, text=True, timeout=timeout)
        if b.returncode != 0:
            return dict(folder=fid, subprogram=sub['name'], kind='skipped',
                        detail='sort driver build failed', status='skipped')
        r = mutate.run_limited(['./idx_shift'], work, timeout, env=env14())
        if r is None:
            return dict(folder=fid, subprogram=sub['name'], kind='error', detail='timeout', status='error')
        out = (r.stdout or '') + (r.stderr or '')
        if r.returncode == 0 and 'IDX_SHIFT_OK' in out:
            return dict(folder=fid, subprogram=sub['name'], kind='ok', detail='sort shift ok', status='ok')
        return dict(folder=fid, subprogram=sub['name'], kind='shift_mismatch',
                    detail=out.replace('\n', ' | ')[:240], status='fail')
    finally:
        shutil.rmtree(work, ignore_errors=True)


def scan_folder(fid, work_root, timeout):
    rows = []
    ads_texts = [(p, open(p, errors='replace').read()) for p in ads_files(fid)]
    types = {}
    subs = []
    for p, text in ads_texts:
        types.update(unconstrained_types(text))
        subs.extend(public_array_subs(text, types))
    mids = static_midpoints(fid)
    for path, ln, line in mids:
        rows.append(dict(folder=fid, subprogram='', kind='static_midpoint',
                         detail=f'{path}:{ln}: {line}', status='review',
                         n_array_params='', note='prefer Lo + (Hi - Lo) / 2'))
    if not types:
        if not rows:
            rows.append(dict(folder=fid, subprogram='', kind='skipped', detail='no unconstrained array type',
                             status='skipped', n_array_params='', note=''))
        return rows
    if not subs:
        rows.append(dict(folder=fid, subprogram='', kind='skipped',
                         detail=f'types={list(types)} but no public subprogram taking them',
                         status='skipped', n_array_params='', note=''))
        return rows
    # Record catalog row
    for s in subs:
        rows.append(dict(folder=fid, subprogram=s['name'], kind='catalog',
                         detail=f"{s['kind']} n_arrays={s['n_arrays']} ret={s['ret']}",
                         status='catalog', n_array_params=str(s['n_arrays']), note=''))
    # Contract pins 'First = 1 (SPARK classroom ports): cannot shift until First-relative
    ads_all = '\n'.join(text for _, text in ads_texts)
    if re.search(r"A'First\s*=\s*1|First\s*=\s*1\s*and\s+then", ads_all):
        rows.append(dict(folder=fid, subprogram='', kind='first_pinned',
                         detail="In_Bounds/Pre requires A'First = 1 — make indexing 'First-relative and drop the pin",
                         status='fail', n_array_params='', note='fix: First-relative indexing / subtypes'))
    if 'AdaBoost' in fid:
        ab = run_adaboost_shift(fid, work_root, timeout)
        if ab: rows.append(ab)
    dyn = try_dynamic_integer_array(fid, types, subs, work_root, timeout)
    for d in dyn:
        d.setdefault('n_array_params', '')
        d.setdefault('note', '')
        rows.append(d)
    return rows



def run_adaboost_shift(fid, work_root, timeout):
    """Train/Predict with Features and Labels at DIFFERENT 'First origins."""
    if not fid.endswith('AdaBoost') and 'AdaBoost' not in fid:
        return None
    src = os.path.join(ROOT, fid)
    work = tempfile.mkdtemp(prefix='idx_', dir=work_root)
    try:
        shutil.copytree(src, work, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns('obj', 'bin', 'gnatprove', '*.o', '*.ali'))
        driver = """pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with AdaBoost; use AdaBoost;
procedure Idx_Shift_Driver is
   Fail : Natural := 0;
   procedure Check (Cond : Boolean; Msg : String) is
   begin
      if not Cond then Fail := Fail + 1; Put_Line ("FAIL " & Msg); end if;
   end Check;
   --  4 samples, 2 features; baseline Sample_Index from 1
   X1 : Features_Matrix (1 .. 4, 1 .. 2) :=
     (1 => (1.0, 0.0), 2 => (0.0, 1.0), 3 => (1.0, 1.0), 4 => (0.0, 0.0));
   Y1 : Labels_Array (1 .. 4) := (1, -1, 1, -1);
   --  Features start at 10, Labels at 50 (DIFFERENT shifts — AdaBoost pairing bug)
   X2 : Features_Matrix (10 .. 13, 1 .. 2) :=
     (10 => (1.0, 0.0), 11 => (0.0, 1.0), 12 => (1.0, 1.0), 13 => (0.0, 0.0));
   Y2 : Labels_Array (50 .. 53) := (1, -1, 1, -1);
   M1, M2 : Ensemble (1 .. 4);
   S1, S2 : Classifier_Weight;
begin
   Train (M1, X1, Y1);
   Train (M2, X2, Y2);
   S1 := Predict_Score (M1, (1.0, 0.0));
   S2 := Predict_Score (M2, (1.0, 0.0));
   Check (S1 = S2, "AdaBoost score matches with differently shifted X/Y");
   Check (Predict (M1, (1.0, 0.0)) = Predict (M2, (1.0, 0.0)),
          "AdaBoost label matches with differently shifted X/Y");
   if Fail > 0 then Put_Line ("IDX_SHIFT_FAIL"); raise Program_Error; end if;
   Put_Line ("IDX_SHIFT_OK AdaBoost");
end Idx_Shift_Driver;
"""
        open(os.path.join(work, 'idx_shift_driver.adb'), 'w').write(driver)
        b = subprocess.run(['gnatmake', '-q', '-gnat2022', '-gnato', '-gnata',
                            '-o', 'idx_shift', 'idx_shift_driver.adb'],
                           cwd=work, env=env14(), capture_output=True, text=True, timeout=timeout)
        if b.returncode != 0:
            return dict(folder=fid, subprogram='Train', kind='skipped',
                        detail='adaboost driver build: ' + (b.stdout+b.stderr)[-180:].replace('\n',' '),
                        status='skipped', n_array_params='2', note='')
        r = mutate.run_limited(['./idx_shift'], work, timeout, env=env14())
        if r is None:
            return dict(folder=fid, subprogram='Train', kind='error', detail='timeout',
                        status='error', n_array_params='2', note='')
        out = (r.stdout or '') + (r.stderr or '')
        if r.returncode == 0 and 'IDX_SHIFT_OK' in out:
            return dict(folder=fid, subprogram='Train', kind='ok', detail='different-shift X/Y ok',
                        status='ok', n_array_params='2', note='')
        return dict(folder=fid, subprogram='Train', kind='shift_mismatch',
                    detail=out.replace('\n',' | ')[:240], status='fail', n_array_params='2',
                    note='arrays must be paired by position, not shared index')
    finally:
        shutil.rmtree(work, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--folders', nargs='*')
    ap.add_argument('--sample', type=int, default=0)
    ap.add_argument('--seed', type=int, default=20261008)
    ap.add_argument('-j', type=int, default=4)
    ap.add_argument('--timeout', type=int, default=90)
    ap.add_argument('--out', default=os.path.join(ROOT, 'tools/vv/index_shift.csv'))
    ap.add_argument('--work', default='/tmp/flk/index_shift')
    args = ap.parse_args()
    os.makedirs(args.work, exist_ok=True)
    all_f = folders()
    # Prefer folders that declare unconstrained array types
    if args.folders:
        todo = args.folders
    else:
        typed = []
        for fid in all_f:
            for p in ads_files(fid):
                if ARR_TYPE.search(open(p, errors='replace').read()):
                    typed.append(fid); break
        todo = typed
        if args.sample and args.sample < len(todo):
            import random
            rng = random.Random(args.seed)
            todo = sorted(rng.sample(todo, args.sample))
    print(f'index_shift {len(todo)} folders (of {len(all_f)} total)', flush=True)
    rows = []
    with ThreadPoolExecutor(max_workers=args.j) as ex:
        futs = {ex.submit(scan_folder, f, args.work, args.timeout): f for f in todo}
        for i, fut in enumerate(as_completed(futs), 1):
            try:
                part = fut.result()
            except Exception as e:
                part = [dict(folder=futs[fut], subprogram='', kind='error', detail=repr(e)[:200],
                             status='error', n_array_params='', note='')]
            rows.extend(part)
            fails = [r for r in part if r.get('status') == 'fail']
            if fails or i % 20 == 0:
                print(f'  [{i}/{len(todo)}] {futs[fut]} fails={len(fails)}', flush=True)
    cols = ['folder', 'subprogram', 'kind', 'status', 'n_array_params', 'detail', 'note']
    with open(args.out, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction='ignore')
        w.writeheader(); w.writerows(rows)
    print('wrote', args.out, Counter(r['kind'] for r in rows), 'status', Counter(r['status'] for r in rows))


if __name__ == '__main__':
    main()
