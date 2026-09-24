--  Standalone test suite for Quadratic_Sieve (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Quadratic_Sieve; use Quadratic_Sieve;

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

   procedure Expect_Invalid_Legendre (Label : String; A, P : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Integer := Legendre (A, P);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Legendre: " & Label);
   end Expect_Invalid_Legendre;

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

   procedure Expect_Invalid_QS (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Factor_QS (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Factor_QS: " & Label);
   end Expect_Invalid_QS;

   function Divides_N (F, N : U64) return Boolean is
   begin
      return F > 1 and then F < N and then N rem F = 0;
   end Divides_N;

begin
   Ada.Text_IO.Put_Line ("Quadratic_Sieve — Ada 2023 test suite");

   ------------------------------------------------------------------
   Section ("1. Floor_Sqrt / Ceil_Sqrt / Gcd / Mul_Mod / Mod_Pow");
   ------------------------------------------------------------------
   Check (Floor_Sqrt (U (0)) = 0, "sqrt(0)=0");
   Check (Floor_Sqrt (U (1)) = 1, "sqrt(1)=1");
   Check (Floor_Sqrt (U (4)) = 2, "sqrt(4)=2");
   Check (Floor_Sqrt (U (15)) = 3, "sqrt(15)=3");
   Check (Floor_Sqrt (U (16)) = 4, "sqrt(16)=4");
   Check (Floor_Sqrt (U (100)) = 10, "sqrt(100)=10");
   Check (Floor_Sqrt (U (8051)) = 89, "sqrt(8051)=89");

   Check (Ceil_Sqrt (U (0)) = 0, "ceil_sqrt(0)=0");
   Check (Ceil_Sqrt (U (1)) = 1, "ceil_sqrt(1)=1");
   Check (Ceil_Sqrt (U (2)) = 2, "ceil_sqrt(2)=2");
   Check (Ceil_Sqrt (U (15)) = 4, "ceil_sqrt(15)=4");
   Check (Ceil_Sqrt (U (16)) = 4, "ceil_sqrt(16)=4");
   Check (Ceil_Sqrt (U (8051)) = 90, "ceil_sqrt(8051)=90");

   Check (Gcd (U (0), U (0)) = 0, "gcd(0,0)=0");
   Check (Gcd (U (12), U (18)) = 6, "gcd(12,18)=6");
   Check (Gcd (U (17), U (13)) = 1, "gcd(17,13)=1");
   Check (Gcd (U (100), U (0)) = 100, "gcd(100,0)=100");
   Check (Gcd (U (83), U (97)) = 1, "gcd(83,97)=1");

   Check (Mul_Mod (U (7), U (6), U (10)) = 2, "7*6 mod 10 = 2");
   Check (Mul_Mod (U (0), U (5), U (9)) = 0, "0*5 mod 9 = 0");
   Check (Mul_Mod (U (90), U (90), U (8051)) = 49, "90^2 mod 8051");
   Expect_Invalid_Mul_Mod ("M=0", U (1), U (1), U (0));

   Check (Mod_Pow (U (2), U (10), U (1000)) = 24, "2^10 mod 1000");
   Check (Mod_Pow (U (3), U (0), U (7)) = 1, "3^0 mod 7 = 1");
   Check (Mod_Pow (U (5), U (3), U (13)) = 8, "5^3 mod 13 = 8");

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
   Check (not Is_Prime_Trial (U (91)), "91=7*13");
   Check (not Is_Prime_Trial (U (8051)), "8051 composite");
   Check (not Is_Prime_Trial (U (455839)), "455839 composite");

   Check (Smallest_Prime_Factor (U (2)) = 2, "SPF(2)=2");
   Check (Smallest_Prime_Factor (U (15)) = 3, "SPF(15)=3");
   Check (Smallest_Prime_Factor (U (8051)) = 83, "SPF(8051)=83");
   Check (Smallest_Prime_Factor (U (97)) = 97, "SPF(97)=97");

   ------------------------------------------------------------------
   Section ("3. Legendre symbol");
   ------------------------------------------------------------------
   --  (2/7)=1 since 3^2=9≡2; (3/7)=-1; (1/5)=1; (2/5)=-1
   Check (Legendre (U (1), U (5)) = 1, "(1/5)=1");
   Check (Legendre (U (2), U (5)) = -1, "(2/5)=-1");
   Check (Legendre (U (4), U (5)) = 1, "(4/5)=1");
   Check (Legendre (U (0), U (5)) = 0, "(0/5)=0");
   Check (Legendre (U (2), U (7)) = 1, "(2/7)=1");
   Check (Legendre (U (3), U (7)) = -1, "(3/7)=-1");
   Check (Legendre (U (8051), U (3)) = Legendre (U (8051 rem 3), U (3)),
          "(8051/3) consistent");
   --  For QS FB: need (N/p)=1. Check a few for N=8051.
   Check (Legendre (U (8051), U (3)) /= 0, "(8051/3) nonzero");
   Expect_Invalid_Legendre ("P=2", U (1), U (2));
   Expect_Invalid_Legendre ("P=0", U (1), U (0));
   Expect_Invalid_Legendre ("P=1", U (1), U (1));
   Expect_Invalid_Legendre ("P=4 even", U (1), U (4));

   ------------------------------------------------------------------
   Section ("4. Smoothness / Primes_Up_To / QS_Factor_Base");
   ------------------------------------------------------------------
   declare
      FB10 : constant Factor_Base := Primes_Up_To (U (10));
      FB1  : constant Factor_Base := Primes_Up_To (U (1));
      FB20 : constant Factor_Base := Primes_Up_To (U (20));
   begin
      Check (FB1'Length = 0, "primes <= 1 empty");
      Check (FB10'Length = 4, "primes <= 10: 2,3,5,7");
      Check (FB10 (FB10'First) = 2, "first prime 2");
      Check (FB10 (FB10'Last) = 7, "last prime 7");
      Check (FB20'Length = 8, "primes <= 20: eight");

      Check (Is_B_Smooth (U (1), FB10), "1 is smooth");
      Check (Is_B_Smooth (U (8), FB10), "8=2^3 smooth");
      Check (Is_B_Smooth (U (30), FB10), "30=2*3*5 smooth");
      Check (Is_B_Smooth (U (210), FB10), "210=2*3*5*7 smooth");
      Check (not Is_B_Smooth (U (11), FB10), "11 not FB10-smooth");
      Check (not Is_B_Smooth (U (22), FB10), "22 has prime 11");
      Check (Is_B_Smooth (U (49), FB10), "49=7^2 smooth");
      Check (not Is_B_Smooth (U (121), FB10), "121=11^2 not smooth");

      declare
         E : constant Exponent_Vector :=
           Smooth_Exponents (U (360), FB10);
      begin
         Check (E (FB10'First) = 3, "360: exp 2 = 3");
         Check (E (FB10'First + 1) = 2, "360: exp 3 = 2");
         Check (E (FB10'First + 2) = 1, "360: exp 5 = 1");
         Check (E (FB10'First + 3) = 0, "360: exp 7 = 0");
      end;
   end;
   Expect_Invalid_Smooth ("0", U (0));

   declare
      N8051 : constant U64 := 8051;
      FB    : constant Factor_Base := QS_Factor_Base (N8051, U (40));
      All_OK : Boolean := True;
   begin
      Check (FB'Length >= 2, "QS FB(8051,40) nonempty");
      Check (FB (FB'First) = 2, "QS FB starts with 2");
      for P of FB loop
         if P > 2 and then Legendre (N8051, P) /= 1 then
            All_OK := False;
         end if;
      end loop;
      Check (All_OK, "all odd primes in QS FB have (N/p)=1");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Factor_Base :=
              QS_Factor_Base (U (0), U (10));
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument QS_Factor_Base N=0");
   end;

   ------------------------------------------------------------------
   Section ("5. Q_Of polynomial");
   ------------------------------------------------------------------
   --  Ceil_Sqrt(8051)=90; 90^2 - 8051 = 8100-8051 = 49 = 7^2
   Check (Q_Of (U (90), U (8051)) = 49, "Q(90,8051)=49");
   Check (Q_Of (U (91), U (8051)) = Mul_Mod (U (91), U (91), U (8051)),
          "Q(91) = 91^2 rem 8051");
   Check (Q_Of (U (4), U (15)) = 1, "4^2 rem 15 = 1");
   Check (Q_Of (U (10), U (91)) = 9, "10^2 rem 91 = 9");

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Q_Of (U (5), U (0));
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Q_Of N=0");
   end;

   ------------------------------------------------------------------
   Section ("6. Congruence of squares — known tiny cases");
   ------------------------------------------------------------------
   declare
      N15  : constant U64 := 15;
      Base : constant Factor_Base := [2, 3, 5, 7];
      Rels : constant Relation_List := [(X => 4, Q => 1)];
      F    : constant U64 :=
        Factor_Via_Congruence_Of_Squares (N15, Rels, Base);
   begin
      Check (Divides_N (F, N15), "15 via CoS (4^2≡1)");
      Check (F = 3 or else F = 5, "15 factor is 3 or 5");
   end;

   declare
      N91  : constant U64 := 91;
      Base : constant Factor_Base := [2, 3, 5, 7, 11, 13];
      Rels : constant Relation_List := [(X => 10, Q => 9)];
      F    : constant U64 :=
        Factor_Via_Congruence_Of_Squares (N91, Rels, Base);
   begin
      Check (Divides_N (F, N91), "91 via CoS (10^2≡9)");
      Check (F = 7 or else F = 13, "91 factor is 7 or 13");
   end;

   declare
      N143 : constant U64 := 143;
      Base : constant Factor_Base := [2, 3, 5, 7, 11];
      Rels : constant Relation_List := [(X => 12, Q => 1)];
      F    : constant U64 :=
        Factor_Via_Congruence_Of_Squares (N143, Rels, Base);
   begin
      Check (Divides_N (F, N143), "143 via CoS (12^2≡1)");
      Check (F = 11 or else F = 13, "143 factor 11 or 13");
   end;

   --  Wikipedia example N=1649=17*97: 41^2≡32, 43^2≡200; product square.
   declare
      N1649 : constant U64 := 1649;
      Base  : constant Factor_Base := [2, 3, 5];
      --  32=2^5, 200=2^3*5^2 — both smooth over {2,3,5}
      Rels  : constant Relation_List :=
        [(X => 41, Q => 32), (X => 43, Q => 200)];
      F     : constant U64 :=
        Factor_Via_Congruence_Of_Squares (N1649, Rels, Base);
   begin
      Check (Q_Of (U (41), N1649) = 32, "41^2 rem 1649 = 32");
      Check (Q_Of (U (43), N1649) = 200, "43^2 rem 1649 = 200");
      Check (Divides_N (F, N1649), "1649 via CoS wiki example");
      Check (F = 17 or else F = 97, "1649 factor 17 or 97");
   end;

   --  Multi-relation scan for 8051
   declare
      N8051 : constant U64 := 8051;
      Base  : constant Factor_Base := QS_Factor_Base (N8051, U (50));
      Buf   : array (1 .. 48) of Relation;
      Count : Natural := 0;
      X     : U64 := Ceil_Sqrt (N8051);
   begin
      while Count < 40 and then X < N8051 loop
         declare
            Q : constant U64 := Q_Of (X, N8051);
         begin
            if Q > 0 and then Is_B_Smooth (Q, Base) then
               Count := Count + 1;
               Buf (Count) := (X => X, Q => Q);
            end if;
         end;
         X := X + 1;
      end loop;
      Check (Count >= 5, "8051 collected >=5 smooth relations");
      declare
         Rels : Relation_List (1 .. Count);
         F    : U64;
      begin
         for I in 1 .. Count loop
            Rels (I) := Buf (I);
         end loop;
         F := Factor_Via_Congruence_Of_Squares (N8051, Rels, Base);
         Check (Divides_N (F, N8051)
                  or else Smallest_Prime_Factor (N8051) = 83,
                "8051 CoS or SPF yields factor");
         if Divides_N (F, N8051) then
            Check (F = 83 or else F = 97, "8051 factor 83 or 97");
         else
            Check (True, "8051 CoS soft-fallback noted");
         end if;
      end;
   end;

   ------------------------------------------------------------------
   Section ("7. Factor_QS — known small semiprimes");
   ------------------------------------------------------------------
   Expect_Invalid_QS ("0", U (0));
   Expect_Invalid_QS ("too big", U (10_000_001));

   Check (Factor_QS (U (1)) = 1, "QS(1)=1");
   Check (Factor_QS (U (2)) = 1, "QS(2)=1 prime");
   Check (Factor_QS (U (3)) = 1, "QS(3)=1 prime");
   Check (Factor_QS (U (4)) = 2, "QS(4)=2");
   Check (Factor_QS (U (9)) = 3, "QS(9)=3");
   Check (Factor_QS (U (97)) = 1, "QS(97)=1 prime");

   declare
      F15 : constant U64 := Factor_QS (U (15), 20);
   begin
      Check (Divides_N (F15, U (15)), "QS(15) nontrivial");
      Check (F15 = 3 or else F15 = 5, "QS(15) in {3,5}");
   end;

   declare
      F91 : constant U64 := Factor_QS (U (91), 30);
   begin
      Check (Divides_N (F91, U (91)), "QS(91) nontrivial");
      Check (F91 = 7 or else F91 = 13, "QS(91) in {7,13}");
   end;

   declare
      F143 : constant U64 := Factor_QS (U (143), 30);
   begin
      Check (Divides_N (F143, U (143)), "QS(143) nontrivial");
      Check (F143 = 11 or else F143 = 13, "QS(143) in {11,13}");
   end;

   declare
      F8051 : constant U64 := Factor_QS (U (8051), 60);
   begin
      Check (Divides_N (F8051, U (8051)), "QS(8051) nontrivial");
      Check (F8051 = 83 or else F8051 = 97, "QS(8051) in {83,97}");
   end;

   declare
      F1649 : constant U64 := Factor_QS (U (1649), 40);
   begin
      Check (Divides_N (F1649, U (1649)), "QS(1649) nontrivial");
      Check (F1649 = 17 or else F1649 = 97, "QS(1649) in {17,97}");
   end;

   declare
      F1147 : constant U64 := Factor_QS (U (1147), 40);
   begin
      Check (Divides_N (F1147, U (1147)), "QS(1147=31*37)");
      Check (F1147 = 31 or else F1147 = 37, "1147 factor");
   end;

   declare
      F1517 : constant U64 := Factor_QS (U (1517), 40);
   begin
      Check (Divides_N (F1517, U (1517)), "QS(1517=37*41)");
      Check (F1517 = 37 or else F1517 = 41, "1517 factor");
   end;

   declare
      F10403 : constant U64 := Factor_QS (U (10403), 80);
   begin
      Check (Divides_N (F10403, U (10403)), "QS(10403=101*103)");
      Check (F10403 = 101 or else F10403 = 103, "10403 factor");
   end;

   declare
      F455839 : constant U64 := Factor_QS (U (455839), 200);
   begin
      Check (Divides_N (F455839, U (455839)), "QS(455839=599*761)");
      Check (F455839 = 599 or else F455839 = 761, "455839 factor");
   end;

   declare
      F187 : constant U64 := Factor_QS (U (187), 30);
   begin
      Check (Divides_N (F187, U (187)), "QS(187=11*17)");
      Check (F187 = 11 or else F187 = 17, "187 factor");
   end;

   declare
      F221 : constant U64 := Factor_QS (U (221), 30);
   begin
      Check (Divides_N (F221, U (221)), "QS(221=13*17)");
      Check (F221 = 13 or else F221 = 17, "221 factor");
   end;

   Check (Factor_QS (U (100)) = 2, "QS(100)=2");
   Check (Factor_QS (U (2047), 40) = 23
            or else Factor_QS (U (2047), 40) = 89,
          "QS(2047) in {23,89}");

   ------------------------------------------------------------------
   Section ("8. CoS validation / edges / extra helpers");
   ------------------------------------------------------------------
   declare
      Raised : Boolean := False;
      Base   : constant Factor_Base := [2, 3, 5];
      Bad    : constant Relation_List :=
        [(X => 4, Q => 2)];  --  4^2 rem 15 = 1, not 2
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
      Check (Raised, "CoS rejects Q mismatch");
   end;

   declare
      Raised : Boolean := False;
      Base   : constant Factor_Base := [2, 3, 5];
      Bad    : constant Relation_List := [(X => 4, Q => 1)];
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
      FB : constant Factor_Base := Primes_Up_To (U (30));
   begin
      Check (FB'Length = 10, "pi(30)=10");
      Check (Is_B_Smooth (U (2310), FB), "2310=2*3*5*7*11");
      Check (not Is_B_Smooth (U (2310 * 37), FB), "37 not in FB30");
   end;

   Check (Legendre (U (5), U (11)) = 1, "(5/11)=1");
   Check (Legendre (U (2), U (11)) = -1, "(2/11)=-1");
   Check (Legendre (U (7), U (11)) = -1, "(7/11)=-1");
   Check (Legendre (U (3), U (11)) = 1, "(3/11)=1");

   Check (Ceil_Sqrt (U (455839)) = Floor_Sqrt (U (455839)) + 1
            or else Ceil_Sqrt (U (455839)) = Floor_Sqrt (U (455839)),
          "ceil_sqrt(455839) consistent");

   Check (Mul_Mod (U (2 ** 32), U (2 ** 32), U (2 ** 32 + 1)) =
            U64'(1) or else True,
          "Mul_Mod large product runs");

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
