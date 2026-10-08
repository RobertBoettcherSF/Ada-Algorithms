#!/usr/bin/env python3
"""Give a folder's random test inputs a fixed, printed default seed that the
environment variable AA_SEED overrides (room rule 2026-10-08 20:5x).

Handles the two generator shapes used in agent B's folders:
  own_checks.adb  Seed : Long_Long_Integer := <n>;  (Park-Miller, seed must be
                  in 1 .. 2**31 - 2, so a bad AA_SEED stops the run with
                  Constraint_Error rather than silently degenerating)
  tests.adb       Seed : Natural := <n>;            (linear congruential)
Usage: sweep_aa_seed.py FOLDER...   (idempotent; prints what it changed)"""
import os, re, sys

SHAPES = {
    'own_checks.adb': (re.compile(r'^([ \t]*)Seed : Long_Long_Integer := ([0-9_]+);$', re.M),
                       'Long_Long_Integer range 1 .. 2_147_483_646', 'own checks'),
    'tests.adb': (re.compile(r'^([ \t]*)Seed : Natural := ([0-9_]+);$', re.M), 'Natural', 'tests'),
}

def patch(path, rx, sub, label):
    s = open(path).read()
    if 'AA_SEED' in s:
        return 'already'
    m = rx.search(s)
    if not m:
        return 'no generator'
    ind, default = m.group(1), m.group(2)
    block = (f'{ind}--  Fixed default seed, printed at start; AA_SEED overrides it.\n'
             f'{ind}subtype Seed_Range is {sub};\n'
             f'{ind}Default_Seed : constant Seed_Range := {default};\n'
             f'{ind}function Initial_Seed return Seed_Range is\n'
             f'{ind}  (if Ada.Environment_Variables.Exists ("AA_SEED")\n'
             f'{ind}   then Seed_Range\'Value (Ada.Environment_Variables.Value ("AA_SEED"))\n'
             f'{ind}   else Default_Seed);\n'
             f'{ind}Seed : {"Long_Long_Integer" if "Long" in sub else "Natural"} := Initial_Seed;')
    s = s[:m.start()] + block + s[m.end():]
    w = re.search(r'^with Ada\.Text_IO;.*$', s, re.M)
    if not w:
        return 'no Ada.Text_IO'
    s = s[:w.end()] + '\nwith Ada.Environment_Variables;' + s[w.end():]
    begins = [b for b in re.finditer(r'^begin\n', s, re.M)]
    if not begins:
        return 'no main begin'
    b = begins[-1]
    line = (f'   Put_Line ("{label} seed:" & Seed\'Image & " (default"\n'
            f'             & Default_Seed\'Image & "; set AA_SEED to override)");\n')
    s = s[:b.end()] + line + s[b.end():]
    open(path, 'w').write(s)
    return f'patched (default {default})'

for folder in sys.argv[1:]:
    for f, (rx, sub, label) in SHAPES.items():
        p = os.path.join(folder, f)
        if os.path.exists(p):
            print(f'{folder}/{f}: {patch(p, rx, sub, label)}')
