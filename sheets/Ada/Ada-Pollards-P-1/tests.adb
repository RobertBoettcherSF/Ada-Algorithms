--  Standalone test suite for Pollards_P_1 (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Pollards_P_1; use Pollards_P_1;

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

   procedure Expect_Invalid_Mod_Pow (Label : String; Base, Exp, M : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Mod_Pow (Base, Exp, M);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Mod_Pow: " & Label);
   end Expect_Invalid_Mod_Pow;

   procedure Expect_Invalid_Stage1
     (Label : String; N, B : U64; Base : U64 := 2)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Factor_Stage1 (N, B, Base);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Factor_Stage1: " & Label);
   end Expect_Invalid_Stage1;

   procedure Expect_Invalid_Factor (Label : String; N, B : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Factor (N, B);
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

   function Divides_N (F, N : U64) return Boolean is
   begin
      return F > 1 and then F < N and then N rem F = 0;
   end Divides_N;

   F : U64;

begin
   Ada.Text_IO.Put_Line ("Pollards_P_1 — Ada 2023 test suite");

   ------------------------------------------------------------------
   Section ("1. Floor_Sqrt / Gcd / Mul_Mod / Mod_Pow");
   ------------------------------------------------------------------
   Check (Floor_Sqrt (U (0)) = 0, "sqrt(0)=0");
   Check (Floor_Sqrt (U (1)) = 1, "sqrt(1)=1");
   Check (Floor_Sqrt (U (2)) = 1, "sqrt(2)=1");
   Check (Floor_Sqrt (U (4)) = 2, "sqrt(4)=2");
   Check (Floor_Sqrt (U (15)) = 3, "sqrt(15)=3");
   Check (Floor_Sqrt (U (16)) = 4, "sqrt(16)=4");
   Check (Floor_Sqrt (U (100)) = 10, "sqrt(100)=10");
   Check (Floor_Sqrt (U (299)) = 17, "sqrt(299)=17");

   Check (Gcd (U (0), U (0)) = 0, "gcd(0,0)=0");
   Check (Gcd (U (12), U (18)) = 6, "gcd(12,18)=6");
   Check (Gcd (U (17), U (13)) = 1, "gcd(17,13)=1");
   Check (Gcd (U (100), U (0)) = 100, "gcd(100,0)=100");
   Check (Gcd (U (0), U (42)) = 42, "gcd(0,42)=42");
   Check (Gcd (U (13), U (299)) = 13, "gcd(13,299)=13");
   Check (Gcd (U (23), U (299)) = 23, "gcd(23,299)=23");

   Check (Mul_Mod (U (7), U (6), U (10)) = 2, "7*6 mod 10 = 2");
   Check (Mul_Mod (U (0), U (5), U (9)) = 0, "0*5 mod 9 = 0");
   Check (Mul_Mod (U (2), U (3), U (1)) = 0, "any mod 1 = 0");
   Check (Mul_Mod (U (123456789), U (987654321), U (1_000_000_007)) =
            259_106_859,
          "large Mul_Mod");
   Expect_Invalid_Mul_Mod ("M=0", U (1), U (1), U (0));

   Check (Mod_Pow (U (2), U (10), U (1000)) = 24, "2^10 mod 1000");
   Check (Mod_Pow (U (3), U (0), U (7)) = 1, "3^0 mod 7 = 1");
   Check (Mod_Pow (U (5), U (3), U (13)) = 8, "5^3 mod 13 = 8");
   declare
      R60 : constant U64 := Mod_Pow (U (2), U (60), U (299));
   begin
      Check (R60 < U (299), "2^60 mod 299 < 299");
   end;
   --  Wikipedia path: after Stage 1 with M=60, a=2, N=299 → related check
   Check (Mod_Pow (U (2), U (60), U (13)) = 1, "2^60 ≡ 1 (mod 13)");
   Check (Mod_Pow (U (7), U (5), U (1)) = 0, "any^e mod 1 = 0");
   Expect_Invalid_Mod_Pow ("M=0", U (2), U (3), U (0));

   ------------------------------------------------------------------
   Section ("2. Is_Prime_Trial");
   ------------------------------------------------------------------
   Check (not Is_Prime_Trial (U (0)), "0 not prime");
   Check (not Is_Prime_Trial (U (1)), "1 not prime");
   Check (Is_Prime_Trial (U (2)), "2 is prime");
   Check (Is_Prime_Trial (U (3)), "3 is prime");
   Check (not Is_Prime_Trial (U (4)), "4 not prime");
   Check (Is_Prime_Trial (U (5)), "5 is prime");
   Check (not Is_Prime_Trial (U (9)), "9 not prime");
   Check (Is_Prime_Trial (U (13)), "13 is prime");
   Check (Is_Prime_Trial (U (23)), "23 is prime");
   Check (not Is_Prime_Trial (U (299)), "299 not prime");
   Check (Is_Prime_Trial (U (97)), "97 is prime");
   Check (Is_Prime_Trial (U (101)), "101 is prime");
   Check (not Is_Prime_Trial (U (121)), "121=11^2 not prime");
   Check (Is_Prime_Trial (U (7919)), "7919 is prime");
   Check (not Is_Prime_Trial (U (1001)), "1001 not prime");

   ------------------------------------------------------------------
   Section ("3. Primes_Up_To");
   ------------------------------------------------------------------
   declare
      P0 : constant U64_Array := Primes_Up_To (U (0));
      P1 : constant U64_Array := Primes_Up_To (U (1));
      P2 : constant U64_Array := Primes_Up_To (U (2));
      P5 : constant U64_Array := Primes_Up_To (U (5));
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
      Check (P5'Length = 3 and then P5 (3) = 5, "Primes_Up_To(5)=[2,3,5]");
      Check (P30'Length = 10, "π(30)=10");
      Check (P30 (10) = 29, "last prime ≤30 is 29");
   end;

   ------------------------------------------------------------------
   Section ("4. Domain errors N<2 / B<2");
   ------------------------------------------------------------------
   Expect_Invalid_Stage1 ("N=0", U (0), U (10));
   Expect_Invalid_Stage1 ("N=1", U (1), U (10));
   Expect_Invalid_Stage1 ("B=0", U (299), U (0));
   Expect_Invalid_Stage1 ("B=1", U (299), U (1));
   Expect_Invalid_Factor ("N=0", U (0), U (10));
   Expect_Invalid_Factor ("N=1", U (1), U (10));
   Expect_Invalid_Factor ("B=0", U (299), U (0));
   Expect_Invalid_Factor ("B=1", U (299), U (1));

   ------------------------------------------------------------------
   Section ("5. Even / primes → 1");
   ------------------------------------------------------------------
   Check (Factor_Stage1 (U (2), U (10)) = 2, "Stage1(2)=2");
   Check (Factor_Stage1 (U (4), U (10)) = 2, "Stage1(4)=2");
   Check (Factor_Stage1 (U (6), U (10)) = 2, "Stage1(6)=2");
   Check (Factor (U (100)) = 2, "Factor(100)=2");
   Check (Factor_Stage1 (U (13), U (20)) = 1, "Stage1(13)=1 prime");
   Check (Factor_Stage1 (U (23), U (20)) = 1, "Stage1(23)=1 prime");
   Check (Factor_Stage1 (U (97), U (50)) = 1, "Stage1(97)=1 prime");
   Check (Factor (U (97)) = 1, "Factor(97)=1");
   Check (Factor (U (101)) = 1, "Factor(101)=1");
   Check (Factor (U (7919)) = 1, "Factor(7919)=1");
   Check (Factor (U (3)) = 1, "Factor(3)=1");
   Check (Factor (U (5)) = 1, "Factor(5)=1");

   ------------------------------------------------------------------
   Section ("6. Wikipedia 299 = 13 x 23, B=5");
   ------------------------------------------------------------------
   F := Factor_Stage1 (U (299), U (5), Base => 2);
   Check (F = 13, "Stage1(299,B=5)=13 (Wikipedia)");
   Check (Divides_N (F, U (299)), "13 divides 299");

   F := Factor (U (299), B => 5);
   Check (F = 13 or else F = 23, "Factor(299,B=5) in {13,23}");

   F := Factor_Stage1 (U (299), U (10), Base => 2);
   Check (Divides_N (F, U (299)), "Stage1(299,B=10) divides");

   ------------------------------------------------------------------
   Section ("7. Smooth p−1 semiprimes");
   ------------------------------------------------------------------
   --  p=13 (p−1=12=2²·3), need B ≥ 3 for powers; use B≥4 for 2².
   F := Factor_Stage1 (U (481), U (4));  -- 13*37
   Check (F = 13 or else F = 37, "Stage1(481=13*37,B=4)");
   Check (Divides_N (F, U (481)), "481 factor divides");

   F := Factor_Stage1 (U (533), U (5));  -- 13*41; 40=2³·5 → B≥5
   Check (F = 13 or else F = 41, "Stage1(533=13*41,B=5)");

   --  Base 2 hits g=N for both smooth p-1 at once; other bases / Factor split.
   F := Factor_Stage1 (U (703), U (9), Base => 6);  -- 19*37
   Check (F = 19 or else F = 37, "Stage1(703=19*37,B=9,base=6)");

   F := Factor_Stage1 (U (2701), U (9), Base => 3);  -- 37*73
   Check (F = 37 or else F = 73, "Stage1(2701=37*73,B=9,base=3)");

   F := Factor_Stage1 (U (91), U (5));  -- 7*13; 6=2·3, 12=2²·3
   Check (F = 7 or else F = 13, "Stage1(91=7*13,B=5)");

   F := Factor_Stage1 (U (143), U (5));  -- 11*13; 10=2·5
   Check (F = 11 or else F = 13, "Stage1(143=11*13,B=5)");

   F := Factor_Stage1 (U (187), U (10));  -- 11*17; 16=2^4 → B≥16? 2^4=16>10
   --  With B=10: highest 2-power is 8; 16 doesn't divide M=8*3*5*7.
   --  10=2*5 divides M. So may find 11.
   Check (F = 11 or else F = 17 or else F = 1, "Stage1(187,B=10) ok");
   F := Factor_Stage1 (U (187), U (16));
   Check (F = 11 or else F = 17, "Stage1(187,B=16)");

   F := Factor_Stage1 (U (121), U (5));  -- 11²; 10=2·5
   Check (F = 11, "Stage1(121)=11");

   F := Factor_Stage1 (U (169), U (5));  -- 13²
   Check (F = 13, "Stage1(169)=13");

   F := Factor_Stage1 (U (289), U (16));  -- 17²; 16=2^4
   Check (F = 17, "Stage1(289)=17");

   ------------------------------------------------------------------
   Section ("8. Factor multi-base dispatcher");
   ------------------------------------------------------------------
   F := Factor (U (299));
   Check (F = 13 or else F = 23, "Factor(299) default B");
   F := Factor (U (481));
   Check (F = 13 or else F = 37, "Factor(481)");
   F := Factor (U (91));
   Check (F = 7 or else F = 13, "Factor(91)");
   F := Factor (U (143));
   Check (F = 11 or else F = 13, "Factor(143)");
   F := Factor (U (121));
   Check (F = 11, "Factor(121)=11");
   F := Factor (U (2701));
   Check (F = 37 or else F = 73, "Factor(2701)");
   F := Factor (U (1003), B => 30);  -- 17*59; 58=2*29 → B≥29
   Check (F = 17 or else F = 59, "Factor(1003,B=30)");
   F := Factor (U (2047), B => 50);  -- 23*89; 22=2*11, 88=2^3*11
   Check (F = 23 or else F = 89, "Factor(2047,B=50)");
   F := Factor (U (1147), B => 40);  -- 31*37; 30=2·3·5, 36=2²·3² → B≥9
   Check (F = 31 or else F = 37, "Factor(1147)");
   F := Factor (U (1763), B => 50);  -- 41*43; 40=2³·5, 42=2·3·7
   Check (F = 41 or else F = 43, "Factor(1763)");

   ------------------------------------------------------------------
   Section ("9. More composites with smooth factors");
   ------------------------------------------------------------------
   --  Choose B so exactly one of p−1, q−1 is B-powersmooth when possible.
   declare
      type Semi is record
         N, Expect_A, Expect_B, Bound : U64;
      end record;
      Semis : constant array (Positive range <>) of Semi :=
        [(35, 5, 7, 5),
         (55, 5, 11, 5),
         (65, 5, 13, 5),
         (77, 7, 11, 5),
         (85, 5, 17, 8),       -- 4 smooth; 16 needs B≥16 — use B=8 → 5
         (95, 5, 19, 5),       -- 4; 18 needs 9
         (119, 7, 17, 5),      -- 6; 16 needs 16
         (133, 7, 19, 5),
         (161, 7, 23, 5),      -- 6; 22 needs 11
         (187, 11, 17, 5),     -- 10; 16 needs 16
         (209, 11, 19, 5),
         (247, 13, 19, 5),
         (299, 13, 23, 5),
         (319, 11, 29, 5),     -- 10; 28 needs 7 — B=5 may miss; use 10
         (391, 17, 23, 16),
         (493, 17, 29, 16),
         (667, 23, 29, 11),    -- 22; 28 needs 7 — B=11 finds 23
         (703, 19, 37, 9),
         (899, 29, 31, 14),    -- 28=4*7; 30 needs 5 — B=14 finds 29
         (1073, 29, 37, 14),
         (1147, 31, 37, 10),   -- 30; 36 needs 9 — B=10 finds 31
         (1313, 13, 101, 5),   -- 12; 100 needs 25
         (1517, 37, 41, 9),    -- 36; 40 needs 5 — both? 40=8*5, B=9: 5≤9,8≤9
         (1891, 31, 61, 10),   -- 30; 60 needs 5 — both smooth at B=10
         (2021, 43, 47, 15),   -- 42=2*3*7; 46=2*23 — B=15 finds 43
         (2491, 47, 53, 20),   -- 46=2*23; 52=4*13 — B=20 may get either
         (3127, 53, 59, 20),   -- 52; 58=2*29 — B=20 finds 53
         (4087, 61, 67, 20),   -- 60; 66=2*3*11 — both at B=20
         (4757, 67, 71, 25),   -- 66; 70=2*5*7
         (5183, 71, 73, 30),   -- 70; 72=8*9
         (5767, 73, 79, 20),   -- 72; 78=2*3*13 — B=20 finds 73
         (6557, 79, 83, 20),   -- 78; 82=2*41 — B=20 finds 79
         (7387, 83, 89, 20),   -- 82 needs 41; 88=8*11 — B=20 finds 89?
         (8633, 89, 97, 30)];  -- 88; 96=32*3 — B=30 finds 89
   begin
      for S of Semis loop
         F := Factor (S.N, B => S.Bound);
         Check
           (F = S.Expect_A or else F = S.Expect_B,
            "Factor " & S.N'Image & " in expected pair");
         Check
           (Divides_N (F, S.N),
            "Factor divides " & S.N'Image);
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("10. Bound too small → failure sentinel 1");
   ------------------------------------------------------------------
   --  23−1=22=2·11; B=5 has no factor 11 → Stage1 should miss 23.
   --  For N=299 with B=2: M=2, neither 12|2 nor 22|2 → 1
   F := Factor_Stage1 (U (299), U (2));
   Check (F = 1, "Stage1(299,B=2)=1 too small");
   --  Prime power square with insufficient B
   F := Factor_Stage1 (U (121), U (2));  -- 10 needs 5
   Check (F = 1, "Stage1(121,B=2)=1");

   ------------------------------------------------------------------
   Section ("11. Alternate bases");
   ------------------------------------------------------------------
   F := Factor_Stage1 (U (299), U (5), Base => 3);
   Check (F = 13 or else F = 23 or else F = 1, "Stage1 base=3 ok");
   F := Factor_Stage1 (U (299), U (5), Base => 5);
   Check (F = 13 or else F = 23 or else F = 1, "Stage1 base=5 ok");
   F := Factor_Stage1 (U (481), U (4), Base => 7);
   Check (Divides_N (F, U (481)) or else F = 1, "Stage1(481,base=7)");
   F := Factor (U (299), B => 5);
   Check (Divides_N (F, U (299)), "Factor(299,B=5) divides");

   ------------------------------------------------------------------
   Section ("12. Default_B and miscellaneous");
   ------------------------------------------------------------------
   Check (U (Default_B) = U (100), "Default_B=100");
   F := Factor (U (299));
   Check (Divides_N (F, U (299)), "Factor(299) default");
   F := Factor_Stage1 (U (15), U (5));  -- 3*5; peel? 15 odd, 3|15
   --  Stage1 does not peel 3; p=3 → p−1=2 B-smooth; p=5 → 4=2²
   Check (F = 3 or else F = 5, "Stage1(15,B=5)");
   F := Factor (U (9), B => 5);
   Check (F = 3, "Factor(9)=3");
   F := Factor (U (25), B => 5);
   Check (F = 5, "Factor(25)=5");
   F := Factor (U (49), B => 5);
   Check (F = 7, "Factor(49)=7");
   F := Factor (U (35), B => 5);
   Check (F = 5 or else F = 7, "Factor(35)");

   --  Mod_Pow identity checks for Stage-1 exponent idea
   Check (Mod_Pow (U (2), U (4), U (13)) = 3, "2^4 mod 13");
   Check (Mod_Pow (U (3), U (3), U (13)) = 1, "3^3 mod 13 = 1");
   Check (Mod_Pow (U (2), U (12), U (13)) = 1, "Fermat 2^12≡1 mod 13");

   ------------------------------------------------------------------
   --  Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
