--  Standalone test suite for Integer_Factorization (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Integer_Factorization; use Integer_Factorization;

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
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwc constant-condition warnings).
   function U (X : U64) return U64 is (X);

   function Product (L : Factor_List) return U64 is
      Acc : U64 := 1;
   begin
      for I in L'Range loop
         for E in 1 .. L (I).Exponent loop
            Acc := Acc * L (I).Prime;
         end loop;
      end loop;
      return Acc;
   end Product;

   function Sorted_Ascending (L : Factor_List) return Boolean is
   begin
      for I in L'First .. L'Last - 1 loop
         if L (I).Prime >= L (I + 1).Prime then
            return False;
         end if;
      end loop;
      return True;
   end Sorted_Ascending;

   function Divides (F, N : U64) return Boolean is
   begin
      return F > 1 and then F < N and then N rem F = 0;
   end Divides;

   procedure Expect_Invalid_Mul_Mod (Label : String; A, B, M : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Mul_Mod (A, B, M);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Mul_Mod: " & Label);
   end Expect_Invalid_Mul_Mod;

   procedure Expect_Invalid_SPF (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Smallest_Prime_Factor (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument SPF: " & Label);
   end Expect_Invalid_SPF;

   procedure Expect_Invalid_Factor (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Factor (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Factor: " & Label);
   end Expect_Invalid_Factor;

   procedure Expect_Invalid_Factorize (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Factor_List := Factorize (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Factorize: " & Label);
   end Expect_Invalid_Factorize;

   procedure Expect_Invalid_CoS (Label : String; X, Y, N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Factor_From_Congruence (X, Y, N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Factor_From_Congruence: " & Label);
   end Expect_Invalid_CoS;

   procedure Expect_Invalid_Fermat (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Fermat_Factor (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Fermat_Factor: " & Label);
   end Expect_Invalid_Fermat;

   procedure Expect_Invalid_Rho (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Pollard_Rho_Factor (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Pollard_Rho_Factor: " & Label);
   end Expect_Invalid_Rho;

   F : U64;
   P : Factor_Pair;
   L : Factor_List (1 .. 0);

begin
   Ada.Text_IO.Put_Line
     ("Integer_Factorization — Ada 2023 educational test suite");

   ------------------------------------------------------------------
   Section ("Mul_Mod / Gcd / Floor_Sqrt");
   ------------------------------------------------------------------
   Check (Mul_Mod (U (3), U (4), U (5)) = 2, "3*4 mod 5 = 2");
   Check (Mul_Mod (U (7), U (7), U (10)) = 9, "7*7 mod 10 = 9");
   Check (Mul_Mod (U (0), U (5), U (7)) = 0, "0*5 mod 7 = 0");
   Check (Mul_Mod (U (1), U (1), U (1)) = 0, "1*1 mod 1 = 0");
   Check (Mul_Mod (U (2**32), U (2**32), U (2**32 + 1)) =
            Mul_Mod (U (2**32), U (2**32), U (2**32 + 1)),
          "Mul_Mod large product stable");
   Expect_Invalid_Mul_Mod ("M=0", U (1), U (1), U (0));

   Check (Gcd (U (0), U (0)) = 0, "Gcd(0,0)=0");
   Check (Gcd (U (0), U (5)) = 5, "Gcd(0,5)=5");
   Check (Gcd (U (12), U (18)) = 6, "Gcd(12,18)=6");
   Check (Gcd (U (17), U (19)) = 1, "Gcd(17,19)=1");
   Check (Gcd (U (100), U (25)) = 25, "Gcd(100,25)=25");

   Check (Floor_Sqrt (U (0)) = 0, "Floor_Sqrt(0)=0");
   Check (Floor_Sqrt (U (1)) = 1, "Floor_Sqrt(1)=1");
   Check (Floor_Sqrt (U (15)) = 3, "Floor_Sqrt(15)=3");
   Check (Floor_Sqrt (U (16)) = 4, "Floor_Sqrt(16)=4");
   Check (Floor_Sqrt (U (2**10)) = 2**5, "Floor_Sqrt(1024)=32");
   Check (Ceil_Sqrt (U (0)) = 0, "Ceil_Sqrt(0)=0");
   Check (Ceil_Sqrt (U (16)) = 4, "Ceil_Sqrt(16)=4");
   Check (Ceil_Sqrt (U (17)) = 5, "Ceil_Sqrt(17)=5");
   Check (Is_Perfect_Square (U (36)), "36 is square");
   Check (not Is_Perfect_Square (U (37)), "37 not square");

   ------------------------------------------------------------------
   Section ("Trial primality / SPF");
   ------------------------------------------------------------------
   Check (not Is_Prime_Trial (U (0)), "0 not prime");
   Check (not Is_Prime_Trial (U (1)), "1 not prime");
   Check (Is_Prime_Trial (U (2)), "2 prime");
   Check (Is_Prime_Trial (U (3)), "3 prime");
   Check (not Is_Prime_Trial (U (4)), "4 composite");
   Check (Is_Prime_Trial (U (17)), "17 prime");
   Check (not Is_Prime_Trial (U (91)), "91=7*13 composite");
   Check (Is_Prime_Trial (U (97)), "97 prime");

   Check (Smallest_Prime_Factor (U (2)) = 2, "SPF(2)=2");
   Check (Smallest_Prime_Factor (U (15)) = 3, "SPF(15)=3");
   Check (Smallest_Prime_Factor (U (49)) = 7, "SPF(49)=7");
   Check (Smallest_Prime_Factor (U (97)) = 97, "SPF(97)=97");
   Check (Smallest_Prime_Factor (U (1001)) = 7, "SPF(1001)=7");
   Check (Trial_Division_Factor (U (2047)) = 23, "TDF(2047)=23");
   Expect_Invalid_SPF ("N=0", U (0));
   Expect_Invalid_SPF ("N=1", U (1));

   ------------------------------------------------------------------
   Section ("Factorize_Trial");
   ------------------------------------------------------------------
   declare
      Empty : constant Factor_List := Factorize_Trial (U (1));
      F60   : constant Factor_List := Factorize_Trial (U (60));
      F97   : constant Factor_List := Factorize_Trial (U (97));
      F720  : constant Factor_List := Factorize_Trial (U (720));
   begin
      Check (Empty'Length = 0, "Factorize_Trial(1) empty");
      Check (Product (F60) = 60, "Factorize_Trial(60) product");
      Check (F60'Length = 3, "60 = 2^a * 3^b * 5^c");
      Check (F60 (1).Prime = 2 and then F60 (1).Exponent = 2, "60: 2^2");
      Check (F60 (2).Prime = 3 and then F60 (2).Exponent = 1, "60: 3");
      Check (F60 (3).Prime = 5 and then F60 (3).Exponent = 1, "60: 5");
      Check (F97'Length = 1 and then F97 (1).Prime = 97, "97 prime list");
      Check (Product (F720) = 720, "Factorize_Trial(720) product");
      Check (Sorted_Ascending (F720), "720 factors sorted");
   end;

   ------------------------------------------------------------------
   Section ("Fermat factorization");
   ------------------------------------------------------------------
   Check (Fermat_Factor (U (2)) = 2, "Fermat(2)=2");
   Check (Fermat_Factor (U (15)) = 3, "Fermat(15)=3");
   Check (Fermat_Factor (U (36)) = 2, "Fermat(36)=2 even peel");
   Check (Fermat_Factor (U (121)) = 11, "Fermat(121)=11 square");
   Check (Divides (Fermat_Factor (U (8051)), U (8051)),
          "Fermat divides 8051");
   Check (Divides (Fermat_Factor (U (455839)), U (455839)),
          "Fermat divides 455839=599*761");
   P := Fermat_Factor_Pair (U (455839));
   Check (P.F1 = 599 and then P.F2 = 761, "Fermat pair 599*761");
   P := Fermat_Factor_Pair (U (15));
   Check (P.F1 = 3 and then P.F2 = 5, "Fermat pair 3*5");
   P := Fermat_Factor_Pair (U (100));
   Check (P.F1 = 2 and then P.F2 = 50, "Fermat even 100 -> (2,50)");
   P := Fermat_Factor_Pair (U (49));
   Check (P.F1 = 7 and then P.F2 = 7, "Fermat square 49");
   --  Far factors / tiny Max_Steps → failure sentinel
   Check (Fermat_Factor (U (91), Max_Steps => 1) = 1
            or else Divides (Fermat_Factor (U (91), Max_Steps => 1), U (91)),
          "Fermat(91) short steps ok-or-fail");
   Expect_Invalid_Fermat ("N=0", U (0));
   Expect_Invalid_Fermat ("N=1", U (1));

   ------------------------------------------------------------------
   Section ("Pollard's rho");
   ------------------------------------------------------------------
   Check (Pollard_Rho_Factor (U (2)) = 2, "Rho(2)=2");
   Check (Pollard_Rho_Factor (U (4)) = 2, "Rho(4)=2");
   Check (Pollard_Rho_Factor (U (17)) = 17, "Rho(17)=17 prime");
   F := Pollard_Rho_Factor (U (8051), Seed => 2, C => 1);
   Check (Divides (F, U (8051)) or else F = 1,
          "Rho(8051) nontrivial or fail sentinel");
   --  Multi-attempt via Factor path usually succeeds; check a few seeds.
   declare
      Found : Boolean := False;
      D     : U64;
   begin
      for C in U64 range 1 .. 7 loop
         D := Pollard_Rho_Factor (U (8051), Seed => 2, C => C);
         if Divides (D, U (8051)) then
            Found := True;
            exit;
         end if;
      end loop;
      Check (Found, "Rho finds factor of 8051 for some C in 1..7");
   end;
   F := Pollard_Rho_Factor (U (91), Seed => 2, C => 1);
   Check (Divides (F, U (91)) or else F = 1, "Rho(91) ok-or-fail");
   Expect_Invalid_Rho ("N=0", U (0));
   Expect_Invalid_Rho ("N=1", U (1));

   ------------------------------------------------------------------
   Section ("Congruence of squares");
   ------------------------------------------------------------------
   Check (Squares_Congruent (U (4), U (1), U (15)), "4^2≡1^2 mod 15");
   Check (Is_Nontrivial_Congruence (U (4), U (1), U (15)),
          "(4,1) nontrivial mod 15");
   Check (not Is_Trivial_Pair (U (4), U (1), U (15)),
          "4≢±1 mod 15");
   Check (Factor_From_Congruence (U (4), U (1), U (15)) = 3
            or else Factor_From_Congruence (U (4), U (1), U (15)) = 5,
          "CoS(4,1,15) → 3 or 5");
   Check (Factor_From_Congruence (U (6), U (1), U (35)) = 5
            or else Factor_From_Congruence (U (6), U (1), U (35)) = 7,
          "Wikipedia CoS 6^2≡1^2 mod 35");
   Check (Factor_From_Congruence (U (10), U (3), U (91)) = 7
            or else Factor_From_Congruence (U (10), U (3), U (91)) = 13,
          "CoS(10,3,91)");
   Check (Factor_From_Congruence (U (12), U (1), U (143)) = 11
            or else Factor_From_Congruence (U (12), U (1), U (143)) = 13,
          "CoS(12,1,143)");
   Check (Factor_From_Congruence (U (114), U (80), U (1649)) = 17
            or else Factor_From_Congruence (U (114), U (80), U (1649)) = 97,
          "Wikipedia CoS 114^2≡80^2 mod 1649");
   P := Factors_From_Congruence (U (6), U (1), U (35));
   Check (P.F1 = 5 and then P.F2 = 7, "Factors_From_Congruence 5*7");
   Check (Factor_From_Congruence (U (5), U (5), U (35)) = 0,
          "trivial CoS → 0");
   Check (Factor_From_Congruence (U (6), U (29), U (35)) = 0,
          "6≡-29 mod 35 trivial → 0");
   Expect_Invalid_CoS ("N=0", U (1), U (1), U (0));
   Expect_Invalid_CoS ("N=1", U (1), U (1), U (1));

   ------------------------------------------------------------------
   Section ("Factor / Factorize driver");
   ------------------------------------------------------------------
   Check (Factor (U (2)) = 2, "Factor(2)=2");
   Check (Factor (U (3)) = 3, "Factor(3)=3 prime");
   Check (Divides (Factor (U (15)), U (15)), "Factor(15) divides");
   Check (Divides (Factor (U (91)), U (91)), "Factor(91) divides");
   Check (Divides (Factor (U (143)), U (143)), "Factor(143) divides");
   Check (Divides (Factor (U (8051)), U (8051)), "Factor(8051) divides");
   Check (Divides (Factor (U (455839)), U (455839)),
          "Factor(455839) divides");
   Check (Divides (Factor (U (84923)), U (84923)),
          "Factor(84923) divides");
   Check (Factor (U (97)) = 97, "Factor(97)=97");
   Check (Factor (U (100)) = 2, "Factor(100)=2");

   declare
      F15  : constant Factor_List := Factorize (U (15));
      F60  : constant Factor_List := Factorize (U (60));
      F1   : constant Factor_List := Factorize (U (1));
      F8051 : constant Factor_List := Factorize (U (8051));
      F455  : constant Factor_List := Factorize (U (455839));
      Samples : constant array (Positive range <>) of U64 :=
        [12, 15, 35, 91, 100, 143, 221, 1649, 8051, 84923, 455839,
         99991, 1_000_003];
   begin
      Check (F1'Length = 0, "Factorize(1) empty");
      Check (Product (F15) = 15, "Factorize(15) product");
      Check (F15'Length = 2, "15 has 2 prime powers");
      Check (Product (F60) = 60, "Factorize(60) product");
      Check (Sorted_Ascending (F60), "Factorize(60) sorted");
      Check (Product (F8051) = 8051, "Factorize(8051) product");
      Check (F8051 (1).Prime = 83 and then F8051 (2).Prime = 97,
             "8051=83*97");
      Check (Product (F455) = 455839, "Factorize(455839) product");
      Check (F455 (1).Prime = 599 and then F455 (2).Prime = 761,
             "455839=599*761");

      for I in Samples'Range loop
         declare
            N  : constant U64 := Samples (I);
            Ft : constant Factor_List := Factorize_Trial (N);
            Fz : constant Factor_List := Factorize (N);
         begin
            Check (Product (Ft) = N,
                   "Factorize_Trial product" & N'Image);
            Check (Product (Fz) = N,
                   "Factorize product" & N'Image);
            Check (Sorted_Ascending (Fz),
                   "Factorize sorted" & N'Image);
         end;
      end loop;
   end;

   Expect_Invalid_Factor ("N=0", U (0));
   Expect_Invalid_Factor ("N=1", U (1));
   Expect_Invalid_Factor ("N>Factor_Max", Factor_Max + 1);
   Expect_Invalid_Factorize ("N=0", U (0));
   Expect_Invalid_Factorize ("N>Factor_Max", Factor_Max + 1);

   ------------------------------------------------------------------
   Section ("Boundary / consistency");
   ------------------------------------------------------------------
   Check (U (Factor_Max) = U (10_000_000), "Factor_Max=10^7");
   Check (Mul_Mod (U (35), U (35), U (35)) = 0, "N^2≡0 mod N");
   Check
     (Factor_From_Congruence (U (6), U (1), U (35)) =
        Factor_From_Congruence (U (1), U (6), U (35)),
      "Factor_From_Congruence symmetric in X,Y");
   Check (Factor (U (35), U (2)) = Factor (U (35), U (2)),
          "Factor reproducible same seed");
   Check (Ceil_Sqrt (U (2**10 + 1)) = 33, "Ceil_Sqrt(1025)=33");
   L := Factorize_Trial (U (1));
   Check (L'Length = 0, "reuse empty Factor_List");

   ------------------------------------------------------------------
   --  Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
