--  Standalone test suite for Lenstra_Elliptic_Curve_Factorization (main).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Lenstra_Elliptic_Curve_Factorization;
use Lenstra_Elliptic_Curve_Factorization;

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
   function Nat (X : Natural) return Natural is (X);

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

   procedure Expect_Invalid_Try_Inv (Label : String; A, M : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Inv_Result := Try_Mod_Inv (A, M);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Try_Mod_Inv: " & Label);
   end Expect_Invalid_Try_Inv;

   procedure Expect_Invalid_ECM
     (Label  : String;
      N      : U64;
      B      : U64;
      Curves : Natural := Default_Curves;
      Seed   : U64 := 1)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 :=
              Factor_ECM_Stage1 (N, B, Curves, Seed);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Factor_ECM_Stage1: " & Label);
   end Expect_Invalid_ECM;

   function Divides_N (F, N : U64) return Boolean is
   begin
      return F > 1 and then F < N and then N rem F = 0;
   end Divides_N;

   F : U64;
   R : Op_Result;
   IR : Inv_Result;

begin
   Ada.Text_IO.Put_Line
     ("Lenstra_Elliptic_Curve_Factorization — Ada 2023 test suite");

   ------------------------------------------------------------------
   Section ("1. Floor_Sqrt / Gcd / Mul_Mod / Add_Mod / Sub_Mod");
   ------------------------------------------------------------------
   Check (Floor_Sqrt (U (0)) = 0, "sqrt(0)=0");
   Check (Floor_Sqrt (U (1)) = 1, "sqrt(1)=1");
   Check (Floor_Sqrt (U (2)) = 1, "sqrt(2)=1");
   Check (Floor_Sqrt (U (4)) = 2, "sqrt(4)=2");
   Check (Floor_Sqrt (U (15)) = 3, "sqrt(15)=3");
   Check (Floor_Sqrt (U (16)) = 4, "sqrt(16)=4");
   Check (Floor_Sqrt (U (100)) = 10, "sqrt(100)=10");
   Check (Floor_Sqrt (U (8051)) = 89, "sqrt(8051)=89");

   Check (Gcd (U (0), U (0)) = 0, "gcd(0,0)=0");
   Check (Gcd (U (12), U (18)) = 6, "gcd(12,18)=6");
   Check (Gcd (U (17), U (13)) = 1, "gcd(17,13)=1");
   Check (Gcd (U (100), U (0)) = 100, "gcd(100,0)=100");
   Check (Gcd (U (0), U (42)) = 42, "gcd(0,42)=42");
   Check (Gcd (U (83), U (8051)) = 83, "gcd(83,8051)=83");
   Check (Gcd (U (97), U (8051)) = 97, "gcd(97,8051)=97");

   Check (Mul_Mod (U (7), U (6), U (10)) = 2, "7*6 mod 10 = 2");
   Check (Mul_Mod (U (0), U (5), U (9)) = 0, "0*5 mod 9 = 0");
   Check (Mul_Mod (U (2), U (3), U (1)) = 0, "any mod 1 = 0");
   Check (Mul_Mod (U (123456789), U (987654321), U (1_000_000_007)) =
            259_106_859,
          "large Mul_Mod");
   Expect_Invalid_Mul_Mod ("M=0", U (1), U (1), U (0));

   Check (Add_Mod (U (7), U (6), U (10)) = 3, "7+6 mod 10 = 3");
   Check (Add_Mod (U (9), U (1), U (10)) = 0, "9+1 mod 10 = 0");
   Check (Sub_Mod (U (3), U (5), U (10)) = 8, "3-5 mod 10 = 8");
   Check (Sub_Mod (U (5), U (3), U (10)) = 2, "5-3 mod 10 = 2");
   Check (Add_Mod (U (0), U (0), U (1)) = 0, "add mod 1 = 0");
   Check (Sub_Mod (U (0), U (0), U (1)) = 0, "sub mod 1 = 0");

   ------------------------------------------------------------------
   Section ("2. Try_Mod_Inv");
   ------------------------------------------------------------------
   IR := Try_Mod_Inv (U (3), U (10));
   Check (IR.Kind = Ok and then Mul_Mod (IR.Inv, U (3), U (10)) = 1,
          "inv(3) mod 10 = 7");
   IR := Try_Mod_Inv (U (2), U (10));
   Check (IR.Kind = Factor_Found and then IR.Factor = 2,
          "inv(2) mod 10 → factor 2");
   IR := Try_Mod_Inv (U (0), U (15));
   Check (IR.Kind = Factor_Found and then IR.Factor = 15,
          "inv(0) mod 15 → 15");
   IR := Try_Mod_Inv (U (5), U (35));
   Check (IR.Kind = Factor_Found and then IR.Factor = 5,
          "inv(5) mod 35 → 5");
   IR := Try_Mod_Inv (U (7), U (13));
   Check (IR.Kind = Ok and then Mul_Mod (IR.Inv, U (7), U (13)) = 1,
          "inv(7) mod 13 ok");
   Expect_Invalid_Try_Inv ("M=0", U (1), U (0));

   ------------------------------------------------------------------
   Section ("3. Is_Prime_Trial / Primes_Up_To");
   ------------------------------------------------------------------
   Check (not Is_Prime_Trial (U (0)), "0 not prime");
   Check (not Is_Prime_Trial (U (1)), "1 not prime");
   Check (Is_Prime_Trial (U (2)), "2 is prime");
   Check (Is_Prime_Trial (U (3)), "3 is prime");
   Check (not Is_Prime_Trial (U (4)), "4 not prime");
   Check (Is_Prime_Trial (U (5)), "5 is prime");
   Check (not Is_Prime_Trial (U (9)), "9 not prime");
   Check (Is_Prime_Trial (U (83)), "83 is prime");
   Check (Is_Prime_Trial (U (97)), "97 is prime");
   Check (not Is_Prime_Trial (U (8051)), "8051 not prime");
   Check (Is_Prime_Trial (U (599)), "599 is prime");
   Check (Is_Prime_Trial (U (761)), "761 is prime");
   Check (not Is_Prime_Trial (U (455839)), "455839 not prime");
   Check (Is_Prime_Trial (U (7919)), "7919 is prime");

   declare
      P0  : constant U64_Array := Primes_Up_To (U (0));
      P1  : constant U64_Array := Primes_Up_To (U (1));
      P2  : constant U64_Array := Primes_Up_To (U (2));
      P10 : constant U64_Array := Primes_Up_To (U (10));
      P30 : constant U64_Array := Primes_Up_To (U (30));
   begin
      Check (P0'Length = 0, "Primes_Up_To(0) empty");
      Check (P1'Length = 0, "Primes_Up_To(1) empty");
      Check (P2'Length = 1 and then P2 (1) = 2, "Primes_Up_To(2)=[2]");
      Check (P10'Length = 4, "Primes_Up_To(10) length 4");
      Check (P10 (1) = 2 and then P10 (2) = 3 and then P10 (3) = 5
               and then P10 (4) = 7,
             "Primes_Up_To(10)=[2,3,5,7]");
      Check (P30'Length = 10, "π(30)=10");
      Check (P30 (10) = 29, "last prime ≤30 is 29");
   end;

   ------------------------------------------------------------------
   Section ("4. Point Add / Double / Scalar_Mult (prime field)");
   ------------------------------------------------------------------
   declare
      --  Curve y² = x³ + 1 over F_7; point (0,1): 1 = 0 + 0 + 1.
      C7 : constant Curve := (A => 0, B => 1, N => 7);
      P0 : constant Point := (X => 0, Y => 1, Infinity => False);
      Inf : constant Point := (X => 0, Y => 0, Infinity => True);
   begin
      R := Double (Inf, C7);
      Check (R.Kind = Ok and then R.P.Infinity, "2·O = O");

      R := Add (P0, Inf, C7);
      Check (R.Kind = Ok and then R.P.X = 0 and then R.P.Y = 1,
             "P + O = P");

      R := Add (Inf, P0, C7);
      Check (R.Kind = Ok and then not R.P.Infinity, "O + P = P");

      --  −P = (0, −1) = (0,6) mod 7; P + (−P) = O
      R := Add (P0, (X => 0, Y => 6, Infinity => False), C7);
      Check (R.Kind = Ok and then R.P.Infinity, "P + (−P) = O");

      R := Scalar_Mult (U (0), P0, C7);
      Check (R.Kind = Ok and then R.P.Infinity, "0·P = O");

      R := Scalar_Mult (U (1), P0, C7);
      Check (R.Kind = Ok and then R.P.X = 0 and then R.P.Y = 1,
             "1·P = P");

      R := Scalar_Mult (U (7), P0, C7);
      --  Over F_7 group order divides ≤ 7+1+2√7 ≈ 13; 7P may or may not
      --  be O — just require Ok.
      Check (R.Kind = Ok, "7·P on F_7 succeeds");
   end;

   ------------------------------------------------------------------
   Section ("5. Domain errors N<2 / B<2 / Curves=0");
   ------------------------------------------------------------------
   Expect_Invalid_ECM ("N=0", U (0), U (10));
   Expect_Invalid_ECM ("N=1", U (1), U (10));
   Expect_Invalid_ECM ("B=0", U (35), U (0));
   Expect_Invalid_ECM ("B=1", U (35), U (1));
   Expect_Invalid_ECM ("Curves=0", U (35), U (10), Curves => 0);

   ------------------------------------------------------------------
   Section ("6. Even / primes → 1");
   ------------------------------------------------------------------
   Check (Factor_ECM_Stage1 (U (2), U (10)) = 2, "ECM(2)=2");
   Check (Factor_ECM_Stage1 (U (4), U (10)) = 2, "ECM(4)=2");
   Check (Factor_ECM_Stage1 (U (6), U (10)) = 2, "ECM(6)=2");
   Check (Factor (U (100)) = 2, "Factor(100)=2");
   Check (Factor_ECM_Stage1 (U (13), U (20)) = 1, "ECM(13)=1 prime");
   Check (Factor_ECM_Stage1 (U (23), U (20)) = 1, "ECM(23)=1 prime");
   Check (Factor_ECM_Stage1 (U (97), U (50)) = 1, "ECM(97)=1 prime");
   Check (Factor (U (97)) = 1, "Factor(97)=1");
   Check (Factor (U (101)) = 1, "Factor(101)=1");
   Check (Factor (U (7919)) = 1, "Factor(7919)=1");
   Check (Factor (U (3)) = 1, "Factor(3)=1");
   Check (Factor (U (5)) = 1, "Factor(5)=1");
   Check (Factor (U (83)) = 1, "Factor(83)=1");
   Check (Factor (U (599)) = 1, "Factor(599)=1");

   ------------------------------------------------------------------
   Section ("7. Known small composites 35, 91");
   ------------------------------------------------------------------
   F := Factor_ECM_Stage1 (U (35), U (20), Curves => 30, Seed => 1);
   Check (F = 5 or else F = 7, "ECM(35) in {5,7}");
   Check (Divides_N (F, U (35)), "35 factor divides");

   F := Factor_ECM_Stage1 (U (91), U (30), Curves => 40, Seed => 1);
   Check (F = 7 or else F = 13, "ECM(91) in {7,13}");
   Check (Divides_N (F, U (91)), "91 factor divides");

   F := Factor (U (35), B => 20);
   Check (Divides_N (F, U (35)), "Factor(35) divides");

   F := Factor (U (91), B => 30);
   Check (Divides_N (F, U (91)), "Factor(91) divides");

   ------------------------------------------------------------------
   Section ("8. Known composites 8051 = 83 x 97");
   ------------------------------------------------------------------
   F := Factor_ECM_Stage1 (U (8051), U (50), Curves => 50, Seed => 1);
   Check (F = 83 or else F = 97, "ECM(8051) in {83,97}");
   Check (Divides_N (F, U (8051)), "8051 factor divides");

   F := Factor_ECM_Stage1 (U (8051), U (40), Curves => 30, Seed => 1);
   Check (Divides_N (F, U (8051)), "ECM(8051,B=40) divides");

   F := Factor (U (8051), B => 50, Seed => 1);
   Check (Divides_N (F, U (8051)), "Factor(8051) divides");

   ------------------------------------------------------------------
   Section ("9. Known composite 455839 = 599 x 761");
   ------------------------------------------------------------------
   F := Factor_ECM_Stage1
     (U (455839), U (100), Curves => 80, Seed => 1);
   Check (F = 599 or else F = 761, "ECM(455839) in {599,761}");
   Check (Divides_N (F, U (455839)), "455839 factor divides");

   F := Factor (U (455839), B => 100, Seed => 1);
   Check (Divides_N (F, U (455839)), "Factor(455839) divides");

   ------------------------------------------------------------------
   Section ("10. More semiprimes / powers");
   ------------------------------------------------------------------
   F := Factor_ECM_Stage1 (U (143), U (30), Curves => 40, Seed => 2);
   --  11*13
   Check (F = 11 or else F = 13, "ECM(143=11*13)");
   Check (Divides_N (F, U (143)), "143 factor divides");

   F := Factor_ECM_Stage1 (U (187), U (30), Curves => 40, Seed => 3);
   --  11*17
   Check (Divides_N (F, U (187)), "ECM(187=11*17) divides");

   F := Factor_ECM_Stage1 (U (319), U (40), Curves => 50, Seed => 4);
   --  11*29
   Check (Divides_N (F, U (319)), "ECM(319=11*29) divides");

   F := Factor_ECM_Stage1 (U (1147), U (50), Curves => 50, Seed => 5);
   --  31*37
   Check (Divides_N (F, U (1147)), "ECM(1147=31*37) divides");

   F := Factor_ECM_Stage1 (U (2047), U (50), Curves => 60, Seed => 6);
   --  23*89 (Mersenne composite)
   Check (Divides_N (F, U (2047)), "ECM(2047=23*89) divides");

   F := Factor_ECM_Stage1 (U (121), U (20), Curves => 30, Seed => 7);
   --  11^2
   Check (F = 11, "ECM(121=11^2)=11");

   F := Factor_ECM_Stage1 (U (169), U (20), Curves => 30, Seed => 8);
   Check (F = 13, "ECM(169=13^2)=13");

   F := Factor_ECM_Stage1 (U (15), U (10), Curves => 20, Seed => 1);
   Check (F = 3 or else F = 5, "ECM(15) in {3,5}");

   F := Factor_ECM_Stage1 (U (21), U (10), Curves => 20, Seed => 1);
   Check (F = 3 or else F = 7, "ECM(21) in {3,7}");

   F := Factor_ECM_Stage1 (U (33), U (15), Curves => 25, Seed => 1);
   Check (F = 3 or else F = 11, "ECM(33) in {3,11}");

   F := Factor_ECM_Stage1 (U (39), U (15), Curves => 25, Seed => 1);
   Check (F = 3 or else F = 13, "ECM(39) in {3,13}");

   F := Factor_ECM_Stage1 (U (55), U (20), Curves => 30, Seed => 1);
   Check (F = 5 or else F = 11, "ECM(55) in {5,11}");

   F := Factor_ECM_Stage1 (U (77), U (20), Curves => 30, Seed => 1);
   Check (F = 7 or else F = 11, "ECM(77) in {7,11}");

   ------------------------------------------------------------------
   Section ("11. Add/Double expose factor mod composite N");
   ------------------------------------------------------------------
   declare
      --  Force a non-invertible denominator: den = x2-x1 sharing factor.
      --  Use Scalar_Mult path which is already covered; also check
      --  Try_Mod_Inv path used by Add when X coincide mod p but not N.
      CN : constant Curve := (A => 1, B => 1, N => 35);
      --  Points that are equal mod 5 but not mod 35 can yield factor 5.
      P1 : constant Point := (X => 2, Y => 4, Infinity => False);
      P2 : constant Point := (X => 7, Y => 9, Infinity => False);
      --  x2-x1 = 5; gcd(5,35)=5
   begin
      R := Add (P1, P2, CN);
      Check (R.Kind = Factor_Found and then R.Factor = 5,
             "Add mod 35 exposes factor 5");
   end;

   ------------------------------------------------------------------
   Section ("12. Defaults / Factor wrapper / miss bound");
   ------------------------------------------------------------------
   Check (U (Default_B) = U (50), "Default_B = 50");
   Check (Nat (Default_Curves) = Nat (40), "Default_Curves = 40");

   --  Very small B may miss; still a valid return of 1 (no crash).
   F := Factor_ECM_Stage1
     (U (8051), U (2), Curves => 3, Seed => 99);
   Check (F = 1 or else Divides_N (F, U (8051)),
          "tiny B: miss (1) or lucky factor");

   F := Factor (U (35));
   Check (Divides_N (F, U (35)), "Factor(35) default B divides");

   --  Seed stability: same seed → same result for a fixed easy N
   declare
      F1 : constant U64 :=
        Factor_ECM_Stage1 (U (35), U (20), 30, Seed => 42);
      F2 : constant U64 :=
        Factor_ECM_Stage1 (U (35), U (20), 30, Seed => 42);
   begin
      Check (F1 = F2, "same Seed → same Factor_ECM_Stage1");
      Check (Divides_N (F1, U (35)), "seed 42 factors 35");
   end;

   ------------------------------------------------------------------
   --  Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line (
     "Result:" & Natural'Image (Pass_Count) & " PASS,"
     & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
