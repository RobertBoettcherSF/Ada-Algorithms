#!/usr/bin/env python3
"""FAIL-but-passes scan (static): can a failing check make `make test` fail?

1. Test drivers (tests.adb, test.adb, own_checks.adb, test_*.adb, tests_*.adb, run_*.adb) that print FAIL
   (a string literal containing FAIL) but contain no exit-status signal: Set_Exit_Status (... Failure),
   GNAT.OS_Lib.OS_Exit (non-zero), a raise statement, pragma Assert / Ada.Assertions.Assert. When the driver
   keeps a failure counter (X := X + 1 with Fail in the name), the signal must depend on that counter: an
   `if <counter> ...` block (to its `end if;` at the same indentation) that contains a signal, or
   Assert (<counter> = 0) (a call of a local procedure whose body signals counts as a signal); a raise or
   pragma Assert elsewhere in the file does not count. A procedure
   that hands its failure count to the caller (an `out` parameter, e.g. Own_Checks (Fail_Count : out
   Natural)) is the caller's job and is not flagged.
2. Makefile recipe lines that swallow an exit code: `|| true` / `|| :`, a leading '-' (ignore errors),
   or a pipe into tee without `set -o pipefail` / SHELLFLAGS with pipefail in that Makefile (continuation
   lines and clean / distclean recipes are skipped).
Static only: it does NOT see a handler that swallows a failure (`when others => Put_Line ("FAIL")`), a
signal on a path that never runs, or a pragma Assert compiled without -gnata. The real check is planting a
failure per folder (tools/vv/silent_fail.py --plant, or by hand); a folder this scan does not flag is
'scan-clean, not planted' unless a plant is recorded.
  python3 tools/vv/check_fail_exit.py [--root REPO] [--selftest]    (exit 0 = no hits / control passes)
"""
import argparse, os, re, sys
DRIVER = re.compile(r'^(tests?|own_checks|tests?_\w+|run_\w+)\.adb$', re.I)
FAIL_LIT = re.compile(r'"[^"\n]*\bFAIL', re.I)
SIGNAL = re.compile(r'Set_Exit_Status\s*\([^)]*Failure|OS_Exit\s*\(\s*[1-9]|\braise\b|pragma\s+Assert\b|\bAssert\s*\(', re.I)
OUT_PARAM = re.compile(r'^procedure\s+\w+\s*\([^)]*:\s*out\b', re.I | re.M)
SKIP = {'.git', 'obj', 'bin', 'gnatprove', 'alire', 'tools', 'docs'}

def code(t):
    """drop Ada comments (a -- outside a string literal), keep string literals"""
    out = []
    for l in t.split('\n'):
        q, i = False, 0
        while i < len(l):
            if l[i] == '"': q = not q
            elif not q and l.startswith('--', i): l = l[:i]; break
            i += 1
        out.append(l)
    return '\n'.join(out)

COUNTER = re.compile(r'\b(\w*fail\w*)\s*:=\s*\1\s*\+\s*1\b', re.I)

def signalled(t):
    counters = set(m.lower() for m in COUNTER.findall(t))
    if not counters:
        return bool(SIGNAL.search(t))
    #  a call of a local procedure whose body signals (e.g. Fail (...) that raises) counts as a signal
    sig = SIGNAL
    names = []
    for m in re.finditer(r'\bprocedure\s+(\w+)\b(?:\s*\([^)]*\))?\s*is\b', t, re.I):
        e = re.search(r'\bend\s+' + re.escape(m.group(1)) + r'\s*;', t[m.end():], re.I)
        if e and SIGNAL.search(t[m.end():m.end() + e.start()]):
            names.append(m.group(1))
    if names:
        sig = re.compile(SIGNAL.pattern + '|' + '|'.join(r'\b' + re.escape(n) + r'\s*\(' for n in names), re.I)
    lines = t.split('\n')
    for c in counters:
        if re.search(r'Assert\s*\(\s*' + re.escape(c) + r'\s*=\s*0', t, re.I):
            return True
        for i, l in enumerate(lines):
            m = re.match(r'^(\s*)(els)?if\b.*\b' + re.escape(c) + r'\b', l, re.I)
            if not m:
                continue
            ind = m.group(1)
            j = i + 1
            while j < len(lines) and not re.match('^' + ind + r'end\s+if\s*;', lines[j], re.I):
                j += 1
            if sig.search('\n'.join(lines[i:j + 1])):
                return True
    return False

def scan(root):
    drivers, makes = [], []
    for dp, dirs, files in os.walk(root):
        dirs[:] = sorted(x for x in dirs if x not in SKIP)
        rel = os.path.relpath(dp, root)
        for fn in sorted(files):
            p = os.path.join(dp, fn)
            if DRIVER.match(fn):
                t = code(open(p, errors='replace').read())
                if FAIL_LIT.search(t) and not signalled(t) and not OUT_PARAM.search(t):
                    drivers.append(f'{rel}/{fn}')
            elif fn == 'Makefile' and rel != '.':
                t = open(p, errors='replace').read()
                pipefail = re.search(r'pipefail', t)
                target, cont = '', False
                for k, l in enumerate(t.split('\n'), 1):
                    was_cont, cont = cont, l.rstrip().endswith('\\')
                    if not l.startswith('\t'):
                        m = re.match(r'^([\w.$()/-]+)\s*:(?!=)', l)
                        if m: target = m.group(1)
                        continue
                    if was_cont or re.match(r'(dist)?clean', target):   # continuation lines; cleaning may fail harmlessly
                        continue
                    body = l.strip()
                    why = ('|| true' if re.search(r'\|\|\s*(true|:)\b', body) else
                           "leading '-'" if body.startswith('-') or body.startswith('@-') else
                           'pipe to tee without pipefail' if re.search(r'\|\s*tee\b', body) and not pipefail else '')
                    if why:
                        makes.append(f'{rel}/Makefile:{k}: {why}: {body[:100]}')
    return drivers, makes

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', default=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--selftest', action='store_true', help='run the Makefile / driver control fixtures only')
    a = ap.parse_args()
    if a.selftest:
        import tempfile
        with tempfile.TemporaryDirectory() as t:
            def w(rel, txt):
                os.makedirs(os.path.dirname(os.path.join(t, rel)), exist_ok=True); open(os.path.join(t, rel), 'w').write(txt)
            w('a/Silent/tests.adb', 'procedure Tests is\n   Failures : Natural := 0;\nbegin\n   Failures := Failures + 1;\n'
              '   if Failures = 0 then\n      Put_Line ("PASS");\n   else\n      Put_Line ("FAIL");\n   end if;\n   pragma Assert (True);\nend Tests;\n')
            w('a/Loud/tests.adb', 'procedure Tests is\n   Failures : Natural := 0;\nbegin\n   Failures := Failures + 1;\n'
              '   if Failures > 0 then\n      Put_Line ("FAIL");\n      raise Program_Error;\n   end if;\nend Tests;\n')
            w('a/Swallow/Makefile', 'test:\n\t-bin/tests\n\tbin/tests || true\n\tbin/tests | tee log\nclean:\n\t-rm -rf obj\n')
            w('a/Piped/Makefile', 'SHELL := /bin/bash -o pipefail\ntest:\n\tbin/tests | tee log\n')
            d, m = scan(t)
        ok = d == ['a/Silent/tests.adb'] and len(m) == 3 and all('Swallow' in x for x in m)
        print(('ok  ' if ok else 'FAIL') + f' fail-exit control: silent driver and 3 swallowing recipe lines found; signalling driver, clean recipe, pipefail not ({d}, {m})')
        sys.exit(0 if ok else 1)
    d, m = scan(a.root)
    for x in d: print('FAIL driver prints FAIL, no exit-status signal:', x)
    for x in m: print('FAIL Makefile swallows an exit code:', x)
    print(('ok  ' if not (d or m) else 'FAIL') + f' fail-exit scan: {len(d)} driver(s), {len(m)} Makefile line(s)')
    sys.exit(1 if d or m else 0)
