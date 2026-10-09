#!/usr/bin/env python3
"""Calibration of the score138 hidden sets (agent-S138, 2026-10-09). DIAGNOSTIC ONLY.

1. Thinned tests: a scratch copy (mktemp) of the folder's test programs (tests*.adb,
   own_checks*.adb, tests/*.adb) in which every test case keeps only its FIRST check:
   * a run of consecutive check statements (pragma Assert, Assert / Check* / Report* / Expect*
     calls, `if <cond> then <fail>; end if;` with fail = raise / Failures := Failures + 1 /
     Ok := False / a FAIL Put_Line), separated only by blank or comment lines, is one test case:
     the first statement stays, the others become `null;` (`pragma Assert (True);` for pragmas);
   * inside the kept check only the first conjunct stays: first operand of a top-level
     `and then` / `and` in an assert or Report condition, first operand of a top-level
     `or else` / `or` in an `if ... then <fail>` condition.
   A check inside a loop is one check per iteration: loops are not cut, so exhaustive / random
   own-check loops keep their single property check.  The thinned copy is never committed.
2. Kill mode of every hidden kill, from a rerun with the full tests (output captured):
   test_check (a FAIL line, or an assertion / Program_Error raised from a test program),
   contract (Pre / Post / Assert / invariant failure inside library code, -gnata),
   runtime_error (Constraint_Error, other exceptions, non-zero exit without a test failure),
   uninit (Initialize_Scalars + -gnatVa rerun), proof (recorded proof kill).
The mutant set is the sealed hidden set of the record (same edits, no reseed, no new draws);
'equivalent' and 'unspecified output' survivors are left out as in the primary k/n.

usage: score138_thin.py FOLDER... [--thin] [-j 3] --out CSV_DETAIL
Private run files: same directory as score138.py (AA_S138_PRIVATE).
"""
import argparse, csv, json, os, re, shutil, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mutate, sweep_mutate as sm, score138_record as rec

ROOT = sm.ROOT
CHECK_CALL = re.compile(r'^\s*(pragma\s+Assert\b|(Ada\.Assertions\.)?Assert\s*\(|Check\w*\s*\(|Report\w*\s*\(|Expect\w*\s*\()', re.I)
SUMMARY_COND = re.compile(r'\b(Failures|Fail_Count|Failed|Errors|Bad|Not\s+Ok|not\s+All_Ok)\b', re.I)
FAIL_BODY = re.compile(r'^\s*(raise\b|Failures\s*:=|Fail_Count\s*:=|Errors\s*:=|Ok\s*:=\s*False|(Ada\.Text_IO\.)?Put_Line\s*\(\s*"[^"]*FAIL)', re.I)
TEST_FILE = re.compile(r'^(tests?|own_checks)\w*\.adb$', re.I)


def stmt_end(lines, i):
    """index of the line holding the ';' that ends the statement starting at line i (paren depth 0)."""
    depth = 0
    for j in range(i, len(lines)):
        code = re.sub(r'"[^"]*"', '""', lines[j].split('--')[0])
        for ch in code:
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
            elif ch == ';' and depth == 0:
                return j
    return i


def if_fail_end(lines, i):
    """if line i starts `if <cond> then` and the body (up to the matching end if) only fails, return the end line."""
    if not re.match(r'^\s*if\b', lines[i], re.I):
        return None
    depth, body, j = 0, [], i
    while j < len(lines):
        code = lines[j].split('--')[0]
        if re.match(r'^\s*(if)\b', code, re.I):
            depth += 1
        if re.search(r'\bend\s+if\s*;', code, re.I):
            depth -= 1
            if depth == 0:
                break
        if j > i:
            body.append(code)
        j += 1
    if j >= len(lines):
        return None
    stmts = [b for b in body if b.strip()]
    if not stmts or any(re.match(r'^\s*(elsif|else)\b', b, re.I) for b in stmts):
        return None
    joined = '\n'.join(lines[i:j + 1])
    if ' then' not in joined.lower():
        return None
    # body lines after the 'then' line
    after = []
    seen_then = False
    for b in [l.split('--')[0] for l in lines[i:j]]:
        if seen_then:
            after.append(b)
        if re.search(r'\bthen\b', b, re.I):
            seen_then = True
    after = [a for a in after if a.strip()]
    if not after or not all(FAIL_BODY.match(a) or re.match(r'^\s*(Put_Line|Ada\.Text_IO\.Put_Line|Put)\b', a, re.I) or
                            re.match(r'^\s*(\w+\s*=>|&|\))', a.strip()) or not re.match(r'^\s*\w', a) for a in after):
        return None
    if not any(FAIL_BODY.match(a) for a in after):
        return None
    parts = if_condition(joined)
    if parts and SUMMARY_COND.search(parts[1]):
        return None   # the final `if Failures > 0 then raise` summary is the harness, not a check
    return j


def split_top(expr, ops):
    """split expr at top-level occurrences of the words in ops (in order of preference)."""
    for op in ops:
        depth, parts, last, k = 0, [], 0, 0
        low = expr.lower()
        while k < len(expr):
            ch = expr[k]
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
            elif ch == '"':
                k = expr.index('"', k + 1)
            elif depth == 0 and low.startswith(op, k) and (not op[0].isalpha() or k == 0 or not (expr[k - 1].isalnum() or expr[k - 1] == '_')) \
                    and (not op[-1].isalpha() or k + len(op) >= len(expr) or not (expr[k + len(op)].isalnum() or expr[k + len(op)] == '_')):
                if op == ' and' or op == ' or':
                    nxt = low[k + len(op):].lstrip()
                    if nxt.startswith('then') or nxt.startswith('else'):
                        k += 1; continue
                parts.append(expr[last:k]); last = k + len(op)
            k += 1
        if parts:
            parts.append(expr[last:])
            return [p.strip() for p in parts]
    return [expr.strip()]


def first_conjunct_assert(text):
    """text of one check statement; keep the first conjunct of its condition (first argument)."""
    m = re.match(r'^(\s*(?:pragma\s+Assert|(?:Ada\.Assertions\.)?Assert|Check\w*|Report\w*|Expect\w*)\s*\()(.*)\)\s*;\s*$', text, re.I | re.S)
    if not m:
        return text, False
    head, inner = m.group(1), m.group(2)
    args = split_top(inner, [','])
    if not args:
        return text, False
    conj = split_top(args[0], [' and then', ' and'])
    if len(conj) < 2:
        return text, False
    return head + conj[0] + (', ' + ', '.join(args[1:]) if len(args) > 1 else '') + ');', True


def if_condition(text):
    """split `if <cond> then <rest>` at the top-level `then` that is not part of `and then`."""
    m = re.match(r'^(\s*if\s+)', text, re.I)
    if not m:
        return None
    k, depth, low = m.end(), 0, text.lower()
    while k < len(text):
        ch = text[k]
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
        elif ch == '"':
            k = text.index('"', k + 1)
        elif depth == 0 and low.startswith('then', k) and not (text[k - 1].isalnum() or text[k - 1] == '_') \
                and (k + 4 >= len(text) or not (text[k + 4].isalnum() or text[k + 4] == '_')) \
                and not re.search(r'\band\s*$', low[:k]):
            return m.group(1), text[m.end():k], text[k:]
        k += 1
    return None


def first_disjunct_if(text):
    parts = if_condition(text)
    if not parts:
        return text, False
    head, cond, rest = parts
    disj = split_top(cond.rstrip(), [' or else', ' or'])
    if len(disj) < 2:
        return text, False
    return head + disj[0] + ' ' + rest, True


def thin_file(path):
    lines = open(path, errors='replace').read().split('\n')
    out, i, prev_check, kept, dropped, narrowed = [], 0, False, 0, 0, 0
    while i < len(lines):
        code = lines[i].split('--')[0]
        if not code.strip():
            out.append(lines[i]); i += 1; continue
        end, kind = None, None
        if CHECK_CALL.match(code):
            end, kind = stmt_end(lines, i), 'call'
        else:
            e = if_fail_end(lines, i)
            if e is not None:
                end, kind = e, 'if'
        if end is None:
            out.append(lines[i]); prev_check = False; i += 1; continue
        text = '\n'.join(lines[i:end + 1])
        indent = re.match(r'^\s*', lines[i]).group(0)
        if prev_check:
            rep = indent + ('pragma Assert (True);' if re.match(r'^\s*pragma', code, re.I) else 'null;')
            out += [rep + '   --  thinned'] + [''] * (end - i)
            dropped += 1
        else:
            if kind == 'call':
                new, ch = first_conjunct_assert(text)
            else:
                new, ch = first_disjunct_if(text)
            narrowed += ch
            nl = new.split('\n')
            out += nl + [''] * ((end - i + 1) - len(nl))
            kept += 1
        prev_check = True
        i = end + 1
    open(path, 'w').write('\n'.join(out))
    return kept, dropped, narrowed


def thinned_copy(fid):
    d = tempfile.mkdtemp(prefix='s138_thin_')
    shutil.copytree(os.path.join(ROOT, fid), os.path.join(d, 'src'), ignore=sm.IGN)
    stats = {}
    for dp, dirs, fs in os.walk(os.path.join(d, 'src')):
        for f in fs:
            rel = os.path.relpath(os.path.join(dp, f), os.path.join(d, 'src'))
            if TEST_FILE.match(f) or (rel.startswith('tests' + os.sep) and f.endswith('.adb')):
                stats[rel] = thin_file(os.path.join(dp, f))
    return os.path.join(d, 'src'), stats


def run_capture(work):
    main = next((m for m in ('tests.adb', 'tests/main.adb', 'src/tests.adb') if os.path.exists(os.path.join(work, m))), None)
    os.makedirs(os.path.join(work, 'obj'), exist_ok=True)
    inc = [f'-I{d}' for d in ('src', 'tests') if os.path.isdir(os.path.join(work, d))]
    b = subprocess.run([sm.GNATMAKE, '-q', '-gnat2022', '-gnata', *inc, '-D', 'obj', main, '-o', 'tbin'], cwd=work, capture_output=True, text=True)
    if b.returncode != 0:
        return 'stillborn', ''
    r = mutate.run_limited(['./tbin'], work, 30)
    if r is None:
        return 'timeout', ''
    out = r.stdout + r.stderr
    fails = [l for l in out.split('\n') if sm.FAIL_LINE.search(l) and not sm.ZERO_FAIL.search(l)]
    if r.returncode != 0 or fails:
        return 'killed', out
    return 'survived', out


def mode_of(out):
    fails = [l for l in out.split('\n') if sm.FAIL_LINE.search(l) and not sm.ZERO_FAIL.search(l)]
    m = re.search(r'raised\s+([\w.]+)\s*:?\s*(.*)', out)
    exc, msg = (m.group(1).upper(), m.group(2)) if m else ('', '')
    if fails:
        return 'test_check'
    if 'ASSERTION_ERROR' in exc or exc == 'PROGRAM_ERROR':
        if re.search(r'precondition|postcondition|invariant', msg, re.I):
            return 'contract'
        loc = re.search(r'([\w-]+\.ad[bs]):\d+', msg)
        if loc and not TEST_FILE.match(loc.group(1)):
            return 'contract' if 'ASSERTION_ERROR' in exc else 'runtime_error'
        return 'test_check'
    return 'runtime_error'


def one(args):
    src, w, m = args
    shutil.rmtree(w, ignore_errors=True); shutil.copytree(src, w, ignore=sm.IGN)
    for rel, ln, c0, c1, rep in m['edits']:
        p = os.path.join(w, rel); L = open(p, errors='replace').read().split('\n')
        L[ln] = L[ln][:c0] + rep + L[ln][c1:]; open(p, 'w').write('\n'.join(L))
    res, out = run_capture(w)
    kk = ''
    if res == 'survived':
        ck = mutate.recheck_uninit(w, m['op'], m['after'])
        if ck:
            res, kk = ck
    shutil.rmtree(w, ignore_errors=True)
    return res, (kk or (mode_of(out) if res == 'killed' else ''))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('folders', nargs='+'); ap.add_argument('--thin', action='store_true')
    ap.add_argument('-j', type=int, default=3); ap.add_argument('--out', required=True)
    a = ap.parse_args()
    mutate.require_version(14)
    eq = {}
    for r in csv.DictReader(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'score138_equivalent.csv'))):
        if r['half'] == 'held':
            eq.setdefault(r['folder'], set()).add(int(r['index']))
    rows = []
    for fid in a.folders:
        held = rec.load(fid, 'held')
        full_src = os.path.join(ROOT, fid)
        variants = [('full', full_src, {})]
        if a.thin:
            tsrc, stats = thinned_copy(fid)
            variants.append(('thinned', tsrc, stats))
            print(fid, 'thinning (kept, dropped, narrowed):', stats, flush=True)
        ms = [(i, m) for i, m in enumerate(held['mutants']) if m['result'] != 'stillborn' and i not in eq.get(fid, set())]
        for name, src, stats in variants:
            wk = tempfile.mkdtemp(prefix='s138_cal_')
            shutil.copytree(src, wk + '/base', ignore=sm.IGN)
            base, _ = run_capture(wk + '/base')
            if base != 'survived':
                print(f'{fid} {name}: baseline {base}; variant skipped', flush=True)
                rows.append(dict(folder=fid, variant=name, index='', family='', recorded='', recorded_kill_kind='',
                                 tests_result='baseline ' + base, mode='', thin_stats=json.dumps(stats)))
                continue
            with ThreadPoolExecutor(a.j) as ex:
                res = list(ex.map(one, [(src, f'{wk}/m{i}', m) for i, m in ms]))
            shutil.rmtree(wk, ignore_errors=True)
            for (i, m), (r, mode) in zip(ms, res):
                rows.append(dict(folder=fid, variant=name, index=i, family=m['family'], recorded=m['result'],
                                 recorded_kill_kind=m.get('kill_kind') or '', tests_result=r, mode=mode,
                                 thin_stats=json.dumps(stats) if name == 'thinned' else ''))
            k = sum(r == 'killed' for r, _ in res)
            print(f'{fid} {name}: tests-only {k}/{len(ms)}', flush=True)
    with open(a.out, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]), lineterminator='\n'); w.writeheader(); w.writerows(rows)


if __name__ == '__main__':
    main()
