--  Standalone test suite for Primality_Test (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Primality_Test; use Primality_Test;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function U (N : Natural) return U64 is (U64 (N));

   Raised_OK : Boolean;

begin
   Put_Line ("Primality_Test — educational survey tests");
   Put_Line ("MR_Small_Max =" & MR_Small_Max'Image);
   Put_Line ("AKS_Tiny_Max =" & AKS_Tiny_Max'Image);

   ------------------------------------------------------------------
   Section ("1. Taxonomy / Method_Kind");
   ------------------------------------------------------------------
   Check (Is_Deterministic (Trial_Division), "Trial is deterministic");
   Check (not Is_Probabilistic (Trial_Division), "Trial not probabilistic");
   Check (Is_Proving (Trial_Division), "Trial is proving");
   Check (Is_Implemented (Trial_Division), "Trial implemented");

   Check (not Is_Deterministic (Fermat), "Fermat not deterministic");
   Check (Is_Probabilistic (Fermat), "Fermat is probabilistic");
   Check (not Is_Proving (Fermat), "Fermat not proving");
   Check (Is_Implemented (Fermat), "Fermat implemented");

   Check (Is_Deterministic (Miller_Rabin), "MR-small is deterministic");
   Check (not Is_Probabilistic (Miller_Rabin), "MR-small not probabilistic");
   Check (Is_Proving (Miller_Rabin), "MR-small is proving on domain");
   Check (Is_Implemented (Miller_Rabin), "MR implemented");

   Check (Is_Deterministic (Lucas_N_Minus_1), "Lucas catalogue deterministic");
   Check (Is_Proving (Lucas_N_Minus_1), "Lucas catalogue proving");
   Check (not Is_Implemented (Lucas_N_Minus_1), "Lucas catalogue only");

   Check (not Is_Deterministic (Baillie_PSW), "BPSW not deterministic");
   Check (Is_Probabilistic (Baillie_PSW), "BPSW probabilistic");
   Check (not Is_Implemented (Baillie_PSW), "BPSW catalogue only");

   Check (Is_Deterministic (AKS), "AKS tiny deterministic");
   Check (Is_Proving (AKS), "AKS tiny proving");
   Check (Is_Implemented (AKS), "AKS tiny implemented");

   Check (not Is_Implemented (Sieve_Eratosthenes_Catalogue),
          "Eratosthenes catalogue only");
   Check (not Is_Implemented (Sieve_Atkin_Catalogue),
          "Atkin catalogue only");
   Check (not Is_Implemented (Solovay_Strassen_Catalogue),
          "Solovay–Strassen catalogue only");
   Check (Is_Implemented (Default), "Default implemented");

   Check (Method_Name (Trial_Division) = "Trial division",
          "Method_Name Trial");
   Check (Method_Name (Fermat) = "Fermat", "Method_Name Fermat");
   Check (Method_Name (Miller_Rabin) = "Miller–Rabin", "Method_Name MR");
   Check (Method_Name (Baillie_PSW) = "Baillie–PSW", "Method_Name BPSW");

   ------------------------------------------------------------------
   Section ("2. Mul_Mod / Mod_Pow / Gcd / squares");
   ------------------------------------------------------------------
   Check (Mul_Mod (U (7), U (8), U (10)) = 6, "Mul_Mod 7*8 mod 10");
   Check (Mul_Mod (U (0), U (5), U (9)) = 0, "Mul_Mod 0");
   Check (Mod_Pow (U (2), U (10), U (1000)) = 24, "Mod_Pow 2^10");
   Check (Mod_Pow (U (2), U (0), U (7)) = 1, "Mod_Pow exp 0");
   Check (Mod_Pow (U (5), U (3), U (1)) = 0, "Mod_Pow mod 1");
   Check (Gcd (U (0), U (0)) = 0, "Gcd 0,0");
   Check (Gcd (U (12), U (18)) = 6, "Gcd 12,18");
   Check (Gcd (U (561), U (2)) = 1, "Gcd 561,2");
   Check (Gcd (U (561), U (3)) = 3, "Gcd 561,3");
   Check (Is_Perfect_Square (U (0)), "0 is square");
   Check (Is_Perfect_Square (U (1)), "1 is square");
   Check (Is_Perfect_Square (U (144)), "144 is square");
   Check (not Is_Perfect_Square (U (2)), "2 not square");
   Check (not Is_Perfect_Square (U (50)), "50 not square");
   Check (Is_Perfect_Power (U (8)), "8=2^3 perfect power");
   Check (Is_Perfect_Power (U (16)), "16=2^4 / 4^2 perfect power");
   Check (Is_Perfect_Power (U (81)), "81=3^4 / 9^2");
   Check (not Is_Perfect_Power (U (12)), "12 not perfect power");
   Check (not Is_Perfect_Power (U (2)), "2 not perfect power");
   Check (not Is_Perfect_Power (U (7)), "7 not perfect power");

   Raised_OK := False;
   begin
      declare
         Unused : constant U64 := Mul_Mod (U (1), U (1), U (0));
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Mul_Mod M=0 raises");

   Raised_OK := False;
   begin
      declare
         Unused : constant U64 := Mod_Pow (U (2), U (3), U (0));
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Mod_Pow M=0 raises");

   ------------------------------------------------------------------
   Section ("3. Trial division known primes / composites");
   ------------------------------------------------------------------
   Check (not Trial_Division_Is_Prime (U (0)), "trial 0");
   Check (not Trial_Division_Is_Prime (U (1)), "trial 1");
   Check (Trial_Division_Is_Prime (U (2)), "trial 2");
   Check (Trial_Division_Is_Prime (U (3)), "trial 3");
   Check (not Trial_Division_Is_Prime (U (4)), "trial 4");
   Check (Trial_Division_Is_Prime (U (5)), "trial 5");
   Check (not Trial_Division_Is_Prime (U (9)), "trial 9");
   Check (Trial_Division_Is_Prime (U (97)), "trial 97");
   Check (not Trial_Division_Is_Prime (U (91)), "trial 91=7*13");
   Check (Trial_Division_Is_Prime (U (101)), "trial 101");
   Check (not Trial_Division_Is_Prime (U (121)), "trial 121=11^2");
   Check (Trial_Division_Is_Prime (U (997)), "trial 997");
   Check (not Trial_Division_Is_Prime (U (1001)), "trial 1001=7*11*13");
   Check (Trial_Division_Is_Prime (U (7919)), "trial 7919");
   Check (not Trial_Division_Is_Prime (U (561)), "trial Carmichael 561");

   ------------------------------------------------------------------
   Section ("4. Fermat: 561 fools base 2; multi-base catches factors");
   ------------------------------------------------------------------
   Check (Fermat_Probable_Prime (U (2)), "Fermat 2");
   Check (Fermat_Probable_Prime (U (3)), "Fermat 3");
   Check (Fermat_Probable_Prime (U (97)), "Fermat 97");
   Check (not Fermat_Probable_Prime (U (9)), "Fermat rejects 9");
   Check (not Fermat_Probable_Prime (U (15)), "Fermat rejects 15");
   Check (not Fermat_Probable_Prime (U (91)), "Fermat rejects 91");
   --  Carmichael 561 fools Fermat with base 2 only (Rounds = 1)
   Check (Fermat_Probable_Prime (U (561), 1),
          "Fermat Rounds=1: 561 fools base 2");
   --  With base 3 included, gcd(3,561)=3 → rejected as composite
   Check (not Fermat_Probable_Prime (U (561), 2),
          "Fermat Rounds=2 catches 561 via base 3");
   Check (not Fermat_Probable_Prime (U (0)), "Fermat 0");
   Check (not Fermat_Probable_Prime (U (1)), "Fermat 1");
   Check (not Fermat_Probable_Prime (U (4)), "Fermat 4");

   ------------------------------------------------------------------
   Section ("5. Miller–Rabin rejects 561; known values");
   ------------------------------------------------------------------
   Check (Miller_Rabin_Deterministic_Small (U (2)), "MR 2");
   Check (Miller_Rabin_Deterministic_Small (U (3)), "MR 3");
   Check (Miller_Rabin_Deterministic_Small (U (97)), "MR 97");
   Check (Miller_Rabin_Deterministic_Small (U (65537)), "MR Fermat F4");
   Check (not Miller_Rabin_Deterministic_Small (U (0)), "MR 0");
   Check (not Miller_Rabin_Deterministic_Small (U (1)), "MR 1");
   Check (not Miller_Rabin_Deterministic_Small (U (4)), "MR 4");
   Check (not Miller_Rabin_Deterministic_Small (U (9)), "MR 9");
   Check (not Miller_Rabin_Deterministic_Small (U (561)),
          "MR rejects Carmichael 561");
   Check (not Miller_Rabin_Deterministic_Small (U (1105)), "MR 1105");
   Check (not Miller_Rabin_Deterministic_Small (U (1729)), "MR 1729");
   Check (not Miller_Rabin_Deterministic_Small (U (2047)), "MR 2047");
   Check (Miller_Rabin_Deterministic_Small (U (1_000_003)), "MR 1000003");
   Check (not Miller_Rabin_Deterministic_Small (U (1_000_000)), "MR 10^6");

   Raised_OK := False;
   begin
      declare
         Unused : constant Boolean :=
           Miller_Rabin_Deterministic_Small (MR_Small_Max + 1);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "MR N>2^32 raises");

   ------------------------------------------------------------------
   Section ("6. Cross-check Trial vs MR for N ≤ 5000");
   ------------------------------------------------------------------
   declare
      Mismatch : Natural := 0;
   begin
      for N in U64 range 0 .. 5000 loop
         if Trial_Division_Is_Prime (N) /=
           Miller_Rabin_Deterministic_Small (N)
         then
            Mismatch := Mismatch + 1;
         end if;
      end loop;
      Check (Mismatch = 0, "Trial vs MR agree for N in 0..5000");
   end;

   ------------------------------------------------------------------
   Section ("7. AKS tiny hybrid");
   ------------------------------------------------------------------
   Check (AKS_Is_Prime_Tiny (U (2)), "AKS tiny 2");
   Check (AKS_Is_Prime_Tiny (U (3)), "AKS tiny 3");
   Check (AKS_Is_Prime_Tiny (U (97)), "AKS tiny 97");
   Check (not AKS_Is_Prime_Tiny (U (1)), "AKS tiny 1");
   Check (not AKS_Is_Prime_Tiny (U (4)), "AKS tiny 4=2^2");
   Check (not AKS_Is_Prime_Tiny (U (8)), "AKS tiny 8=2^3");
   Check (not AKS_Is_Prime_Tiny (U (9)), "AKS tiny 9=3^2");
   Check (not AKS_Is_Prime_Tiny (U (49)), "AKS tiny 49");
   Check (not AKS_Is_Prime_Tiny (U (561)), "AKS tiny 561");
   Check (AKS_Is_Prime_Tiny (U (7919)), "AKS tiny 7919");

   Raised_OK := False;
   begin
      declare
         Unused : constant Boolean := AKS_Is_Prime_Tiny (AKS_Tiny_Max + 1);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "AKS tiny N>Max raises");

   declare
      Mismatch : Natural := 0;
   begin
      for N in U64 range 0 .. AKS_Tiny_Max loop
         if AKS_Is_Prime_Tiny (N) /= Trial_Division_Is_Prime (N) then
            Mismatch := Mismatch + 1;
         end if;
      end loop;
      Check (Mismatch = 0, "AKS tiny vs Trial agree ≤ AKS_Tiny_Max");
   end;

   ------------------------------------------------------------------
   Section ("8. Dispatcher Is_Prime / Default");
   ------------------------------------------------------------------
   Check (Is_Prime (U (97), Trial_Division), "dispatch Trial 97");
   Check (Is_Prime (U (97), Fermat), "dispatch Fermat 97");
   Check (Is_Prime (U (97), Miller_Rabin), "dispatch MR 97");
   Check (Is_Prime (U (97), AKS), "dispatch AKS 97");
   Check (Is_Prime (U (97), Default), "dispatch Default 97");
   Check (not Is_Prime (U (561), Miller_Rabin), "dispatch MR 561");
   Check (Is_Prime (U (561), Fermat) = Fermat_Probable_Prime (U (561)),
          "dispatch Fermat 561 matches");
   Check (Is_Prime_Default (U (2)), "Default 2");
   Check (Is_Prime_Default (U (97)), "Default 97");
   Check (not Is_Prime_Default (U (561)), "Default 561");
   Check (Is_Prime_Default (U (50_000)) =
            Miller_Rabin_Deterministic_Small (U (50_000)),
          "Default uses MR above cutoff");
   Check (Is_Prime_Default (U (997)) = Trial_Division_Is_Prime (U (997)),
          "Default uses Trial below cutoff");

   Raised_OK := False;
   begin
      declare
         Unused : constant Boolean :=
           Is_Prime (U (7), Lucas_N_Minus_1);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "dispatch Lucas catalogue raises");

   Raised_OK := False;
   begin
      declare
         Unused : constant Boolean := Is_Prime (U (7), Baillie_PSW);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "dispatch Baillie_PSW catalogue raises");

   Raised_OK := False;
   begin
      declare
         Unused : constant Boolean :=
           Is_Prime (U (7), Sieve_Eratosthenes_Catalogue);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "dispatch Sieve_Eratosthenes raises");

   Raised_OK := False;
   begin
      declare
         Unused : constant Boolean :=
           Is_Prime (U (7), Sieve_Atkin_Catalogue);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "dispatch Sieve_Atkin raises");

   Raised_OK := False;
   begin
      declare
         Unused : constant Boolean :=
           Is_Prime (U (7), Solovay_Strassen_Catalogue);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "dispatch Solovay_Strassen raises");

   ------------------------------------------------------------------
   Section ("9. Invalid_Argument edges / more primes");
   ------------------------------------------------------------------
   Check (Trial_Division_Is_Prime (U (11)), "trial 11");
   Check (Trial_Division_Is_Prime (U (13)), "trial 13");
   Check (Trial_Division_Is_Prime (U (17)), "trial 17");
   Check (Trial_Division_Is_Prime (U (19)), "trial 19");
   Check (Trial_Division_Is_Prime (U (23)), "trial 23");
   Check (Trial_Division_Is_Prime (U (29)), "trial 29");
   Check (Trial_Division_Is_Prime (U (31)), "trial 31");
   Check (not Trial_Division_Is_Prime (U (25)), "trial 25");
   Check (not Trial_Division_Is_Prime (U (27)), "trial 27");
   Check (not Trial_Division_Is_Prime (U (33)), "trial 33");
   Check (not Trial_Division_Is_Prime (U (35)), "trial 35");
   Check (Miller_Rabin_Deterministic_Small (U (2_147_483_647)),
          "MR Mersenne 31");
   Check (Is_Prime (U (2_147_483_647), Default), "Default Mersenne 31");
   Check (Fermat_Probable_Prime (U (2_147_483_647)), "Fermat Mersenne 31");

   ------------------------------------------------------------------
   Section ("Summary");
   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
   pragma Assert (Fail_Count = 0);
end Tests;
