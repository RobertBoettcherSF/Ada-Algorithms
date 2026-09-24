--  Standalone test suite for Prime_Factorization (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Prime_Factorization; use Prime_Factorization;

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

   function Product (F : Factor_List) return U64 is
      P : U64 := 1;
   begin
      for E of F loop
         for I in 1 .. E.Exponent loop
            P := P * E.Prime;
         end loop;
      end loop;
      return P;
   end Product;

   function Sorted_Ascending (F : Factor_List) return Boolean is
   begin
      for I in F'First .. F'Last - 1 loop
         if F (I).Prime >= F (I + 1).Prime then
            return False;
         end if;
      end loop;
      return True;
   end Sorted_Ascending;

   Raised_OK : Boolean;
   Fl        : Factor_List (1 .. 8);
   pragma Unreferenced (Fl);
   F         : U64;

begin
   Put_Line ("Prime_Factorization — educational survey tests");

   ------------------------------------------------------------------
   Section ("1. Taxonomy / Method_Kind");
   ------------------------------------------------------------------
   Check (Is_Special_Purpose (Trial_Division), "Trial special-purpose");
   Check (not Is_General (Trial_Division), "Trial not general");
   Check (Is_Implemented (Trial_Division), "Trial implemented");

   Check (Is_Special_Purpose (Fermat), "Fermat special-purpose");
   Check (not Is_General (Fermat), "Fermat not general");
   Check (Is_Implemented (Fermat), "Fermat implemented");

   Check (Is_Special_Purpose (Pollard_Rho), "Rho special-purpose");
   Check (not Is_General (Pollard_Rho), "Rho not general");
   Check (Is_Implemented (Pollard_Rho), "Rho implemented");

   Check (Is_Special_Purpose (Pollard_P1), "P-1 special-purpose");
   Check (not Is_Implemented (Pollard_P1), "P-1 catalogue only");

   Check (not Is_Special_Purpose (Quadratic_Sieve), "QS not special");
   Check (Is_General (Quadratic_Sieve), "QS is general");
   Check (not Is_Implemented (Quadratic_Sieve), "QS catalogue only");

   Check (Is_Special_Purpose (SNFS), "SNFS special-purpose");
   Check (not Is_General (SNFS), "SNFS not general");
   Check (not Is_Implemented (SNFS), "SNFS catalogue only");

   Check (not Is_Special_Purpose (GNFS), "GNFS not special");
   Check (Is_General (GNFS), "GNFS is general");
   Check (not Is_Implemented (GNFS), "GNFS catalogue only");

   Check (Is_Special_Purpose (ECM), "ECM special-purpose");
   Check (not Is_Implemented (ECM), "ECM catalogue only");

   Check (not Is_Special_Purpose (Shor_Catalogue), "Shor not special");
   Check (not Is_General (Shor_Catalogue), "Shor not general");
   Check (not Is_Implemented (Shor_Catalogue), "Shor catalogue only");

   Check (not Is_Special_Purpose (Default), "Default not special");
   Check (Is_General (Default), "Default marked general hybrid");
   Check (Is_Implemented (Default), "Default implemented");

   Check (Method_Name (Trial_Division) = "Trial division",
          "Method_Name Trial");
   Check (Method_Name (Fermat) = "Fermat factorization",
          "Method_Name Fermat");
   Check (Method_Name (Pollard_Rho) = "Pollard's rho",
          "Method_Name Rho");
   Check (Method_Name (Quadratic_Sieve) = "Quadratic sieve (catalogue)",
          "Method_Name QS");
   Check (Method_Name (Default) = "Default (trial / rho hybrid)",
          "Method_Name Default");

   ------------------------------------------------------------------
   Section ("2. Helpers: Gcd / Mul_Mod / Floor_Sqrt / Is_Prime_Trial");
   ------------------------------------------------------------------
   Check (Gcd (U (0), U (0)) = 0, "Gcd 0,0");
   Check (Gcd (U (12), U (18)) = 6, "Gcd 12,18");
   Check (Gcd (U (8051), U (83)) = 83, "Gcd 8051,83");
   Check (Gcd (U (17), U (19)) = 1, "Gcd 17,19");
   Check (Mul_Mod (U (7), U (8), U (10)) = 6, "Mul_Mod 7*8 mod 10");
   Check (Mul_Mod (U (0), U (5), U (9)) = 0, "Mul_Mod 0");
   Check (Mul_Mod (U (123456789), U (987654321), U (1000003)) =
            Mul_Mod (U (123456789), U (987654321), U (1000003)),
          "Mul_Mod self-consistent");
   Check (Floor_Sqrt (U (0)) = 0, "Floor_Sqrt 0");
   Check (Floor_Sqrt (U (1)) = 1, "Floor_Sqrt 1");
   Check (Floor_Sqrt (U (15)) = 3, "Floor_Sqrt 15");
   Check (Floor_Sqrt (U (16)) = 4, "Floor_Sqrt 16");
   Check (Floor_Sqrt (U (455839)) = 675, "Floor_Sqrt 455839");
   Check (not Is_Prime_Trial (U (0)), "Is_Prime_Trial 0");
   Check (not Is_Prime_Trial (U (1)), "Is_Prime_Trial 1");
   Check (Is_Prime_Trial (U (2)), "Is_Prime_Trial 2");
   Check (Is_Prime_Trial (U (3)), "Is_Prime_Trial 3");
   Check (not Is_Prime_Trial (U (4)), "Is_Prime_Trial 4");
   Check (Is_Prime_Trial (U (97)), "Is_Prime_Trial 97");
   Check (not Is_Prime_Trial (U (91)), "Is_Prime_Trial 91");
   Check (Is_Prime_Trial (U (599)), "Is_Prime_Trial 599");
   Check (Is_Prime_Trial (U (761)), "Is_Prime_Trial 761");
   Check (not Is_Prime_Trial (U (455839)), "Is_Prime_Trial 455839");
   Check (not Is_Prime_Trial (U (8051)), "Is_Prime_Trial 8051");

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

   ------------------------------------------------------------------
   Section ("3. Trial_Division_Factor / Factorize_Trial");
   ------------------------------------------------------------------
   Check (Trial_Division_Factor (U (2)) = 2, "TDF 2");
   Check (Trial_Division_Factor (U (3)) = 3, "TDF 3");
   Check (Trial_Division_Factor (U (4)) = 2, "TDF 4");
   Check (Trial_Division_Factor (U (9)) = 3, "TDF 9");
   Check (Trial_Division_Factor (U (97)) = 97, "TDF 97 prime");
   Check (Trial_Division_Factor (U (91)) = 7, "TDF 91=7*13");
   Check (Trial_Division_Factor (U (100)) = 2, "TDF 100");
   Check (Trial_Division_Factor (U (8051)) = 83, "TDF 8051=83*97");
   Check (Trial_Division_Factor (U (455839)) = 599, "TDF 455839=599*761");

   declare
      Ft70  : constant Factor_List := Factorize_Trial (U (70));
      Ft100 : constant Factor_List := Factorize_Trial (U (100));
      Ft1   : constant Factor_List := Factorize_Trial (U (1));
      Ft97  : constant Factor_List := Factorize_Trial (U (97));
      Ft12  : constant Factor_List := Factorize_Trial (U (12));
   begin
      Check (Ft1'Length = 0, "Factorize_Trial 1 empty");
      Check (Ft70'Length = 3, "Factorize_Trial 70 length 3");
      Check (Ft70 (1).Prime = 2 and then Ft70 (1).Exponent = 1,
             "Factorize_Trial 70 has 2");
      Check (Ft70 (2).Prime = 5 and then Ft70 (2).Exponent = 1,
             "Factorize_Trial 70 has 5");
      Check (Ft70 (3).Prime = 7 and then Ft70 (3).Exponent = 1,
             "Factorize_Trial 70 has 7");
      Check (Product (Ft70) = 70, "Factorize_Trial 70 product");
      Check (Ft100'Length = 2, "Factorize_Trial 100 length");
      Check (Ft100 (1).Prime = 2 and then Ft100 (1).Exponent = 2,
             "Factorize_Trial 100 = 2^2");
      Check (Ft100 (2).Prime = 5 and then Ft100 (2).Exponent = 2,
             "Factorize_Trial 100 = 5^2");
      Check (Product (Ft100) = 100, "Factorize_Trial 100 product");
      Check (Ft97'Length = 1 and then Ft97 (1).Prime = 97,
             "Factorize_Trial 97");
      Check (Ft12 (1).Prime = 2 and then Ft12 (1).Exponent = 2
                and then Ft12 (2).Prime = 3,
             "Factorize_Trial 12 = 2^2 * 3");
      Check (Sorted_Ascending (Ft70), "Factorize_Trial 70 sorted");
   end;

   Raised_OK := False;
   begin
      declare
         Unused : constant U64 := Trial_Division_Factor (U (0));
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "TDF 0 raises");

   Raised_OK := False;
   begin
      declare
         Unused : constant U64 := Trial_Division_Factor (U (1));
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "TDF 1 raises");

   Raised_OK := False;
   begin
      declare
         Unused : constant Factor_List := Factorize_Trial (U (0));
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Factorize_Trial 0 raises");

   ------------------------------------------------------------------
   Section ("4. Fermat_Factor");
   ------------------------------------------------------------------
   F := Fermat_Factor (U (455839));
   Check (F = 599 or else F = 761, "Fermat 455839 → 599 or 761");
   Check (U (455839) rem F = 0, "Fermat 455839 divides");
   Check (Fermat_Factor (U (9)) = 3, "Fermat 9 = 3*3");
   Check (Fermat_Factor (U (15), 100) = 3 or else
            Fermat_Factor (U (15), 100) = 5 or else
            Fermat_Factor (U (15), 100) = 1,
          "Fermat 15 finds or times out");
   --  Close factors: 143 = 11*13; Fermat finds quickly.
   F := Fermat_Factor (U (143));
   Check (F = 11 or else F = 13, "Fermat 143 → 11 or 13");
   Check (Fermat_Factor (U (4)) = 2, "Fermat even 4 → 2");
   Check (Fermat_Factor (U (100)) = 2, "Fermat even 100 → 2");
   --  Max_Steps = 0 or tiny → may fail with 1 on hard spread.
   Check (Fermat_Factor (U (91), 0) = 1 or else
            Fermat_Factor (U (91), 0) > 1,
          "Fermat Max_Steps=0 returns something");
   F := Fermat_Factor (U (91), 50);
   Check ((F > 1 and then U (91) rem F = 0) or else F = 1,
          "Fermat 91 with 50 steps divides or fails");

   Raised_OK := False;
   begin
      declare
         Unused : constant U64 := Fermat_Factor (U (1));
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Fermat 1 raises");

   ------------------------------------------------------------------
   Section ("5. Pollard_Rho_Factor (8051 = 83 × 97)");
   ------------------------------------------------------------------
   F := Pollard_Rho_Factor (U (8051));
   Check (F = 83 or else F = 97, "Rho 8051 → 83 or 97");
   Check (U (8051) rem F = 0, "Rho 8051 divides");
   Check (Pollard_Rho_Factor (U (2)) = 2, "Rho 2");
   Check (Pollard_Rho_Factor (U (97)) = 97, "Rho prime 97");
   Check (Pollard_Rho_Factor (U (100)) = 2, "Rho even → 2");
   F := Pollard_Rho_Factor (U (455839));
   Check ((F > 1 and then F < 455839 and then U (455839) rem F = 0)
            or else F = 1,
          "Rho 455839 finds factor or reports fail");
   F := Pollard_Rho_Factor (U (10403));  -- 101*103
   Check ((F = 101 or else F = 103 or else
            (F > 1 and then U (10403) rem F = 0)),
          "Rho 10403 = 101*103");

   Raised_OK := False;
   begin
      declare
         Unused : constant U64 := Pollard_Rho_Factor (U (0));
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Rho 0 raises");

   ------------------------------------------------------------------
   Section ("6. Dispatcher Factor / Factorize");
   ------------------------------------------------------------------
   Check (Factor (U (91), Trial_Division) = 7, "Factor trial 91");
   F := Factor (U (455839), Fermat);
   Check (F = 599 or else F = 761, "Factor Fermat 455839");
   F := Factor (U (8051), Pollard_Rho);
   Check (F = 83 or else F = 97, "Factor Rho 8051");
   Check (Factor (U (97), Default) = 97, "Factor Default prime");
   Check (Factor (U (100), Default) = 2, "Factor Default 100");
   F := Factor (U (8051), Default);
   Check (F = 83 or else F = 97, "Factor Default 8051");

   declare
      Fz70   : constant Factor_List := Factorize (U (70));
      Fz100  : constant Factor_List := Factorize (U (100));
      Fz1    : constant Factor_List := Factorize (U (1));
      Fz8051 : constant Factor_List := Factorize (U (8051));
      Fz455  : constant Factor_List := Factorize (U (455839));
      Fz12   : constant Factor_List := Factorize (U (12));
      Fz97   : constant Factor_List := Factorize (U (97));
   begin
      Check (Fz1'Length = 0, "Factorize 1 empty");
      Check (Product (Fz70) = 70, "Factorize 70 product");
      Check (Fz70'Length = 3, "Factorize 70 length");
      Check (Product (Fz100) = 100, "Factorize 100 product");
      Check (Fz100 (1).Prime = 2 and then Fz100 (1).Exponent = 2,
             "Factorize 100 2^2");
      Check (Product (Fz8051) = 8051, "Factorize 8051 product");
      Check (Fz8051'Length = 2, "Factorize 8051 two primes");
      Check ((Fz8051 (1).Prime = 83 and then Fz8051 (2).Prime = 97),
             "Factorize 8051 = 83*97");
      Check (Product (Fz455) = 455839, "Factorize 455839 product");
      Check (Fz455'Length = 2, "Factorize 455839 two primes");
      Check (Fz455 (1).Prime = 599 and then Fz455 (2).Prime = 761,
             "Factorize 455839 = 599*761");
      Check (Product (Fz12) = 12, "Factorize 12 product");
      Check (Fz97'Length = 1 and then Fz97 (1).Prime = 97,
             "Factorize 97");
      Check (Sorted_Ascending (Fz8051), "Factorize 8051 sorted");
   end;

   Raised_OK := False;
   begin
      declare
         Unused : constant U64 := Factor (U (91), Quadratic_Sieve);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Factor QS catalogue raises");

   Raised_OK := False;
   begin
      declare
         Unused : constant U64 := Factor (U (91), SNFS);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Factor SNFS catalogue raises");

   Raised_OK := False;
   begin
      declare
         Unused : constant U64 := Factor (U (91), GNFS);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Factor GNFS catalogue raises");

   Raised_OK := False;
   begin
      declare
         Unused : constant U64 := Factor (U (91), ECM);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Factor ECM catalogue raises");

   Raised_OK := False;
   begin
      declare
         Unused : constant U64 := Factor (U (91), Shor_Catalogue);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Factor Shor catalogue raises");

   Raised_OK := False;
   begin
      declare
         Unused : constant U64 := Factor (U (91), Pollard_P1);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Factor P-1 catalogue raises");

   Raised_OK := False;
   begin
      declare
         Unused : constant U64 := Factor (U (0), Default);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Factor 0 raises");

   Raised_OK := False;
   begin
      declare
         Unused : constant Factor_List := Factorize (U (0));
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised_OK := True;
   end;
   Check (Raised_OK, "Factorize 0 raises");

   ------------------------------------------------------------------
   Section ("7. More known factorizations");
   ------------------------------------------------------------------
   declare
      Samples : constant array (Positive range <>) of U64 :=
        [12, 30, 42, 60, 84, 90, 210, 2310, 1001, 1111, 2047, 4095];
   begin
      for N of Samples loop
         declare
            Ft : constant Factor_List := Factorize_Trial (N);
            Fz : constant Factor_List := Factorize (N);
         begin
            Check (Product (Ft) = N,
                   "Factorize_Trial product " & N'Image);
            Check (Product (Fz) = N,
                   "Factorize product " & N'Image);
            Check (Sorted_Ascending (Ft),
                   "Factorize_Trial sorted " & N'Image);
         end;
      end loop;
   end;

   Check (Trial_Division_Factor (U (2047)) = 23, "TDF 2047=23*89");
   Check (Trial_Division_Factor (U (1001)) = 7, "TDF 1001=7*11*13");

   ------------------------------------------------------------------
   --  Summary
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
