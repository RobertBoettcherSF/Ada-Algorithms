--  Standalone test suite for Dixon (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Dixon; use Dixon;

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

   procedure Expect_Invalid_Smooth (Label : String; N : U64) is
      Raised : Boolean := False;
      Base   : constant Factor_Base := [2, 3, 5];
   begin
      begin
         declare
            Unused : constant Boolean := Is_B_Smooth (N, Base);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Is_B_Smooth: " & Label);
   end Expect_Invalid_Smooth;

   procedure Expect_Invalid_Dixon (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Factor_Dixon (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Factor_Dixon: " & Label);
   end Expect_Invalid_Dixon;

   function Divides_N (F, N : U64) return Boolean is
   begin
      return F > 1 and then F < N and then N rem F = 0;
   end Divides_N;

begin
   Ada.Text_IO.Put_Line ("Dixon — Ada 2023 test suite");

   ------------------------------------------------------------------
   Section ("1. Floor_Sqrt / Gcd / Mul_Mod / Mod_Pow");
   ------------------------------------------------------------------
   Check (Floor_Sqrt (U (0)) = 0, "sqrt(0)=0");
   Check (Floor_Sqrt (U (1)) = 1, "sqrt(1)=1");
   Check (Floor_Sqrt (U (4)) = 2, "sqrt(4)=2");
   Check (Floor_Sqrt (U (15)) = 3, "sqrt(15)=3");
   Check (Floor_Sqrt (U (16)) = 4, "sqrt(16)=4");
   Check (Floor_Sqrt (U (100)) = 10, "sqrt(100)=10");
   Check (Floor_Sqrt (U (8051)) = 89, "sqrt(8051)=89");
   Check (Floor_Sqrt (U (84923)) = 291, "sqrt(84923)=291");

   Check (Gcd (U (0), U (0)) = 0, "gcd(0,0)=0");
   Check (Gcd (U (12), U (18)) = 6, "gcd(12,18)=6");
   Check (Gcd (U (17), U (13)) = 1, "gcd(17,13)=1");
   Check (Gcd (U (100), U (0)) = 100, "gcd(100,0)=100");
   Check (Gcd (U (83), U (97)) = 1, "gcd(83,97)=1");
   Check (Gcd (U (163), U (521)) = 1, "gcd(163,521)=1");
   Check (Gcd (U (3912), U (84923)) = 163, "wiki gcd(3912,84923)=163");

   Check (Mul_Mod (U (7), U (6), U (10)) = 2, "7*6 mod 10 = 2");
   Check (Mul_Mod (U (0), U (5), U (9)) = 0, "0*5 mod 9 = 0");
   Check (Mul_Mod (U (90), U (90), U (8051)) = 49, "90^2 mod 8051");
   Check (Mul_Mod (U (513), U (513), U (84923)) = 8400, "513^2 mod 84923");
   Check (Mul_Mod (U (537), U (537), U (84923)) = 33600, "537^2 mod 84923");
   Expect_Invalid_Mul_Mod ("M=0", U (1), U (1), U (0));

   Check (Mod_Pow (U (2), U (10), U (1000)) = 24, "2^10 mod 1000");
   Check (Mod_Pow (U (3), U (0), U (7)) = 1, "3^0 mod 7 = 1");
   Check (Mod_Pow (U (5), U (3), U (13)) = 8, "5^3 mod 13 = 8");
   Check (Mod_Pow (U (2), U (5), U (1000)) = 32, "2^5 mod 1000");

   ------------------------------------------------------------------
   Section ("2. Trial helpers");
   ------------------------------------------------------------------
   Check (not Is_Prime_Trial (U (0)), "0 not prime");
   Check (not Is_Prime_Trial (U (1)), "1 not prime");
   Check (Is_Prime_Trial (U (2)), "2 prime");
   Check (Is_Prime_Trial (U (3)), "3 prime");
   Check (not Is_Prime_Trial (U (4)), "4 composite");
   Check (Is_Prime_Trial (U (97)), "97 prime");
   Check (Is_Prime_Trial (U (83)), "83 prime");
   Check (Is_Prime_Trial (U (163)), "163 prime");
   Check (Is_Prime_Trial (U (521)), "521 prime");
   Check (not Is_Prime_Trial (U (91)), "91=7*13");
   Check (not Is_Prime_Trial (U (8051)), "8051 composite");
   Check (not Is_Prime_Trial (U (84923)), "84923 composite");
   Check (not Is_Prime_Trial (U (455839)), "455839 composite");

   Check (Smallest_Prime_Factor (U (2)) = 2, "SPF(2)=2");
   Check (Smallest_Prime_Factor (U (15)) = 3, "SPF(15)=3");
   Check (Smallest_Prime_Factor (U (8051)) = 83, "SPF(8051)=83");
   Check (Smallest_Prime_Factor (U (97)) = 97, "SPF(97)=97");
   Check (Smallest_Prime_Factor (U (84923)) = 163, "SPF(84923)=163");

   ------------------------------------------------------------------
   Section ("3. Smoothness / Primes_Up_To / Dixon_Factor_Base");
   ------------------------------------------------------------------
   declare
      FB10 : constant Factor_Base := Primes_Up_To (U (10));
      FB1  : constant Factor_Base := Primes_Up_To (U (1));
      FB20 : constant Factor_Base := Primes_Up_To (U (20));
      FB7  : constant Factor_Base := Dixon_Factor_Base (U (7));
   begin
      Check (FB1'Length = 0, "primes <= 1 empty");
      Check (FB10'Length = 4, "primes <= 10: 2,3,5,7");
      Check (FB10 (FB10'First) = 2, "first prime 2");
      Check (FB10 (FB10'Last) = 7, "last prime 7");
      Check (FB20'Length = 8, "primes <= 20: eight");
      Check (FB7'Length = 4, "Dixon FB(7) = {2,3,5,7}");
      Check (FB7 (FB7'First) = 2, "Dixon FB starts with 2");
      Check (FB7 (FB7'Last) = 7, "Dixon FB ends with 7");

      Check (Is_B_Smooth (U (1), FB10), "1 is smooth");
      Check (Is_B_Smooth (U (8), FB10), "8=2^3 smooth");
      Check (Is_B_Smooth (U (30), FB10), "30=2*3*5 smooth");
      Check (Is_B_Smooth (U (210), FB10), "210=2*3*5*7 smooth");
      Check (not Is_B_Smooth (U (11), FB10), "11 not FB10-smooth");
      Check (not Is_B_Smooth (U (22), FB10), "22 has prime 11");
      Check (Is_B_Smooth (U (49), FB10), "49=7^2 smooth");
      Check (not Is_B_Smooth (U (121), FB10), "121=11^2 not smooth");
      Check (Is_B_Smooth (U (8400), FB7), "8400=2^4*3*5^2*7 wiki");
      Check (Is_B_Smooth (U (33600), FB7), "33600=2^6*3*5^2*7 wiki");
      Check (not Is_B_Smooth (U (34675), FB7), "34675 has 19,73");

      declare
         E : constant Exponent_Vector :=
           Smooth_Exponents (U (360), FB10);
      begin
         Check (E (FB10'First) = 3, "360: exp 2 = 3");
         Check (E (FB10'First + 1) = 2, "360: exp 3 = 2");
         Check (E (FB10'First + 2) = 1, "360: exp 5 = 1");
         Check (E (FB10'First + 3) = 0, "360: exp 7 = 0");
      end;

      declare
         E8400 : constant Exponent_Vector :=
           Smooth_Exponents (U (8400), FB7);
      begin
         Check (E8400 (FB7'First) = 4, "8400: exp 2 = 4");
         Check (E8400 (FB7'First + 1) = 1, "8400: exp 3 = 1");
         Check (E8400 (FB7'First + 2) = 2, "8400: exp 5 = 2");
         Check (E8400 (FB7'First + 3) = 1, "8400: exp 7 = 1");
      end;
   end;
   Expect_Invalid_Smooth ("0", U (0));

   declare
      FB : constant Factor_Base := Dixon_Factor_Base (U (0));
   begin
      Check (FB'Length = 0, "Dixon FB(0) empty");
   end;

   ------------------------------------------------------------------
   Section ("4. Congruence of squares — known tiny cases");
   ------------------------------------------------------------------
   declare
      N15  : constant U64 := 15;
      Base : constant Factor_Base := [2, 3, 5, 7];
      Rels : constant Relation_List := [(A => 4, B => 1)];
      F    : constant U64 :=
        Factor_Via_Congruence_Of_Squares (N15, Rels, Base);
   begin
      Check (Divides_N (F, N15), "15 via CoS (4^2≡1)");
      Check (F = 3 or else F = 5, "15 factor is 3 or 5");
   end;

   declare
      N91  : constant U64 := 91;
      Base : constant Factor_Base := [2, 3, 5, 7, 11, 13];
      Rels : constant Relation_List := [(A => 10, B => 9)];
      F    : constant U64 :=
        Factor_Via_Congruence_Of_Squares (N91, Rels, Base);
   begin
      Check (Divides_N (F, N91), "91 via CoS (10^2≡9)");
      Check (F = 7 or else F = 13, "91 factor is 7 or 13");
   end;

   declare
      N143 : constant U64 := 143;
      Base : constant Factor_Base := [2, 3, 5, 7, 11];
      Rels : constant Relation_List := [(A => 12, B => 1)];
      F    : constant U64 :=
        Factor_Via_Congruence_Of_Squares (N143, Rels, Base);
   begin
      Check (Divides_N (F, N143), "143 via CoS (12^2≡1)");
      Check (F = 11 or else F = 13, "143 factor 11 or 13");
   end;

   --  Wikipedia Dixon example N=84923 with 513 and 537.
   declare
      N84923 : constant U64 := 84923;
      Base   : constant Factor_Base := [2, 3, 5, 7];
      Rels   : constant Relation_List :=
        [(A => 513, B => 8400), (A => 537, B => 33600)];
      F      : constant U64 :=
        Factor_Via_Congruence_Of_Squares (N84923, Rels, Base);
   begin
      Check (Mul_Mod (U (513), U (513), N84923) = 8400,
             "513^2 rem 84923 = 8400");
      Check (Mul_Mod (U (537), U (537), N84923) = 33600,
             "537^2 rem 84923 = 33600");
      Check (Divides_N (F, N84923), "84923 via CoS wiki Dixon");
      Check (F = 163 or else F = 521, "84923 factor 163 or 521");
   end;

   --  Product smooth residues N=1649=17*97.
   declare
      N1649 : constant U64 := 1649;
      Base  : constant Factor_Base := [2, 3, 5];
      Rels  : constant Relation_List :=
        [(A => 41, B => 32), (A => 43, B => 200)];
      F     : constant U64 :=
        Factor_Via_Congruence_Of_Squares (N1649, Rels, Base);
   begin
      Check (Mul_Mod (U (41), U (41), N1649) = 32, "41^2 rem 1649 = 32");
      Check (Mul_Mod (U (43), U (43), N1649) = 200, "43^2 rem 1649 = 200");
      Check (Divides_N (F, N1649), "1649 via CoS");
      Check (F = 17 or else F = 97, "1649 factor 17 or 97");
   end;

   ------------------------------------------------------------------
   Section ("5. Factor_Dixon / Factor — known small semiprimes");
   ------------------------------------------------------------------
   Expect_Invalid_Dixon ("0", U (0));
   Expect_Invalid_Dixon ("too big", U (10_000_001));

   Check (Factor_Dixon (U (1)) = 1, "Dixon(1)=1");
   Check (Factor_Dixon (U (2)) = 1, "Dixon(2)=1 prime");
   Check (Factor_Dixon (U (3)) = 1, "Dixon(3)=1 prime");
   Check (Factor_Dixon (U (4)) = 2, "Dixon(4)=2");
   Check (Factor_Dixon (U (9)) = 3, "Dixon(9)=3");
   Check (Factor_Dixon (U (97)) = 1, "Dixon(97)=1 prime");
   Check (Factor (U (4)) = 2, "Factor alias (4)=2");

   declare
      F15 : constant U64 := Factor_Dixon (U (15), 20);
   begin
      Check (Divides_N (F15, U (15)), "Dixon(15) nontrivial");
      Check (F15 = 3 or else F15 = 5, "Dixon(15) in {3,5}");
   end;

   declare
      F91 : constant U64 := Factor_Dixon (U (91), 30);
   begin
      Check (Divides_N (F91, U (91)), "Dixon(91) nontrivial");
      Check (F91 = 7 or else F91 = 13, "Dixon(91) in {7,13}");
   end;

   declare
      F143 : constant U64 := Factor_Dixon (U (143), 30);
   begin
      Check (Divides_N (F143, U (143)), "Dixon(143) nontrivial");
      Check (F143 = 11 or else F143 = 13, "Dixon(143) in {11,13}");
   end;

   declare
      F8051 : constant U64 := Factor_Dixon (U (8051), 60);
   begin
      Check (Divides_N (F8051, U (8051)), "Dixon(8051) nontrivial");
      Check (F8051 = 83 or else F8051 = 97, "Dixon(8051) in {83,97}");
   end;

   declare
      F1649 : constant U64 := Factor_Dixon (U (1649), 40);
   begin
      Check (Divides_N (F1649, U (1649)), "Dixon(1649) nontrivial");
      Check (F1649 = 17 or else F1649 = 97, "Dixon(1649) in {17,97}");
   end;

   declare
      F84923 : constant U64 := Factor_Dixon (U (84923), 30, 42);
   begin
      Check (Divides_N (F84923, U (84923)), "Dixon(84923) nontrivial");
      Check (F84923 = 163 or else F84923 = 521,
             "Dixon(84923) in {163,521}");
   end;

   declare
      F1147 : constant U64 := Factor_Dixon (U (1147), 40);
   begin
      Check (Divides_N (F1147, U (1147)), "Dixon(1147=31*37)");
      Check (F1147 = 31 or else F1147 = 37, "1147 factor");
   end;

   declare
      F1517 : constant U64 := Factor_Dixon (U (1517), 40);
   begin
      Check (Divides_N (F1517, U (1517)), "Dixon(1517=37*41)");
      Check (F1517 = 37 or else F1517 = 41, "1517 factor");
   end;

   declare
      F10403 : constant U64 := Factor_Dixon (U (10403), 80);
   begin
      Check (Divides_N (F10403, U (10403)), "Dixon(10403=101*103)");
      Check (F10403 = 101 or else F10403 = 103, "10403 factor");
   end;

   declare
      F455839 : constant U64 := Factor_Dixon (U (455839), 200);
   begin
      Check (Divides_N (F455839, U (455839)), "Dixon(455839=599*761)");
      Check (F455839 = 599 or else F455839 = 761, "455839 factor");
   end;

   declare
      F187 : constant U64 := Factor_Dixon (U (187), 30);
   begin
      Check (Divides_N (F187, U (187)), "Dixon(187=11*17)");
      Check (F187 = 11 or else F187 = 17, "187 factor");
   end;

   declare
      F221 : constant U64 := Factor (U (221), 30);
   begin
      Check (Divides_N (F221, U (221)), "Factor(221=13*17)");
      Check (F221 = 13 or else F221 = 17, "221 factor");
   end;

   Check (Factor_Dixon (U (100)) = 2, "Dixon(100)=2");
   Check (Factor_Dixon (U (2047), 40) = 23
            or else Factor_Dixon (U (2047), 40) = 89,
          "Dixon(2047) in {23,89}");

   ------------------------------------------------------------------
   Section ("6. CoS validation / edges / extra helpers");
   ------------------------------------------------------------------
   declare
      Raised : Boolean := False;
      Base   : constant Factor_Base := [2, 3, 5];
      Bad    : constant Relation_List :=
        [(A => 4, B => 2)];  --  4^2 rem 15 = 1, not 2
   begin
      begin
         declare
            Unused : constant U64 :=
              Factor_Via_Congruence_Of_Squares (15, Bad, Base);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "CoS rejects B mismatch");
   end;

   declare
      Raised : Boolean := False;
      Base   : constant Factor_Base := [2, 3, 5];
      Bad    : constant Relation_List := [(A => 4, B => 1)];
   begin
      begin
         declare
            Unused : constant U64 :=
              Factor_Via_Congruence_Of_Squares (0, Bad, Base);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "CoS rejects N=0");
   end;

   declare
      Raised : Boolean := False;
      Base   : constant Factor_Base := [2, 3, 5];
      Bad    : constant Relation_List :=
        [(A => 5, B => 11)];  --  5^2 rem 15 = 10, and 11 not smooth anyway
   begin
      begin
         declare
            Unused : constant U64 :=
              Factor_Via_Congruence_Of_Squares (15, Bad, Base);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "CoS rejects non-smooth / mismatch");
   end;

   declare
      FB : constant Factor_Base := Primes_Up_To (U (30));
   begin
      Check (FB'Length = 10, "pi(30)=10");
      Check (Is_B_Smooth (U (2310), FB), "2310=2*3*5*7*11");
      Check (not Is_B_Smooth (U (2310 * 37), FB), "37 not in FB30");
   end;

   declare
      R : constant U64 := Floor_Sqrt (U (455839));
   begin
      Check (R * R <= U (455839)
               and then (R + 1) * (R + 1) > U (455839),
             "floor_sqrt(455839) consistent");
   end;

   declare
      Big : constant U64 := Mul_Mod (U (2 ** 32), U (2 ** 32), U (2 ** 32 + 1));
   begin
      Check (Big = U (1), "Mul_Mod (2^32)^2 mod (2^32+1) = 1");
   end;

   declare
      Max_N : constant U64 := Factor_Dixon_Max;
   begin
      Check (Max_N = U (10_000_000), "Factor_Dixon_Max=10^7");
   end;

   --  Seed reproducibility: same seed → same factor result for tiny N.
   declare
      F1 : constant U64 := Factor_Dixon (U (15), 20, 7);
      F2 : constant U64 := Factor_Dixon (U (15), 20, 7);
   begin
      Check (F1 = F2, "same seed → same Dixon(15) result");
      Check (Divides_N (F1, U (15)), "seeded Dixon(15) nontrivial");
   end;

   ------------------------------------------------------------------
   --  Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line (
     "Result: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");
   if Fail_Count > 0 or else Pass_Count < 80 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
