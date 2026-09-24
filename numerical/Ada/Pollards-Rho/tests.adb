--  Standalone test suite for Pollards_Rho (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Pollards_Rho; use Pollards_Rho;

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

   procedure Expect_Invalid_Floyd (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Factor_Floyd (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Factor_Floyd: " & Label);
   end Expect_Invalid_Floyd;

   procedure Expect_Invalid_Brent (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Factor_Brent (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Factor_Brent: " & Label);
   end Expect_Invalid_Brent;

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

   function Divides_N (F, N : U64) return Boolean is
   begin
      return F > 1 and then F < N and then N rem F = 0;
   end Divides_N;

   function Is_Trivial_Or_Factor (F, N : U64) return Boolean is
   begin
      --  Allowed outcomes: nontrivial factor, failure sentinel 1, or N (prime).
      return F = 1 or else F = N or else Divides_N (F, N);
   end Is_Trivial_Or_Factor;

   F : U64;

begin
   Ada.Text_IO.Put_Line ("Pollards_Rho — Ada 2023 test suite");

   ------------------------------------------------------------------
   Section ("1. Floor_Sqrt / Gcd / Mul_Mod");
   ------------------------------------------------------------------
   Check (Floor_Sqrt (U (0)) = 0, "sqrt(0)=0");
   Check (Floor_Sqrt (U (1)) = 1, "sqrt(1)=1");
   Check (Floor_Sqrt (U (2)) = 1, "sqrt(2)=1");
   Check (Floor_Sqrt (U (4)) = 2, "sqrt(4)=2");
   Check (Floor_Sqrt (U (15)) = 3, "sqrt(15)=3");
   Check (Floor_Sqrt (U (16)) = 4, "sqrt(16)=4");
   Check (Floor_Sqrt (U (100)) = 10, "sqrt(100)=10");
   Check (Floor_Sqrt (U (8051)) = 89, "sqrt(8051)=89");
   Check (Floor_Sqrt (U (455839)) = 675, "sqrt(455839)=675");

   Check (Gcd (U (0), U (0)) = 0, "gcd(0,0)=0");
   Check (Gcd (U (12), U (18)) = 6, "gcd(12,18)=6");
   Check (Gcd (U (17), U (13)) = 1, "gcd(17,13)=1");
   Check (Gcd (U (100), U (0)) = 100, "gcd(100,0)=100");
   Check (Gcd (U (0), U (42)) = 42, "gcd(0,42)=42");
   Check (Gcd (U (83), U (97)) = 1, "gcd(83,97)=1");
   Check (Gcd (U (8051), U (97)) = 97, "gcd(8051,97)=97");
   Check (Gcd (U (8051), U (83)) = 83, "gcd(8051,83)=83");

   Check (Mul_Mod (U (7), U (6), U (10)) = 2, "7*6 mod 10 = 2");
   Check (Mul_Mod (U (0), U (5), U (9)) = 0, "0*5 mod 9 = 0");
   Check (Mul_Mod (U (90), U (90), U (8051)) = 49, "90^2 mod 8051");
   Check (Mul_Mod (U (2), U (3), U (1)) = 0, "any mod 1 = 0");
   Check (Mul_Mod (U (123456789), U (987654321), U (1_000_000_007)) =
            259_106_859,
          "large Mul_Mod");
   Expect_Invalid_Mul_Mod ("M=0", U (1), U (1), U (0));

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
   Check (Is_Prime_Trial (U (97)), "97 is prime");
   Check (Is_Prime_Trial (U (83)), "83 is prime");
   Check (not Is_Prime_Trial (U (8051)), "8051 not prime");
   Check (Is_Prime_Trial (U (599)), "599 is prime");
   Check (Is_Prime_Trial (U (761)), "761 is prime");
   Check (not Is_Prime_Trial (U (455839)), "455839 not prime");
   Check (Is_Prime_Trial (U (1009)), "1009 is prime");
   Check (not Is_Prime_Trial (U (1001)), "1001=7*11*13 not prime");
   Check (Is_Prime_Trial (U (7919)), "7919 is prime");

   ------------------------------------------------------------------
   Section ("3. Domain errors N<2");
   ------------------------------------------------------------------
   Expect_Invalid_Floyd ("0", U (0));
   Expect_Invalid_Floyd ("1", U (1));
   Expect_Invalid_Brent ("0", U (0));
   Expect_Invalid_Brent ("1", U (1));
   Expect_Invalid_Factor ("0", U (0));
   Expect_Invalid_Factor ("1", U (1));

   ------------------------------------------------------------------
   Section ("4. Even / small factors");
   ------------------------------------------------------------------
   Check (Factor_Floyd (U (2)) = 2, "Floyd(2)=2");
   Check (Factor_Floyd (U (4)) = 2, "Floyd(4)=2");
   Check (Factor_Floyd (U (6)) = 2, "Floyd(6)=2");
   Check (Factor_Floyd (U (15)) = 3, "Floyd(15)=3");
   Check (Factor_Floyd (U (21)) = 3, "Floyd(21)=3");
   Check (Factor_Floyd (U (9)) = 3, "Floyd(9)=3");
   Check (Factor_Brent (U (4)) = 2, "Brent(4)=2");
   Check (Factor_Brent (U (15)) = 3, "Brent(15)=3");
   Check (Factor (U (100)) = 2, "Factor(100)=2");
   Check (Factor (U (9)) = 3, "Factor(9)=3");

   ------------------------------------------------------------------
   Section ("5. Wikipedia 8051 = 83 x 97");
   ------------------------------------------------------------------
   F := Factor_Floyd (U (8051), Seed => 2, C => 1);
   Check (F = 83 or else F = 97, "Floyd(8051) in {83,97}");
   Check (Divides_N (F, U (8051)), "Floyd(8051) divides");

   F := Factor_Brent (U (8051), Seed => 2, C => 1);
   Check (F = 83 or else F = 97, "Brent(8051) in {83,97}");
   Check (Divides_N (F, U (8051)), "Brent(8051) divides");

   F := Factor (U (8051));
   Check (F = 83 or else F = 97, "Factor(8051) in {83,97}");
   Check (Divides_N (F, U (8051)), "Factor(8051) divides");

   --  Alternate seed may yield the other cofactor.
   F := Factor_Floyd (U (8051), Seed => 3, C => 1);
   Check (Is_Trivial_Or_Factor (F, U (8051)), "Floyd(8051,seed=3) ok");

   ------------------------------------------------------------------
   Section ("6. 455839 = 599 x 761");
   ------------------------------------------------------------------
   F := Factor_Floyd (U (455839));
   Check (F = 599 or else F = 761, "Floyd(455839) in {599,761}");
   Check (Divides_N (F, U (455839)), "Floyd(455839) divides");

   F := Factor_Brent (U (455839));
   Check (F = 599 or else F = 761, "Brent(455839) in {599,761}");
   Check (Divides_N (F, U (455839)), "Brent(455839) divides");

   F := Factor (U (455839));
   Check (F = 599 or else F = 761, "Factor(455839) in {599,761}");

   ------------------------------------------------------------------
   Section ("7. Primes return 1 or N");
   ------------------------------------------------------------------
   F := Factor_Floyd (U (97));
   Check (F = 1 or else F = 97, "Floyd(97) in {1,97}");
   F := Factor_Brent (U (97));
   Check (F = 1 or else F = 97, "Brent(97) in {1,97}");
   F := Factor (U (97));
   Check (F = 1 or else F = 97, "Factor(97) in {1,97}");

   F := Factor_Floyd (U (83));
   Check (F = 1 or else F = 83, "Floyd(83) in {1,83}");
   F := Factor (U (599));
   Check (F = 1 or else F = 599, "Factor(599) in {1,599}");
   F := Factor (U (761));
   Check (F = 1 or else F = 761, "Factor(761) in {1,761}");
   F := Factor (U (1009));
   Check (F = 1 or else F = 1009, "Factor(1009) in {1,1009}");
   F := Factor (U (7919));
   Check (F = 1 or else F = 7919, "Factor(7919) in {1,7919}");

   ------------------------------------------------------------------
   Section ("8. Small semiprimes");
   ------------------------------------------------------------------
   declare
      type Semi is record
         N, P, Q : U64;
      end record;
      Semis : constant array (Positive range <>) of Semi :=
        [(35, 5, 7),
         (77, 7, 11),
         (91, 7, 13),
         (143, 11, 13),
         (187, 11, 17),
         (209, 11, 19),
         (299, 13, 23),
         (319, 11, 29),
         (391, 17, 23),
         (493, 17, 29),
         (667, 23, 29),
         (899, 29, 31),
         (1073, 29, 37),
         (1517, 37, 41),
         (2021, 43, 47),
         (2491, 47, 53),
         (3127, 53, 59),
         (4087, 61, 67),
         (4757, 67, 71),
         (5183, 71, 73),
         (5767, 73, 79),
         (6557, 79, 83),
         (7387, 83, 89),
         (8633, 89, 97),
         (10403, 101, 103),
         (11413, 101, 113),
         (16637, 127, 131),
         (20711, 139, 149),
         (21979, 31, 709),
         (32041, 179, 179)]; -- square
   begin
      for S of Semis loop
         F := Factor (S.N);
         if S.N rem 2 = 0 then
            Check (F = 2, "Factor even");
         elsif S.N rem 3 = 0 then
            Check (F = 3, "Factor peel 3: " & S.N'Image);
         else
            Check
              (Divides_N (F, S.N),
               "Factor divides " & S.N'Image);
         end if;

         F := Factor_Floyd (S.N);
         Check
           (Is_Trivial_Or_Factor (F, S.N),
            "Floyd ok " & S.N'Image);

         F := Factor_Brent (S.N);
         Check
           (Is_Trivial_Or_Factor (F, S.N),
            "Brent ok " & S.N'Image);
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("9. More composites / powers");
   ------------------------------------------------------------------
   F := Factor (U (121));
   Check (F = 11, "Factor(121)=11");
   F := Factor (U (169));
   Check (F = 13, "Factor(169)=13");
   F := Factor (U (289));
   Check (F = 17, "Factor(289)=17");
   F := Factor (U (961));
   Check (F = 31, "Factor(961)=31");
   F := Factor (U (2047));  -- 23 * 89
   Check (F = 23 or else F = 89, "Factor(2047) in {23,89}");
   F := Factor (U (8051 * 3));  -- divisible by 3
   Check (F = 3, "Factor(24153)=3");

   F := Factor_Floyd (U (1147));  -- 31*37
   Check (Divides_N (F, U (1147)) or else F = 1, "Floyd(1147)");
   F := Factor (U (1147));
   Check (Divides_N (F, U (1147)), "Factor(1147) divides");

   F := Factor (U (1363));  -- 29*47
   Check (Divides_N (F, U (1363)), "Factor(1363) divides");
   F := Factor (U (1763));  -- 41*43
   Check (Divides_N (F, U (1763)), "Factor(1763) divides");
   F := Factor (U (3599));  -- 59*61
   Check (Divides_N (F, U (3599)), "Factor(3599) divides");
   F := Factor (U (8633));
   Check (Divides_N (F, U (8633)), "Factor(8633) divides");

   ------------------------------------------------------------------
   Section ("10. Seed / C variants");
   ------------------------------------------------------------------
   F := Factor_Floyd (U (8051), Seed => 2, C => 1);
   Check (Divides_N (F, U (8051)), "Floyd C=1");
   F := Factor_Floyd (U (8051), Seed => 2, C => 2);
   Check (Is_Trivial_Or_Factor (F, U (8051)), "Floyd C=2 ok");
   F := Factor_Brent (U (8051), Seed => 5, C => 1);
   Check (Is_Trivial_Or_Factor (F, U (8051)), "Brent seed=5 ok");
   F := Factor_Floyd (U (455839), Seed => 2, C => 1, Max_Steps => 50_000);
   Check (Divides_N (F, U (455839)), "Floyd 455839 capped steps");

   ------------------------------------------------------------------
   Section ("11. Max_Steps exhaustion sentinel");
   ------------------------------------------------------------------
   --  Tiny Max_Steps on a harder semiprime may return 1 (failure).
   F := Factor_Floyd (U (10403), Seed => 2, C => 1, Max_Steps => 1);
   Check (F = 1 or else Divides_N (F, U (10403)), "Floyd Max_Steps=1");
   F := Factor_Brent (U (10403), Seed => 2, C => 1, Max_Steps => 1);
   Check (F = 1 or else Divides_N (F, U (10403)), "Brent Max_Steps=1");

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
