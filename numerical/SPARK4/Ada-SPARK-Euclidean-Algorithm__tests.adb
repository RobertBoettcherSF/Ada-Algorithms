--  Standalone test suite for Euclidean_Algorithm (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Euclidean_Algorithm; use Euclidean_Algorithm;

procedure Tests
  with SPARK_Mode => Off
is

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

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function V (X : Long_Long_Integer) return Value is (Value (X));
   function Nat (X : Natural) return Natural is (X);

begin
   Ada.Text_IO.Put_Line ("Euclidean_Algorithm (SPARK) tests");
   Ada.Text_IO.Put_Line ("=================================");

   Section ("1. Divides helper");
   Check (Divides (V (5), V (10)), "Divides(5,10)");
   Check (not Divides (V (5), V (11)), "not Divides(5,11)");
   Check (not Divides (V (0), V (0)), "not Divides(0,0)");
   Check (Divides (V (7), V (0)), "Divides(7,0)");
   Check (Divides (V (1), V (99)), "Divides(1,99)");

   Section ("2. Gcd basics");
   Check (Gcd (V (0), V (0)) = 0, "gcd(0,0)");
   Check (Gcd (V (0), V (7)) = 7, "gcd(0,7)");
   Check (Gcd (V (7), V (0)) = 7, "gcd(7,0)");
   Check (Gcd (V (54), V (24)) = 6, "gcd(54,24)");
   Check (Gcd (V (24), V (54)) = 6, "gcd(24,54)");
   Check (Gcd (V (17), V (13)) = 1, "gcd(17,13)");
   Check (Gcd (V (100), V (25)) = 25, "gcd(100,25)");
   Check (Gcd (V (270), V (192)) = 6, "gcd(270,192)");
   Check (Gcd (V (1), V (1)) = 1, "gcd(1,1)");
   Check (Gcd (V (12), V (18)) = Gcd (V (18), V (12)), "commutative");
   Check (Divides (Gcd (V (54), V (24)), V (54)), "gcd divides 54");
   Check (Divides (Gcd (V (54), V (24)), V (24)), "gcd divides 24");

   Section ("3. Gcd_Recursive agrees with Gcd");
   declare
      Pairs : constant array (Positive range <>) of Value :=
        [0, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 99, 78, 1001, 91,
         100, 35, 270, 192, 54, 24, 17, 13];
   begin
      for I in Pairs'Range loop
         for J in Pairs'Range loop
            Check
              (Gcd_Recursive (Pairs (I), Pairs (J)) =
               Gcd (Pairs (I), Pairs (J)),
               "recursive=iterative");
         end loop;
      end loop;
   end;

   Section ("4. Lcm");
   Check (Lcm (V (0), V (0)) = 0, "lcm(0,0)");
   Check (Lcm (V (4), V (6)) = 12, "lcm(4,6)");
   Check (Lcm (V (21), V (6)) = 42, "lcm(21,6)");
   Check (Lcm (V (7), V (0)) = 0, "lcm(7,0)");
   Check (Lcm (V (0), V (7)) = 0, "lcm(0,7)");
   Check (Lcm (V (12), V (18)) = 36, "lcm(12,18)");
   Check (Lcm (Max_Educational, V (1)) = Max_Educational, "lcm(bound,1)");
   --  Invalid oversized LCM is a Pre violation (no exception in SPARK).
   Check (Max_Educational = V (1_000_000), "Max_Educational");

   Section ("5. Are_Coprime");
   Check (Are_Coprime (V (17), V (13)), "coprime 17,13");
   Check (not Are_Coprime (V (54), V (24)), "not 54,24");
   Check (Are_Coprime (V (1), V (99)), "coprime 1,99");
   Check (Are_Coprime (V (8), V (9)), "coprime 8,9");
   Check (not Are_Coprime (V (0), V (0)), "not coprime 0,0");

   Section ("6. Division_Steps");
   Check (Division_Steps (V (0), V (0)) = 0, "steps 0,0");
   Check (Division_Steps (V (54), V (24)) > Nat (0), "steps 54,24 > 0");
   Check (Division_Steps (V (17), V (13)) >= Nat (1), "steps 17,13");
   Check (Division_Steps (V (7), V (0)) = 0, "steps 7,0");
   Check (Division_Steps (V (0), V (7)) = Nat (1), "steps 0,7");
   Check (Division_Steps (V (100), V (25)) = Nat (1), "steps 100,25");

   Section ("7. Binary_Gcd agrees with Gcd");
   declare
      Pairs : constant array (Positive range <>) of Value :=
        [0, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 99, 78, 1001, 91,
         100, 35, 270, 192, 54, 24, 17, 13, 1024, 768];
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

   Section ("8. Fibonacci worst-case sketch");
   Check (Gcd (V (89), V (55)) = 1, "gcd Fib");
   Check (Are_Coprime (V (144), V (89)), "coprime Fib");
   Check (Division_Steps (V (89), V (55)) >= Division_Steps (V (54), V (24)),
          "Fib steps not fewer than 54,24");
   Check (Gcd_Recursive (V (89), V (55)) = 1, "recursive Fib");
   Check (Binary_Gcd (V (89), V (55)) = 1, "binary Fib");

   Section ("9. Educational bound / large educational values");
   declare
      Bound : constant Value := Max_Educational;
   begin
      Check (Bound = V (1_000_000), "Max_Educational value");
      Check (Gcd (Bound, V (15)) = 5, "gcd bound,15");
      Check (Gcd (Bound, V (0)) = Bound, "gcd bound,0");
      Check (Binary_Gcd (Bound, V (15)) = 5, "binary bound,15");
      Check (Lcm (Bound, V (15)) = Bound * 3, "lcm bound,15");
   end;

   Section ("10. More Gcd identities");
   Check (Gcd (V (2)**10, V (2)**6) = V (2)**6, "gcd powers of 2");
   Check (Gcd (V (997), V (991)) = 1, "gcd primes");
   Check (Gcd (V (48), V (180)) = 12, "gcd(48,180)");
   Check (Lcm (V (48), V (180)) = 720, "lcm(48,180)");
   Check (Gcd (V (1), V (0)) = 1, "gcd(1,0)");
   Check (Are_Coprime (V (1), V (0)), "coprime 1,0");

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
