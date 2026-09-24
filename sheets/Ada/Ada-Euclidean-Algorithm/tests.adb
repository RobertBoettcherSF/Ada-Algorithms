--  Standalone test suite for Euclidean (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Euclidean; use Euclidean;

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

   function L (X : Long_Integer) return Long_Integer is (X);

   procedure Expect_Invalid_Lcm (Label : String; A, B : Long_Integer) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Long_Integer := Lcm (A, B);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Lcm: " & Label);
   end Expect_Invalid_Lcm;

begin
   Ada.Text_IO.Put_Line ("Euclidean tests");
   Ada.Text_IO.Put_Line ("===============");

   Section ("1. Abs_LI");
   Check (Abs_LI (L (0)) = 0, "Abs_LI(0)");
   Check (Abs_LI (L (5)) = 5, "Abs_LI(5)");
   Check (Abs_LI (L (-5)) = 5, "Abs_LI(-5)");

   Section ("2. Gcd basics");
   Check (Gcd (L (0), L (0)) = 0, "gcd(0,0)");
   Check (Gcd (L (0), L (7)) = 7, "gcd(0,7)");
   Check (Gcd (L (7), L (0)) = 7, "gcd(7,0)");
   Check (Gcd (L (-7), L (0)) = 7, "gcd(-7,0)");
   Check (Gcd (L (54), L (24)) = 6, "gcd(54,24)");
   Check (Gcd (L (24), L (54)) = 6, "gcd(24,54)");
   Check (Gcd (L (-54), L (24)) = 6, "gcd(-54,24)");
   Check (Gcd (L (17), L (13)) = 1, "gcd(17,13)");
   Check (Gcd (L (100), L (25)) = 25, "gcd(100,25)");
   Check (Gcd (L (270), L (192)) = 6, "gcd(270,192)");
   Check (Gcd (L (1), L (1)) = 1, "gcd(1,1)");
   Check (Gcd (L (12), L (18)) = Gcd (L (18), L (12)), "commutative");

   Section ("3. Lcm");
   Check (Lcm (L (0), L (0)) = 0, "lcm(0,0)");
   Check (Lcm (L (4), L (6)) = 12, "lcm(4,6)");
   Check (Lcm (L (21), L (6)) = 42, "lcm(21,6)");
   Check (Lcm (L (-4), L (6)) = 12, "lcm(-4,6)");
   Check (Lcm (L (7), L (0)) = 0, "lcm(7,0)");
   Expect_Invalid_Lcm ("over bound", Max_Educational + 1, L (2));

   Section ("4. Are_Coprime");
   Check (Are_Coprime (L (17), L (13)), "coprime 17,13");
   Check (not Are_Coprime (L (54), L (24)), "not 54,24");
   Check (Are_Coprime (L (1), L (99)), "coprime 1,99");

   Section ("5. Division_Steps");
   Check (Division_Steps (L (0), L (0)) = 0, "steps 0,0");
   Check (Division_Steps (L (54), L (24)) > 0, "steps 54,24 > 0");
   Check (Division_Steps (L (17), L (13)) >= 1, "steps 17,13");
   Check (Division_Steps (L (7), L (0)) = 0, "steps 7,0");

   Section ("6. Binary_Gcd agrees with Gcd");
   declare
      Pairs : constant array (Positive range <>) of Long_Integer :=
        [0, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 99, 78, 1001, 91,
         100, 35, 270, 192, 54, 24, -17, -13, -54, 24];
   begin
      for I in Pairs'Range loop
         for J in Pairs'Range loop
            Check
              (Binary_Gcd (Pairs (I), Pairs (J)) =
               Gcd (Pairs (I), Pairs (J)),
               "binary=euclid");
         end loop;
      end loop;
   end;

   Section ("7. Fibonacci worst-case sketch");
   --  Consecutive Fibonacci numbers: gcd(F_{n+1}, F_n) = 1
   Check (Gcd (L (89), L (55)) = 1, "gcd Fib");
   Check (Are_Coprime (L (144), L (89)), "coprime Fib");
   Check (Division_Steps (L (89), L (55)) >= Division_Steps (L (54), L (24)),
          "Fib steps not fewer than 54,24");

   Section ("8. Educational bound");
   declare
      Bound : constant Long_Integer := Max_Educational;
   begin
      Check (Bound = L (1_000_000), "Max_Educational");
      Check (Gcd (Bound, L (15)) = 5, "gcd bound,15");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("----------------------------------------");
   Ada.Text_IO.Put_Line
     ("Passed:" & Natural'Image (Pass_Count) &
      "  Failed:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL TESTS PASSED");
   else
      Ada.Text_IO.Put_Line ("SOME TESTS FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
