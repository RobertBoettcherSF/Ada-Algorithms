#!/usr/bin/env python3
# DRAFT (2026-10-09): written but never run to completion; validate per handover row H164 before trusting results.
"""Classify clamp_scan hits by experiment (docs/VV.md, "Clamp classification").

For each hit, in a scratch copy (mktemp; nothing is committed):
 (a) dead?   put an assertion that the clamp branch is never taken
             (pragma Assert (False) inside a return/assign arm, pragma Assert (COND)
             before a guarded increment, pragma Assert (A <= B) before T'Min (A, B)),
             prove with the canonical settings.  Proves -> reachable=no (dead).
             Not proved is NOT evidence of reachability (prover limits), so:
     taken?  instrument the branch with a marker line and run the folder's tests.
             Marker printed -> reachable; else reachable=unknown.
 (b) only if reachable: remove the branch (arm statement -> null, guard -> True,
             T'Min (A, B) -> A), rerun prover and tests.  Nothing fails ->
             reachable=silent (silent fallback).  Something fails -> reachable=yes
             (the bound is observable: honest bounded code).
Only reachable=yes passes the strict-rule clamp item; no / unknown / silent are held out.
Results go to tools/vv/clamp_review.csv (method column = this script + evidence).

usage: clamp_classify.py [--counted] [--folder F ...] [--dry]
"""
import argparse, csv, io, os, re, shutil, subprocess, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from score138_prove import ROOT, GP, GB, UNPROVED, gpr_of, limit

SCAN = os.path.join(ROOT, 'tools', 'vv', 'clamp_scan.csv')
REVIEW = os.path.join(ROOT, 'tools', 'vv', 'clamp_review.csv')
FIELDS = ['folder', 'file_line', 'reachable', 'evidence', 'reviewed_by', 'method']
MARK = 'AA_CLAMP_TAKEN'
GUARD = re.compile(r'^(\s*)(if|elsif)\s+(.*?)\s+then\b(.*)$', re.I)
MINMAX = re.compile(r"\b(\w+(?:\.\w+)*)'(Min|Max)\s*\(", re.I)


def split_args(s, i):
    """s[i] is '(' ; return (a, b, end) for a two-argument call."""
    depth, parts, cur = 0, [], ''
    for j in range(i, len(s)):
        c = s[j]
        if c == '(':
            depth += 1
            if depth == 1:
                continue
        elif c == ')':
            depth -= 1
            if depth == 0:
                parts.append(cur)
                return (parts[0].strip(), parts[1].strip(), j) if len(parts) == 2 else None
        elif c == ',' and depth == 1:
            parts.append(cur); cur = ''; continue
        cur += c
    return None


def plan(kind, line):
    """Return dict(assert_, mark, remove) as functions of the source line list and index, or None."""
    m = GUARD.match(line)
    if kind == 'guarded_increment' and m:
        ind, kw, cond, rest = m.groups()
        def a(L, i): L.insert(i, f'{ind}pragma Assert ({cond});') if kw.lower() == 'if' else None; return kw.lower() == 'if'
        def k(L, i): L.insert(i, f'{ind}if not ({cond}) then Ada.Text_IO.Put_Line ("{MARK}"); end if;') ; return kw.lower() == 'if'
        def r(L, i): L[i] = f'{ind}{kw} True then{rest}'; return True
        return a, k, r
    mm = MINMAX.search(line)
    if kind == 'min_max_clip' and mm:
        args = split_args(line, mm.end() - 1)
        if not args:
            return None
        A, B, end = args
        op = '<=' if mm.group(2).lower() == 'min' else '>='
        ind = re.match(r'\s*', line).group(0)
        def a(L, i): L.insert(i, f'{ind}pragma Assert ({A} {op} {B});'); return True
        def k(L, i): L.insert(i, f'{ind}if not ({A} {op} {B}) then Ada.Text_IO.Put_Line ("{MARK}"); end if;'); return True
        def r(L, i): L[i] = line[:mm.start()] + f'({A})' + line[end + 1:]; return True
        return a, k, r
    if kind in ('attr_return', 'const_return'):
        ind = re.match(r'\s*', line).group(0)
        st = re.match(r'\s*(?:(?:if|elsif)\s+.*?\s+then\s+|else\s+)?(.*;)\s*(?:--.*)?$', line, re.I)
        if not st or not re.match(r'(return\b|[\w.()]+\s*:=)', st.group(1), re.I):
            return None
        stmt = st.group(1)
        head = line[:line.index(stmt)]
        def a(L, i): L[i] = head + 'pragma Assert (False); ' + stmt if head.strip() else f'{ind}pragma Assert (False);\n{line}'; return True
        def k(L, i): L[i] = head + f'Ada.Text_IO.Put_Line ("{MARK}"); ' + stmt if head.strip() else f'{ind}Ada.Text_IO.Put_Line ("{MARK}");\n{line}'; return True
        def r(L, i): L[i] = head + 'null;' if head.strip() else f'{ind}null;'; return True
        return a, k, r
    return None


def scratch(fid, rel, ln, fn, with_io=False):
    d = tempfile.mkdtemp(prefix='clampc_')
    subprocess.run(f'git -C {ROOT} archive HEAD {fid} | tar -x -C {d}', shell=True, check=True)
    w = os.path.join(d, fid)
    p = os.path.join(w, rel)
    L = open(p, errors='replace').read().split('\n')
    if not fn(L, ln):
        shutil.rmtree(d); return None, None
    if with_io:
        b = next(j for j, l in enumerate(L) if re.match(r'\s*(private\s+)?package\s+body\b|\s*(procedure|function)\s', l, re.I))
        L.insert(b, 'with Ada.Text_IO;')
    open(p, 'w').write('\n'.join(L))
    return d, w


def prove(w, fid, cap):
    cmd = ['timeout', str(cap), os.path.join(GP, 'gnatprove'), '-P', gpr_of(fid), '-f', '--mode=silver', '--level=2',
           '--prover=cvc5,z3,altergo', '--timeout=0', '--steps=1000000', '--counterexamples=off',
           '--report=statistics', '--output=oneline', '-k', '-j2']
    r = subprocess.run(cmd, cwd=w, env=dict(os.environ, PATH=f'{GP}:{GB}:/usr/bin:/bin'),
                       capture_output=True, text=True, errors='replace', preexec_fn=limit)
    out = r.stdout + r.stderr
    if r.returncode == 124:
        return 'cap', f'prove wall cap {cap} s'
    bad = [l.strip() for l in out.splitlines() if UNPROVED.search(l)]
    if bad:
        return 'fail', bad[0][:200]
    return ('proved', 'all checks proved') if r.returncode == 0 else ('fail', (out.strip().splitlines() or [''])[-1][:200])


def test(w, cap):
    subprocess.run('rm -rf obj bin', shell=True, cwd=w)
    r = subprocess.run(f'timeout {cap} nice make test', shell=True, cwd=w, capture_output=True, text=True,
                       errors='replace')
    out = r.stdout + r.stderr
    ok = r.returncode == 0 and not re.search(r'^\s*FAIL\b', out, re.M)
    return ok, MARK in out, (out.strip().splitlines() or [''])[-1][:160]


def classify(fid, fl, kind, cap):
    rel, ln = fl.rsplit(':', 1); ln = int(ln) - 1
    line = open(os.path.join(ROOT, fid, rel), errors='replace').read().split('\n')[ln]
    p = plan(kind, line)
    if not p:
        return 'unknown', f'no automatic plan for kind {kind} on this line; needs manual review'
    a, k, r = p
    d, w = scratch(fid, rel, ln, a)
    if not w:
        return 'unknown', 'elsif guard: no single assertion point; needs manual review'
    st, why = prove(w, fid, cap); shutil.rmtree(d, ignore_errors=True)
    if st == 'proved':
        return 'no', '(a) assertion that the branch is never taken proves (Silver, canonical settings): dead'
    ev = f'(a) assertion not proved ({why})'
    d, w = scratch(fid, rel, ln, k, with_io=True)
    ok, taken, last = test(w, 1800); shutil.rmtree(d, ignore_errors=True)
    if not taken:
        return 'unknown', ev + f'; branch marker not printed by the tests (tests ok={ok}): reachability unknown'
    ev += '; branch taken by the tests (marker printed)'
    d, w = scratch(fid, rel, ln, r)
    ok, _, last = test(w, 1800)
    pst, pwhy = prove(w, fid, cap); shutil.rmtree(d, ignore_errors=True)
    if ok and pst == 'proved':
        return 'silent', ev + '; (b) branch removed: tests pass and proof passes: silent fallback'
    return 'yes', ev + f'; (b) branch removed: tests {"pass" if ok else "fail (" + last + ")"}, proof {pst}: the bound is observable'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--folder', action='append', default=[])
    ap.add_argument('--counted', action='store_true', help='all folders currently training_ready in PROOFS.csv')
    ap.add_argument('--cap', type=int, default=1200)
    ap.add_argument('--dry', action='store_true')
    a = ap.parse_args()
    folders = set(a.folder)
    if a.counted:
        folders |= {r['folder'] for r in csv.DictReader(open(os.path.join(ROOT, 'PROOFS.csv'))) if r.get('training_ready') == 'yes'}
    hits = [r for r in csv.DictReader(open(SCAN)) if r['folder'] in folders]
    raw = open(REVIEW, 'rb').read().decode()
    rows = list(csv.DictReader(io.StringIO(raw)))
    for r in rows:
        r.setdefault('method', None)
        if not r['method']:
            r['method'] = 'manual (reviewer reading + gcov where cited)'
    idx = {(r['folder'], r['file_line']): r for r in rows}
    for h in hits:
        if h['kind'] == 'saturating':      # helper header: its branches are separate hits
            res, ev = 'n/a', 'helper header; decided by its branch hits'
            if (h['folder'], h['file_line']) not in idx:
                continue
        else:
            res, ev = classify(h['folder'], h['file_line'], h['kind'], a.cap)
        print(f"{h['folder']} {h['file_line']} {h['kind']}: {res} - {ev}", flush=True)
        if a.dry:
            continue
        old = idx.get((h['folder'], h['file_line']))
        new = dict(folder=h['folder'], file_line=h['file_line'], reachable=res, evidence=ev,
                   reviewed_by='clamp_classify.py', method='clamp_classify v1 (assert-prove / marker-test / remove-branch)')
        if old:
            if old['evidence'] and old['reviewed_by'] != 'clamp_classify.py':
                new['evidence'] += ' | earlier manual: ' + old['evidence']
            old.update(new)
        else:
            rows.append(new); idx[(h['folder'], h['file_line'])] = new
        buf = io.StringIO()
        w = csv.DictWriter(buf, FIELDS, lineterminator='\r\n'); w.writeheader(); w.writerows(rows)
        open(REVIEW, 'wb').write(buf.getvalue().encode())


if __name__ == '__main__':
    main()
