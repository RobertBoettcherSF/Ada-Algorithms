#!/usr/bin/env python3
"""Exhaustive equivalence check for surviving mutants of
misc/Ada/Hidden-Subgroup-Problem (docs/VV.md 3i). The driver prints, for the
original body and for each surviving mutant:
* Simon_Null_Vector on every subset of Z_2^n (n = 1 .. 4), in increasing and
  in decreasing order (2 x 65,822 equation lists);
* Simon_Sample_Equations and Solve_Simons_Problem for every f : Z_2^n -> Z_4
  (n = 1, 2) and every f : Z_2^3 -> Z_2;
* Solve_Period_Finding, Solve_Abelian_HSP and Verify_Hidden_Subgroup (every
  single h and every pair) for every f : Z_N -> {0, 1, 2}, N = 2 .. 6.
Exceptions are printed as their name. Outputs are compared by hash.
usage: sweep_equiv_hsp.py DETAIL.csv   (rows folder,file,line,op,before,after,result; 'survived' rows only)
"""
import csv, hashlib, os, shutil, subprocess, sys
from concurrent.futures import ThreadPoolExecutor
DRIVE = r'''pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Hidden_Subgroup_Problem; use Hidden_Subgroup_Problem;
procedure Drive is
   Tab_S : array (Bit_Mask) of Bit_Mask := [others => 0];
   function FS (X : Bit_Mask) return Bit_Mask is (Tab_S (X));
   Tab_G : array (Group_Element range 0 .. 63) of Group_Element := [others => 0];
   function FG (X : Group_Element) return Group_Element is (Tab_G (X));
   procedure Null_Line (Bits : Positive; E : Bit_Mask_Array) is
   begin
      Put (Simon_Null_Vector (Bits, E)'Image);
   exception
      when Subgroup_Not_Found => Put (" SNF");
      when Invalid_Oracle => Put (" IO");
   end Null_Line;
   procedure Simon_Line (Bits : Positive) is
      E : constant Bit_Mask_Array := Simon_Sample_Equations (Bits, FS'Unrestricted_Access);
   begin
      for Y of E loop Put (Y'Image); end loop;
      Put (" :");
      begin
         Put (Solve_Simons_Problem (Bits, FS'Unrestricted_Access)'Image);
      exception
         when Subgroup_Not_Found => Put (" SNF");
         when Invalid_Oracle => Put (" IO");
      end;
      New_Line;
   end Simon_Line;
begin
   for Bits in 1 .. 4 loop
      for Set in 0 .. 2 ** (2 ** Bits) - 1 loop
         declare
            Up, Down : Bit_Mask_Array (1 .. 2 ** Bits);
            K : Natural := 0;
         begin
            for Y in 0 .. 2 ** Bits - 1 loop
               if (Set / 2 ** Y) mod 2 = 1 then
                  K := K + 1;
                  Up (K) := Bit_Mask (Y);
               end if;
            end loop;
            for I in 1 .. K loop
               Down (I) := Up (K + 1 - I);
            end loop;
            Null_Line (Bits, Up (1 .. K));
            Null_Line (Bits, Down (1 .. K));
            New_Line;
         end;
      end loop;
   end loop;
   for Bits in 1 .. 3 loop
      declare
         Vals : constant Natural := (if Bits = 3 then 2 else 4);
         Size : constant Natural := 2 ** Bits;
      begin
         for Code in 0 .. Vals ** Size - 1 loop
            for X in 0 .. Size - 1 loop
               Tab_S (Bit_Mask (X)) := Bit_Mask ((Code / Vals ** X) mod Vals);
            end loop;
            Simon_Line (Bits);
         end loop;
      end;
   end loop;
   for N in Group_Element range 2 .. 6 loop
      for Code in 0 .. 3 ** Natural (N) - 1 loop
         for X in 0 .. N - 1 loop
            Tab_G (X) := Group_Element ((Code / 3 ** Natural (X)) mod 3);
         end loop;
         begin
            Put (Solve_Period_Finding (N, FG'Unrestricted_Access)'Image);
            Put (Solve_Abelian_HSP (N, FG'Unrestricted_Access) (1)'Image);
         exception
            when Subgroup_Not_Found => Put (" SNF");
            when Invalid_Oracle => Put (" IO");
         end;
         for H in 0 .. N - 1 loop
            Put (if Verify_Hidden_Subgroup (N, [1 => H], FG'Unrestricted_Access) then "T" else "F");
            for H2 in 0 .. N - 1 loop
               Put (if Verify_Hidden_Subgroup (N, [H, H2], FG'Unrestricted_Access) then "t" else "f");
            end loop;
         end loop;
         New_Line;
      end loop;
   end loop;
end Drive;
'''
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
F = os.path.join(ROOT, 'misc/Ada/Hidden-Subgroup-Problem')
W = '/tmp/hspx'; shutil.rmtree(W, ignore_errors=True); os.makedirs(W)
for x in ('hidden_subgroup_problem.ads', 'hidden_subgroup_problem.adb'):
    shutil.copy(os.path.join(F, x), W)
open(os.path.join(W, 'drive.adb'), 'w').write(DRIVE)
subprocess.run(['gnatmake', '-q', '-O1', '-gnat2022', '-gnata', 'drive.adb', '-o', 'drive_orig'], cwd=W, check=True)
ref = subprocess.run(['./drive_orig'], cwd=W, capture_output=True).stdout
orig = hashlib.md5(ref).hexdigest()
print(f'reference: {len(ref.splitlines())} lines, md5 {orig}', flush=True)
rows = [r for r in csv.reader(open(sys.argv[1])) if len(r) == 7 and r[6].strip() == 'survived']
src = open(os.path.join(W, 'hidden_subgroup_problem.adb')).read().split('\n')
def run(i_r):
    i, r = i_r
    _, f, ln, op, before, after, _ = r
    if not ln.isdigit():
        return (r, 'skipped (second-order or hidden line)')
    ln = int(ln) - 1
    w = f'{W}/m{i}'; os.makedirs(w)
    for x in ('hidden_subgroup_problem.ads', 'drive.adb'): shutil.copy(os.path.join(W, x), w)
    L = list(src)
    if before not in L[ln]: return (r, 'nomatch')
    L[ln] = L[ln].replace(before, after, 1)
    open(f'{w}/hidden_subgroup_problem.adb', 'w').write('\n'.join(L))
    b = subprocess.run(['gnatmake', '-q', '-O1', '-gnat2022', '-gnata', 'drive.adb', '-o', 'd'], cwd=w, capture_output=True)
    if b.returncode: return (r, 'stillborn')
    try:
        p = subprocess.run(['./d'], cwd=w, capture_output=True, timeout=300)
    except subprocess.TimeoutExpired:
        return (r, 'timeout')
    if p.returncode: return (r, 'crash')
    if hashlib.md5(p.stdout).hexdigest() == orig: return (r, 'equivalent')
    for k, (x, y) in enumerate(zip(ref.split(b'\n'), p.stdout.split(b'\n'))):
        if x != y: return (r, f'differs at line {k + 1}: {x.decode()[:80]} vs {y.decode()[:80]}')
    return (r, 'differs (length)')
with ThreadPoolExecutor(4) as ex:
    for r, res in ex.map(run, enumerate(rows)):
        print(f'{r[2]}|{r[3]}|{r[4]}|{r[5]}|{res}', flush=True)
