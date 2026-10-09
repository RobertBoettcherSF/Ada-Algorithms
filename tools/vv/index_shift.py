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
  first_pinned       - contract/body requires A'First = 1 and no written
                       reason yet → still a fail. Prefer a subtype /
                       constrained array type; else Pre => A'First = 1
                       with a one-line reason in `note` (column fix_kind =
                       fixed_origin_type). No reason → do not mark fixed.
  fixed_origin_type  - intentional fixed origin: subtype/constrained type
                       and/or Pre => A'First = 1, with one-line `note`
                       reason (e.g. '1-based heap parent/child formulas').
                       Counts as index_independent once status=ok.
  ok                 - all dynamic checks passed (or fixed_origin accepted)
  static_midpoint    - source still contains (Lo+Hi)/2 style (review)
  skipped            - no runnable dynamic driver for this signature yet
  error              - build/run error unrelated to indexing

Refuse clamps, Bubble_Finish-style fallbacks, Warnings Off, silent
zero-fill of unread cells, epsilon tuned to one seed.

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

# Intentional fixed-origin folders (room recheck 2026-10-08):
# KEEP only Package-Merge (2*P packaging) and PGZ (degree index Poly(I)*I).
# Heapsort/Introsort/Smoothsort/Interpolation/KMP flipped to rewrite: offset
# heap / Lo+probe / prefix-as-offset. Prefer subtype on remaining keeps.
FIXED_ORIGIN_REASONS: dict[str, str] = {
    'misc/SPARK4/Ada-SPARK-Package-Merge-Algorithm':
        'index arithmetic: package-merge pairs at 2*P-1 / 2*P (room recheck KEEP)',
    'compression/Ada/Peterson-Gorenstein-Zierler-Algorithm':
        'index arithmetic: coefficient index is the degree (Derivative Poly(I)*I); subtype Degree_Poly First=0 (room recheck KEEP)',
}


# Room decision ledger for the 90 folders that were fixed_origin_type before
# the mechanical test: keep (index arithmetic, reason) or rewrite (First-relative).
DECISIONS_TSV = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                             'fixed_origin_decisions.tsv')


def load_decisions():
    out = {}
    if os.path.exists(DECISIONS_TSV):
        for r in csv.DictReader(open(DECISIONS_TSV), delimiter='\t'):
            out[r['folder']] = (r['decision'], r['reason'])
    return out


DECISIONS = load_decisions()


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



def index_bounds(tname, ads_text):
    """(low, high) of the index subtype of unconstrained array type tname; None if unknown."""
    m = re.search(rf'type\s+{re.escape(tname)}\s+is\s+array\s*\(\s*([\w.]+)\s+range\s*<>', ads_text, re.I)
    if not m:
        return None, None
    ix = m.group(1).split('.')[-1]
    std = {'natural': (0, None), 'integer': (None, None), 'positive': (1, None)}
    if ix.lower() in std:
        return std[ix.lower()]
    consts = {c.group(1): int(c.group(2).replace('_', ''))
              for c in re.finditer(r'(\w+)\s*:\s*constant(?:\s+\w+)?\s*:=\s*([\d_]+)\s*;', ads_text)}
    def val(s):
        s = s.strip()
        if re.fullmatch(r'[\d_]+', s): return int(s.replace('_', ''))
        if s in consts: return consts[s]
        mm = re.fullmatch(r'(\w+)\s*([+-])\s*(\d+)', s)
        if mm and mm.group(1) in consts:
            return consts[mm.group(1)] + (int(mm.group(3)) if mm.group(2) == '+' else -int(mm.group(3)))
        return None
    d = re.search(rf'(?:sub)?type\s+{re.escape(ix)}\s+is\s+(?:new\s+)?(?:[\w.]+\s+)?range\s+(.+?)\s*\.\.\s*(.+?)\s*;',
                  ads_text, re.I)
    if not d:
        return None, None
    return val(d.group(1)), val(d.group(2))


def origins_for(low, high):
    """Two non-baseline origins and a high-first origin that fit the index subtype."""
    lo = 0 if low is None else low
    o_a = lo if lo != 1 else 2           # shift by one when 0 is not in the subtype
    o_b = 100 if (high is None or high >= 104) and lo <= 100 else None
    hi_first = 10_000
    if high is not None:
        hi_first = high - 64 if high - 64 > max(lo, 1) + 5 else None
    return o_a, o_b, hi_first

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


VALUE_API = re.compile(r'select|kth|median|minimum|maximum|^min$|^max$|value', re.I)
SUCCESSOR_API = re.compile(r'cycle_(length|start)|^(mu|lambda)$', re.I)


def _build_and_run(fid, work, driver, timeout):
    open(os.path.join(work, 'idx_shift_driver.adb'), 'w').write(driver)
    inc = []
    for d in ('.', 'src'):
        if os.path.isdir(os.path.join(work, d)): inc += [f'-I{d}']
    cmd = ['gnatmake', '-q', '-gnat2022', '-gnato', '-gnata'] + inc + ['-o', 'idx_shift', 'idx_shift_driver.adb']
    b = subprocess.run(cmd, cwd=work, env=env14(), capture_output=True, text=True, timeout=timeout)
    if b.returncode != 0:
        return None, 'driver build failed: ' + (b.stdout + b.stderr)[-200:].replace('\n', ' ')
    r = mutate.run_limited(['./idx_shift'], work, timeout, env=env14())
    if r is None:
        return 'timeout', ''
    return r, (r.stdout or '') + (r.stderr or '')


def run_find_driver(fid, pkg, tname, sub, work_root, timeout):
    """Baseline First=1 vs two other origins that fit the index subtype, plus a
    high-'First probe for midpoint overflow.  Index-returning APIs must agree on
    Result - A'First; value-returning APIs (Select_Kth, Median, ...) must agree
    on the value.  Successor maps (Cycle_Length (Next, Start)) are vertex-id keyed:
    the shifted copy relabels ids (indices AND values) and must give the same answer."""
    src = os.path.join(ROOT, fid)
    work = tempfile.mkdtemp(prefix='idx_', dir=work_root)
    try:
        shutil.copytree(src, work, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns('obj', 'bin', 'gnatprove', '*.o', '*.ali'))
        ads_all = '\n'.join(open(a, errors='replace').read() for a in ads_files(fid))
        low, high = index_bounds(tname, ads_all)
        o_a, o_b, hi_first = origins_for(low, high)
        name = sub['name']
        if SUCCESSOR_API.search(name):
            # functional graph 1->2->3->4->5->3 : tail 2, cycle length 3
            shifts = [o for o in (o_a, o_b) if o is not None and o != 1]
            decls, calls, checks = [], [], []
            # Room-decision rewrite folders use position labels: node k lives at
            # Next'First + k - 1, so values / Start stay 1 .. N at any origin.
            # Otherwise ids are the array indexes and relabel with the origin.
            pos_labels = DECISIONS.get(fid, ('', ''))[0] == 'rewrite'
            for k, o in enumerate(shifts):
                d = 0 if pos_labels else o - 1
                vals = ', '.join(str(v + d) for v in (2, 3, 4, 5, 3))
                decls.append(f'   M{k} : constant {tname} ({o} .. {o + 4}) := ({vals});')
                calls.append(f'   R{k} := Integer ({name} (M{k}, {1 + d}));')
                tag = 'position labels' if pos_labels else 'relabelled ids'
                checks.append(f'   Check (R{k} = RB, "{tag} from {o}");')
            driver = f"""pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with {pkg}; use {pkg};
procedure Idx_Shift_Driver is
   Fail : Natural := 0;
   procedure Check (Cond : Boolean; Msg : String) is
   begin
      if not Cond then Fail := Fail + 1; Put_Line ("FAIL " & Msg); end if;
   end Check;
   MB : constant {tname} (1 .. 5) := (2, 3, 4, 5, 3);
{chr(10).join(decls)}
   RB : Integer;
   {', '.join(f'R{k}' for k in range(len(shifts))) or 'Unused'} : Integer;
begin
   RB := Integer ({name} (MB, 1));
{chr(10).join(calls)}
{chr(10).join(checks)}
   if Fail > 0 then Put_Line ("IDX_SHIFT_FAIL" & Fail'Image); raise Program_Error; end if;
   Put_Line ("IDX_SHIFT_OK {name}");
end Idx_Shift_Driver;
"""
            mode = 'successor'
        else:
            value_api = bool(VALUE_API.search(name)) and \
                (sub['ret'] or '').split('.')[-1].lower() not in ('index', 'ext_index')
            # Second argument is itself an index into the array (Pre says
            # "<Param> in <Arr>'Range"): pass the 3rd slot, not the literal 3.
            spec = re.search(r'function\s+' + re.escape(name) + r'\b(.*?)\breturn\s+[\w.]+(.*?);',
                             ads_all, re.S | re.I)
            #  Only a formal parameter counts (not "Find'Result in A'Range" in a Post).
            formals = set()
            if spec:
                for grp in re.findall(r'([\w\s,]+):\s*(?:in\s+|out\s+|in\s+out\s+)?[\w.]+', spec.group(1)):
                    formals.update(n.strip().lower() for n in grp.replace('(', ' ').split(',') if n.strip())
            index_arg = bool(spec and any(
                m.group(1).lower() in formals
                for m in re.finditer(r"(?<!')\b(\w+)\s+in\s+\w+'Range", spec.group(2))))
            if index_arg and (sub['ret'] or '').split('.')[-1].lower() in ('natural', 'boolean', 'integer'):
                value_api = True  # a count / flag about that slot, not an index
            rel = '' if value_api else ' - {A}\'First'
            def cmp(a, b):
                return f'(R{a}{rel.format(A="B" + a)}) = (R{b}{rel.format(A="B" + b)})'
            origin_list = [('A', o_a)] + ([('C', o_b)] if o_b is not None else [])
            decls = '\n'.join(f'   B{n} : {tname} ({o} .. {o + 4}) := (1, 2, 3, 4, 5);' for n, o in origin_list)
            rdecl = ', '.join(f'R{n}' for n, _ in origin_list)
            k3 = (lambda arr: f"{arr}'First + 2") if index_arg else (lambda arr: '3')
            calls = '\n'.join(f'      R{n} := Integer ({name} (B{n}, {k3("B" + n)}));' for n, _ in origin_list)
            checks = '\n'.join(f'      Check ({cmp(n, "1")}, "origin {o} vs 1 for key 3");' for n, o in origin_list)
            hi_block = ''
            if hi_first is not None:
                hcmp = 'RH = RL' if value_api else "RH - Long'First = RL - Low1'First"
                hi_block = f"""   declare
      Low1 : {tname} (1 .. 65);
      Long : {tname} ({hi_first} .. {hi_first} + 64);
      RL, RH : Integer;
   begin
      for I in Low1'Range loop Low1 (I) := I - Low1'First{" + 1" if index_arg else ""}; end loop;
      for I in Long'Range loop Long (I) := I - Long'First{" + 1" if index_arg else ""}; end loop;
      RL := Integer ({name} (Low1, {"Low1'First + 31" if index_arg else "32"}));
      RH := Integer ({name} (Long, {"Long'First + 31" if index_arg else "32"}));
      Check ({hcmp}, "high-first {hi_first} agrees with First=1");
   exception
      when Constraint_Error =>
         Fail := Fail + 1; Put_Line ("FAIL midpoint_overflow Constraint_Error high-first");
      when others =>
         Fail := Fail + 1; Put_Line ("FAIL exception high-first");
   end;
"""
            driver = f"""pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with {pkg}; use {pkg};
procedure Idx_Shift_Driver is
   Fail : Natural := 0;
   procedure Check (Cond : Boolean; Msg : String) is
   begin
      if not Cond then Fail := Fail + 1; Put_Line ("FAIL " & Msg); end if;
   end Check;
   B1 : {tname} (1 .. 5) := (1, 2, 3, 4, 5);
{decls}
   R1, {rdecl} : Integer;
begin
   begin
      R1 := Integer ({name} (B1, {k3("B1")}));
{calls}
{checks}
   exception
      when others =>
         Fail := Fail + 1; Put_Line ("FAIL exception on shift compare");
   end;
{hi_block}   if Fail > 0 then
      Put_Line ("IDX_SHIFT_FAIL" & Fail'Image);
      raise Program_Error;
   end if;
   Put_Line ("IDX_SHIFT_OK {name}");
end Idx_Shift_Driver;
"""
            mode = 'value' if value_api else 'index'
        r, out = _build_and_run(fid, work, driver, timeout)
        if r is None:
            return dict(folder=fid, subprogram=name, kind='skipped', detail=out, status='skipped')
        if r == 'timeout':
            return dict(folder=fid, subprogram=name, kind='error', detail='timeout', status='error')
        origins = f'origins {o_a}/{o_b} high {hi_first} ({mode})'
        if r.returncode == 0 and 'IDX_SHIFT_OK' in out:
            return dict(folder=fid, subprogram=name, kind='ok', detail=origins + ' ok', status='ok')
        kind = 'midpoint_overflow' if 'midpoint_overflow' in out else 'shift_mismatch'
        return dict(folder=fid, subprogram=name, kind=kind,
                    detail=(origins + ' | ' + out.replace('\n', ' | '))[:240], status='fail')
    finally:
        shutil.rmtree(work, ignore_errors=True)


def run_sort_driver(fid, pkg, tname, sub, work_root, timeout):
    src = os.path.join(ROOT, fid)
    work = tempfile.mkdtemp(prefix='idx_', dir=work_root)
    ads_all = '\n'.join(open(a, errors='replace').read() for a in ads_files(fid))
    o_a, o_b, _ = origins_for(*index_bounds(tname, ads_all))
    if o_b is None:
        o_b = o_a + 1
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
   A0 : {tname} ({o_a} .. {o_a} + 4) := (3, 1, 4, 1, 5);
   A100 : {tname} ({o_b} .. {o_b} + 4) := (3, 1, 4, 1, 5);
begin
   {sub["name"]} (A1); {sub["name"]} (A0); {sub["name"]} (A100);
   Expect_Sorted (A1, "first1"); Expect_Sorted (A0, "origin a"); Expect_Sorted (A100, "origin b");
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
    # Contract pins 'First = 1: prefer subtype; Pre + one-line reason = fixed_origin_type.
    ads_all = '\n'.join(text for _, text in ads_texts)
    pinned = bool(re.search(r"A'First\s*=\s*1|First\s*=\s*1\s*and\s+then", ads_all))
    reason = FIXED_ORIGIN_REASONS.get(fid, '').strip()
    if reason:
        rows.append(dict(folder=fid, subprogram='', kind='fixed_origin_type',
                         detail=("Pre/In_Bounds pins A'First = 1" if pinned else "id-keyed index subtype")
                                + " (accepted fixed origin)",
                         status='ok', n_array_params='', note=reason,
                         fix_kind='fixed_origin_type'))
        # Skip origin-shift dynamic drivers for intentional 1-based APIs
        return rows
    decision = DECISIONS.get(fid, ('', ''))[0]
    if decision == 'rewrite' and not pinned:
        # Rewrite folders must also drop line-up pins (X'First = Y'First,
        # X'First (1) = X'First (2)) and literal origins ('First = 0/1).
        pinned = bool(re.search(
            r"'First\s*(?:\(\s*\d\s*\))?\s*(?:/=|=)\s*(?:\d+\b|[\w.]+'First)", ads_all))
    if pinned:
        rw = decision == 'rewrite'
        rows.append(dict(folder=fid, subprogram='', kind='first_pinned',
                         detail=("REWRITE: First-relative (indexes only walk/line-up)" if rw else
                                 "In_Bounds/Pre requires A'First = 1 — subtype/constrained type, "
                                 "or Pre + one-line reason (fix_kind=fixed_origin_type)"),
                         status='fail', n_array_params='',
                         note=('indexes only walk/line-up (room decision)' if rw else ''),
                         fix_kind=('rewrite_first_relative' if rw else '')))
    elif decision == 'rewrite':
        rows.append(dict(folder=fid, subprogram='', kind='first_relative',
                         detail='room decision rewrite: no First pin left; shifted-origin tests in suite',
                         status='ok', n_array_params='',
                         note='indexes only walk/line-up (room decision)',
                         fix_kind='rewritten_first_relative'))
    if 'AdaBoost' in fid:
        ab = run_adaboost_shift(fid, work_root, timeout)
        if ab: rows.append(ab)
    dyn = try_dynamic_integer_array(fid, types, subs, work_root, timeout)
    for d in dyn:
        d.setdefault('n_array_params', '')
        d.setdefault('note', '')
        d.setdefault('fix_kind', '')
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
    ap.add_argument('--work', default=os.path.join(tempfile.gettempdir(), 'flk', 'index_shift'))
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
    cols = ['folder', 'subprogram', 'kind', 'status', 'fix_kind', 'n_array_params', 'detail', 'note']
    if args.folders and os.path.exists(args.out):
        # Partial run: replace only the scanned folders' rows, keep the rest.
        done = set(todo)
        keep = [r for r in csv.DictReader(open(args.out)) if r['folder'] not in done]
        rows = keep + rows
    with open(args.out, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction='ignore')
        w.writeheader(); w.writerows(rows)
    print('wrote', args.out, Counter(r['kind'] for r in rows), 'status', Counter(r['status'] for r in rows))


if __name__ == '__main__':
    main()
