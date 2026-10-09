#!/usr/bin/env python3
"""Exhaustive equivalence check for surviving mutants of misc/Ada/Phonetic-Algorithms
(docs/VV.md 3i). Builds a driver that prints all four encodings for every word of
length 1..4 over A..Z and 1..5 over AEICGHKNSTWD (769,326 words), runs it on the
original body and on each surviving mutant, and compares the outputs.
usage: sweep_equiv_phonetic.py MUT_DETAIL_OR_GATE_OUTPUT   (rows: folder,file,line,op,before,after,survived)
"""
import os, shutil, subprocess, sys, hashlib, tempfile
DRIVE = r'''pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Phonetic_Algorithms; use Phonetic_Algorithms;
procedure Drive is
   Full : constant String := "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
   Ctx  : constant String := "AEICGHKNSTWD";
   type Enc is access function (S : String) return String;
   E : constant array (1 .. 4) of Enc := [Soundex'Access, NYSIIS'Access, Metaphone'Access, Match_Rating_Encode'Access];
   procedure One (W : String) is
   begin
      Put (W);
      for F of E loop
         begin
            Put ("|" & F (W));
         exception
            when Invalid_Argument => Put ("|!");
         end;
      end loop;
      New_Line;
   end One;
   procedure Gen (Alpha : String; Prefix : String; Depth : Natural) is
   begin
      if Prefix'Length > 0 then One (Prefix); end if;
      if Depth = 0 then return; end if;
      for C of Alpha loop
         Gen (Alpha, Prefix & C, Depth - 1);
      end loop;
   end Gen;
begin
   Gen (Full, "", 4);
   for A of Ctx loop
      Gen (Ctx, "" & A & A, 3);   --  length 5 words with a doubled first letter / prefixes
   end loop;
   Gen (Ctx, "", 5);
end Drive;
'''
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
W = os.path.join(tempfile.gettempdir(), 'phx')
os.makedirs(W, exist_ok=True)
F = os.path.join(ROOT, 'misc/Ada/Phonetic-Algorithms')
for x in ('phonetic_algorithms.ads', 'phonetic_algorithms.adb'):
    shutil.copy(os.path.join(F, x), W)
open(os.path.join(W, 'drive.adb'), 'w').write(DRIVE)
subprocess.run(['gnatmake', '-q', '-O1', '-gnat2022', 'drive.adb', '-o', 'drive_orig'], cwd=W, check=True)
orig_hash = hashlib.md5(subprocess.run(['./drive_orig'], cwd=W, capture_output=True).stdout).hexdigest()
os.chdir(W)
sys.argv = [sys.argv[0], sys.argv[1], orig_hash]
import csv
from concurrent.futures import ThreadPoolExecutor
rows = [r for r in csv.reader(open(sys.argv[1])) if len(r) == 7 and r[6] == 'survived']
src = open('phonetic_algorithms.adb').read().split('\n')
orig = sys.argv[2]
def run(i_r):
    i, r = i_r
    _, f, ln, op, before, after, _ = r
    ln = int(ln) - 1
    w = os.path.join(W, f'm{i}'); shutil.rmtree(w, ignore_errors=True); os.makedirs(w)
    for x in ('phonetic_algorithms.ads', 'drive.adb'): shutil.copy(x, w)
    L = list(src)
    if before not in L[ln]: return (r, 'nomatch')
    L[ln] = L[ln].replace(before, after, 1)
    open(f'{w}/phonetic_algorithms.adb', 'w').write('\n'.join(L))
    b = subprocess.run(['gnatmake', '-q', '-O1', '-gnat2022', 'drive.adb', '-o', 'd'], cwd=w, capture_output=True)
    if b.returncode: return (r, 'stillborn')
    try:
        p = subprocess.run(['./d'], cwd=w, capture_output=True, timeout=120)
    except subprocess.TimeoutExpired:
        return (r, 'timeout')
    h = hashlib.md5(p.stdout).hexdigest()
    if p.returncode: return (r, 'crash')
    if h == orig: return (r, 'equivalent')
    a = subprocess.run(['./drive_orig'], capture_output=True).stdout.split(b'\n')
    m = p.stdout.split(b'\n')
    for x, y in zip(a, m):
        if x != y: return (r, 'differs: ' + x.decode() + ' vs ' + y.decode())
    return (r, 'differs (length)')
with ThreadPoolExecutor(4) as ex:
    for r, res in ex.map(run, enumerate(rows)):
        print(f'{r[2]}|{r[3]}|{r[4]}|{r[5]}|{res}', flush=True)
