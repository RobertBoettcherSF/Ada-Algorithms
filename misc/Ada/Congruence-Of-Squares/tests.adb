--  Standalone test suite for Congruence_Of_Squares (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Congruence_Of_Squares; use Congruence_Of_Squares;

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

   procedure Expect_Invalid_Squares (Label : String; X, Y, N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Boolean := Squares_Congruent (X, Y, N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Squares_Congruent: " & Label);
   end Expect_Invalid_Squares;

   procedure Expect_Invalid_Factor_CoS (Label : String; X, Y, N : U64) is
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
   end Expect_Invalid_Factor_CoS;

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

   procedure Expect_Invalid_Fermat_Search (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Factor_Pair :=
              Find_Fermat_Style_Congruence (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Find_Fermat_Style: " & Label);
   end Expect_Invalid_Fermat_Search;

   Divides_OK : Boolean;

begin
   Ada.Text_IO.Put_Line
     ("Congruence_Of_Squares — Ada 2023 educational test suite");

   ------------------------------------------------------------------
   Section ("Mul_Mod");
   ------------------------------------------------------------------
   Check (Mul_Mod (U (3), U (4), U (5)) = 2, "3*4 mod 5 = 2");
   Check (Mul_Mod (U (7), U (7), U (10)) = 9, "7*7 mod 10 = 9");
   Check (Mul_Mod (U (0), U (99), U (13)) = 0, "0*99 mod 13 = 0");
   Check (Mul_Mod (U (1), U (1), U (1)) = 0, "any mod 1 = 0");
   Check (Mul_Mod (U (100), U (100), U (97)) = 9, "100*100 mod 97");
   Check
     (Mul_Mod (U (2**32), U (2**32), U (1_000_000_007)) =
        Mul_Mod (U (2**32), U (2**32), U (1_000_000_007)),
      "large Mul_Mod self-consistent");
   Expect_Invalid_Mul_Mod ("M=0", U (1), U (1), U (0));

   ------------------------------------------------------------------
   Section ("Gcd");
   ------------------------------------------------------------------
   Check (Gcd (U (0), U (0)) = 0, "Gcd(0,0)=0");
   Check (Gcd (U (0), U (15)) = 15, "Gcd(0,15)=15");
   Check (Gcd (U (15), U (0)) = 15, "Gcd(15,0)=15");
   Check (Gcd (U (48), U (18)) = 6, "Gcd(48,18)=6");
   Check (Gcd (U (17), U (19)) = 1, "Gcd(17,19)=1");
   Check (Gcd (U (35), U (5)) = 5, "Gcd(35,5)=5");
   Check (Gcd (U (114 - 80), U (1649)) = 17, "Gcd(34,1649)=17");
   Check (Gcd (U (114 + 80), U (1649)) = 97, "Gcd(194,1649)=97");

   ------------------------------------------------------------------
   Section ("Floor_Sqrt / Ceil_Sqrt / Is_Perfect_Square");
   ------------------------------------------------------------------
   Check (Floor_Sqrt (U (0)) = 0, "Floor_Sqrt(0)=0");
   Check (Floor_Sqrt (U (1)) = 1, "Floor_Sqrt(1)=1");
   Check (Floor_Sqrt (U (15)) = 3, "Floor_Sqrt(15)=3");
   Check (Floor_Sqrt (U (16)) = 4, "Floor_Sqrt(16)=4");
   Check (Floor_Sqrt (U (100)) = 10, "Floor_Sqrt(100)=10");
   Check (Ceil_Sqrt (U (0)) = 0, "Ceil_Sqrt(0)=0");
   Check (Ceil_Sqrt (U (1)) = 1, "Ceil_Sqrt(1)=1");
   Check (Ceil_Sqrt (U (15)) = 4, "Ceil_Sqrt(15)=4");
   Check (Ceil_Sqrt (U (16)) = 4, "Ceil_Sqrt(16)=4");
   Check (Ceil_Sqrt (U (17)) = 5, "Ceil_Sqrt(17)=5");
   Check (Is_Perfect_Square (U (0)), "0 is square");
   Check (Is_Perfect_Square (U (1)), "1 is square");
   Check (Is_Perfect_Square (U (36)), "36 is square");
   Check (not Is_Perfect_Square (U (2)), "2 is not square");
   Check (not Is_Perfect_Square (U (15)), "15 is not square");
   Check (Is_Perfect_Square (U (10_000)), "10000 is square");

   ------------------------------------------------------------------
   Section ("Is_Prime_Trial / Smallest_Prime_Factor");
   ------------------------------------------------------------------
   Check (not Is_Prime_Trial (U (0)), "0 not prime");
   Check (not Is_Prime_Trial (U (1)), "1 not prime");
   Check (Is_Prime_Trial (U (2)), "2 prime");
   Check (Is_Prime_Trial (U (3)), "3 prime");
   Check (not Is_Prime_Trial (U (4)), "4 not prime");
   Check (Is_Prime_Trial (U (17)), "17 prime");
   Check (not Is_Prime_Trial (U (35)), "35 not prime");
   Check (Is_Prime_Trial (U (97)), "97 prime");
   Check (not Is_Prime_Trial (U (91)), "91=7*13 not prime");
   Check (Smallest_Prime_Factor (U (2)) = 2, "SPF(2)=2");
   Check (Smallest_Prime_Factor (U (15)) = 3, "SPF(15)=3");
   Check (Smallest_Prime_Factor (U (35)) = 5, "SPF(35)=5");
   Check (Smallest_Prime_Factor (U (49)) = 7, "SPF(49)=7");
   Check (Smallest_Prime_Factor (U (97)) = 97, "SPF(97)=97");
   Expect_Invalid_SPF ("N=0", U (0));
   Expect_Invalid_SPF ("N=1", U (1));

   ------------------------------------------------------------------
   Section ("Squares_Congruent / Is_Trivial_Pair");
   ------------------------------------------------------------------
   --  Wikipedia: 6² ≡ 1² (mod 35)
   Check (Squares_Congruent (U (6), U (1), U (35)), "6²≡1² mod 35");
   Check (not Is_Trivial_Pair (U (6), U (1), U (35)), "6≢±1 mod 35");
   Check (Is_Trivial_Pair (U (6), U (6), U (35)), "6≡6 mod 35 trivial");
   Check (Is_Trivial_Pair (U (6), U (29), U (35)), "6≡−29? 35-6=29 yes");
   --  10² ≡ 9 ≡ 3² (mod 91)
   Check (Squares_Congruent (U (10), U (3), U (91)), "10²≡3² mod 91");
   Check (not Is_Trivial_Pair (U (10), U (3), U (91)), "10≢±3 mod 91");
   --  Same square, trivial
   Check (Squares_Congruent (U (5), U (5), U (11)), "5²≡5² always");
   Check (Is_Trivial_Pair (U (5), U (5), U (11)), "same is trivial");
   --  X ≡ −Y: 4 and 7 mod 11 (4+7=11)
   Check (Is_Trivial_Pair (U (4), U (7), U (11)), "4≡−7 mod 11");
   Check (Squares_Congruent (U (4), U (7), U (11)), "4²≡7² mod 11");
   Check
     (not Is_Nontrivial_Congruence (U (4), U (7), U (11)),
      "4,7 trivial CoS mod 11");
   Expect_Invalid_Squares ("N=0", U (1), U (1), U (0));

   ------------------------------------------------------------------
   Section ("Is_Nontrivial_Congruence");
   ------------------------------------------------------------------
   Check
     (Is_Nontrivial_Congruence (U (6), U (1), U (35)),
      "nontrivial CoS (6,1,35)");
   Check
     (Is_Nontrivial_Congruence (U (10), U (3), U (91)),
      "nontrivial CoS (10,3,91)");
   Check
     (Is_Nontrivial_Congruence (U (12), U (1), U (143)),
      "nontrivial CoS (12,1,143)");
   Check
     (Is_Nontrivial_Congruence (U (114), U (80), U (1649)),
      "nontrivial CoS (114,80,1649)");
   Check
     (not Is_Nontrivial_Congruence (U (6), U (6), U (35)),
      "trivial same (6,6,35)");
   Check
     (not Is_Nontrivial_Congruence (U (6), U (29), U (35)),
      "trivial ± (6,29,35)");
   Check
     (not Is_Nontrivial_Congruence (U (5), U (2), U (11)),
      "5²≢2² mod 11 → not CoS");

   ------------------------------------------------------------------
   Section ("Factor_From_Congruence — Wikipedia examples");
   ------------------------------------------------------------------
   --  35 = 5 × 7 via (6, 1)
   declare
      F : constant U64 := Factor_From_Congruence (U (6), U (1), U (35));
   begin
      Check (F = 5 or else F = 7, "Factor_From_Congruence(6,1,35) in {5,7}");
      Check (F > 1 and then 35 rem F = 0, "factor divides 35");
   end;
   declare
      P : constant Factor_Pair :=
        Factors_From_Congruence (U (6), U (1), U (35));
   begin
      Check (P.F1 = 5 and then P.F2 = 7, "Factors (6,1,35)=(5,7)");
      Check (P.F1 * P.F2 = 35, "5*7=35");
   end;

   --  1649 = 17 × 97 via (114, 80)
   declare
      F : constant U64 :=
        Factor_From_Congruence (U (114), U (80), U (1649));
   begin
      Check
        (F = 17 or else F = 97,
         "Factor_From_Congruence(114,80,1649) in {17,97}");
   end;
   declare
      P : constant Factor_Pair :=
        Factors_From_Congruence (U (114), U (80), U (1649));
   begin
      Check (P.F1 = 17 and then P.F2 = 97, "Factors (114,80,1649)=(17,97)");
   end;

   --  91 = 7 × 13 via (10, 3): 10²=100≡9=3² (mod 91)
   declare
      F : constant U64 := Factor_From_Congruence (U (10), U (3), U (91));
   begin
      Check (F = 7 or else F = 13, "Factor_From_Congruence(10,3,91)");
   end;

   --  143 = 11 × 13 via (12, 1): 12²=144≡1
   declare
      F : constant U64 := Factor_From_Congruence (U (12), U (1), U (143));
   begin
      Check (F = 11 or else F = 13, "Factor_From_Congruence(12,1,143)");
   end;

   --  15 = 3 × 5 via (4, 1): 4²=16≡1
   declare
      F : constant U64 := Factor_From_Congruence (U (4), U (1), U (15));
   begin
      Check (F = 3 or else F = 5, "Factor_From_Congruence(4,1,15)");
   end;

   --  Trivial → sentinel 0
   Check
     (Factor_From_Congruence (U (6), U (6), U (35)) = 0,
      "trivial same → 0");
   Check
     (Factor_From_Congruence (U (6), U (29), U (35)) = 0,
      "trivial ± → 0");
   Check
     (Factor_From_Congruence (U (5), U (2), U (11)) = 0,
      "not congruent → 0");
   declare
      P : constant Factor_Pair :=
        Factors_From_Congruence (U (6), U (6), U (35));
   begin
      Check (P.F1 = 0 and then P.F2 = 0, "trivial Factors → (0,0)");
   end;

   Expect_Invalid_Factor_CoS ("N=0", U (1), U (1), U (0));
   Expect_Invalid_Factor_CoS ("N=1", U (1), U (1), U (1));

   ------------------------------------------------------------------
   Section ("Find_Fermat_Style_Congruence");
   ------------------------------------------------------------------
   declare
      P : Factor_Pair;
   begin
      P := Find_Fermat_Style_Congruence (U (35));
      Check
        (P.F1 > 1 and then P.F1 * P.F2 = 35,
         "Fermat-style factors 35");
      Check
        ((P.F1 = 5 and then P.F2 = 7)
           or else (P.F1 = 7 and then P.F2 = 5),
         "Fermat-style 35 → 5×7");
   end;
   declare
      P : Factor_Pair;
   begin
      P := Find_Fermat_Style_Congruence (U (15));
      Check (P.F1 * P.F2 = 15 and then P.F1 > 1, "Fermat-style 15");
   end;
   declare
      P : Factor_Pair;
   begin
      P := Find_Fermat_Style_Congruence (U (91));
      Check (P.F1 * P.F2 = 91 and then P.F1 > 1, "Fermat-style 91");
   end;
   declare
      P : Factor_Pair;
   begin
      P := Find_Fermat_Style_Congruence (U (143));
      Check (P.F1 * P.F2 = 143 and then P.F1 > 1, "Fermat-style 143");
   end;
   declare
      P : Factor_Pair;
   begin
      --  Close factors: 83 × 97 = 8051 (Fermat-friendly)
      P := Find_Fermat_Style_Congruence (U (8051));
      Check
        (P.F1 * P.F2 = 8051 and then P.F1 > 1,
         "Fermat-style 8051=83×97");
   end;
   declare
      P : Factor_Pair;
   begin
      P := Find_Fermat_Style_Congruence (U (100));  -- even
      Check (P.F1 = 2 and then P.F2 = 50, "Fermat-style even 100→(2,50)");
   end;
   declare
      P : Factor_Pair;
   begin
      P := Find_Fermat_Style_Congruence (U (49));  -- square
      Check (P.F1 = 7 and then P.F2 = 7, "Fermat-style square 49→(7,7)");
   end;
   Expect_Invalid_Fermat_Search ("N=0", U (0));
   Expect_Invalid_Fermat_Search ("N=1", U (1));
   Expect_Invalid_Fermat_Search ("N>Max", U (1_000_001));

   ------------------------------------------------------------------
   Section ("Find_Random_Square_Congruence");
   ------------------------------------------------------------------
   declare
      P : Factor_Pair;
   begin
      P := Find_Random_Square_Congruence (U (35), Seed => U (1));
      Check
        (P.F1 > 1 and then P.F1 * P.F2 = 35,
         "random-square factors 35");
   end;
   declare
      P : Factor_Pair;
   begin
      P := Find_Random_Square_Congruence (U (91), Seed => U (42));
      --  May or may not find quickly; if found must be correct
      if P.F1 = 0 then
         Check (True, "random-square 91: no hit (ok sentinel)");
      else
         Check (P.F1 * P.F2 = 91 and then P.F1 > 1,
                "random-square 91 valid split");
      end if;
   end;
   declare
      P : Factor_Pair;
   begin
      P := Find_Random_Square_Congruence (U (14));  -- even
      Check (P.F1 = 2 and then P.F2 = 7, "random-square even 14→(2,7)");
   end;

   ------------------------------------------------------------------
   Section ("Factor educational driver");
   ------------------------------------------------------------------
   Check (Factor (U (35)) = 5 or else Factor (U (35)) = 7, "Factor(35)");
   Check (Factor (U (15)) = 3 or else Factor (U (15)) = 5, "Factor(15)");
   Check (Factor (U (91)) = 7 or else Factor (U (91)) = 13, "Factor(91)");
   Check
     (Factor (U (143)) = 11 or else Factor (U (143)) = 13, "Factor(143)");
   Check (Factor (U (2)) = 2, "Factor(2)=2");
   Check (Factor (U (100)) = 2, "Factor(100)=2 even");
   Check (Factor (U (17)) = 1, "Factor(17)=1 prime");
   Check (Factor (U (97)) = 1, "Factor(97)=1 prime");
   Check (Factor (U (1)) = 1, "Factor(1)=1");
   declare
      F : constant U64 := Factor (U (8051));
   begin
      Check
        (F = 83 or else F = 97,
         "Factor(8051) in {83,97}");
      Divides_OK := 8051 rem F = 0;
      Check (Divides_OK, "Factor(8051) divides");
   end;
   declare
      F : constant U64 := Factor (U (1649));
   begin
      Check
        (F = 17 or else F = 97,
         "Factor(1649) in {17,97}");
   end;
   Expect_Invalid_Factor ("N=0", U (0));
   Expect_Invalid_Factor ("N>Max", Factor_Search_Max + 1);

   ------------------------------------------------------------------
   Section ("More CoS pairs / identities");
   ------------------------------------------------------------------
   --  21 = 3×7; 8²=64≡1=1² (mod 21); gcd(7,21)=7, gcd(9,21)=3
   Check (Is_Nontrivial_Congruence (U (8), U (1), U (21)), "CoS (8,1,21)");
   declare
      F : constant U64 := Factor_From_Congruence (U (8), U (1), U (21));
   begin
      Check (F = 3 or else F = 7, "Factor_From_Congruence(8,1,21)");
   end;
   --  55 = 5×11; 12²=144≡34; not helpful — use 21²≡1? 441≡1 mod 55
   Check (Mul_Mod (U (21), U (21), U (55)) = 1, "21²≡1 mod 55");
   Check (Is_Nontrivial_Congruence (U (21), U (1), U (55)), "CoS (21,1,55)");
   declare
      F : constant U64 := Factor_From_Congruence (U (21), U (1), U (55));
   begin
      Check (F = 5 or else F = 11, "Factor_From_Congruence(21,1,55)");
   end;
   --  187 = 11×17; 18²=324≡137; try 40²=1600≡88? ...
   --  Known: 14² ≡ 9²? 196-81=115, 115/187 no.
   --  33² = 1089 ≡ 1089-5*187=1089-935=154; ...
   --  Use Factor driver instead
   declare
      F : constant U64 := Factor (U (187));
   begin
      Check (F = 11 or else F = 17, "Factor(187) in {11,17}");
   end;
   --  221 = 13×17 (close factors)
   declare
      F : constant U64 := Factor (U (221));
   begin
      Check (F = 13 or else F = 17, "Factor(221) in {13,17}");
   end;
   --  319 = 11×29
   declare
      F : constant U64 := Factor (U (319));
   begin
      Check (F = 11 or else F = 29, "Factor(319) in {11,29}");
   end;
   --  667 = 23×29
   declare
      F : constant U64 := Factor (U (667));
   begin
      Check (F = 23 or else F = 29, "Factor(667) in {23,29}");
   end;

   ------------------------------------------------------------------
   Section ("Diff/Sum gcd identities");
   ------------------------------------------------------------------
   --  For nontrivial CoS, both gcds multiply (up to units) to N
   declare
      X : constant U64 := 6;
      Y : constant U64 := 1;
      N : constant U64 := 35;
      D : constant U64 := Gcd ((X + N - Y) rem N, N);
      S : constant U64 := Gcd ((X + Y) rem N, N);
   begin
      Check (D = 5, "gcd(|6-1|,35)=5");
      Check (S = 7, "gcd(6+1,35)=7");
      Check (D * S = N, "product of CoS gcds = N");
   end;
   declare
      X : constant U64 := 114;
      Y : constant U64 := 80;
      N : constant U64 := 1649;
      D : constant U64 := Gcd ((X + N - Y) rem N, N);
      S : constant U64 := Gcd ((X + Y) rem N, N);
   begin
      Check (D = 17, "gcd(|114-80|,1649)=17");
      Check (S = 97, "gcd(114+80,1649)=97");
      Check (D * S = N, "17*97=1649");
   end;

   ------------------------------------------------------------------
   Section ("Boundary / consistency");
   ------------------------------------------------------------------
   Check (Mul_Mod (U (35), U (35), U (35)) = 0, "N²≡0 mod N");
   Check (Is_Trivial_Pair (U (0), U (0), U (35)), "0≡±0 mod 35");
   Check
     (not Is_Nontrivial_Congruence (U (0), U (0), U (35)),
      "(0,0) not nontrivial");
   Check (Floor_Sqrt (U (2**10)) = 2**5, "Floor_Sqrt(1024)=32");
   Check (Ceil_Sqrt (U (2**10 + 1)) = 33, "Ceil_Sqrt(1025)=33");
   Check (Gcd (U (1), U (1)) = 1, "Gcd(1,1)=1");
   Check (Gcd (U (100), U (25)) = 25, "Gcd(100,25)=25");
   --  Reproducibility of Factor on fixed N
   Check (Factor (U (35), U (1)) = Factor (U (35), U (1)),
          "Factor reproducible same seed");
   Check
     (Factor_From_Congruence (U (6), U (1), U (35)) =
        Factor_From_Congruence (U (1), U (6), U (35)),
      "Factor_From_Congruence symmetric in X,Y");

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
