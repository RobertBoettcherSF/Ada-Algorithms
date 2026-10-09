pragma Ada_2022;
with Ada.Text_IO;
with Combination_Sum; use Combination_Sum;
with Own_Checks;

procedure Tests with SPARK_Mode => Off is
   --  Candidates 1 .. Max_Part, each usable any number of times; a
   --  combination is a multiset, so order does not matter.
   procedure Check (Value, Max_Part : Target; Want : Combination_Count) is
      Got : constant Combination_Count := Count_Limited (Value, Max_Part);
   begin
      if Got /= Want then
         raise Program_Error with "Count_Limited (" & Value'Image & "," & Max_Part'Image & ") ="
           & Got'Image & ", expected" & Want'Image;
      end if;
   end Check;

   procedure Check (Value : Target; Want : Combination_Count) is
      Got : constant Combination_Count := Count_Combinations (Value);
   begin
      if Got /= Want then
         raise Program_Error with "Count_Combinations (" & Value'Image & ") =" & Got'Image
           & ", expected" & Want'Image;
      end if;
   end Check;
begin
   --  Candidates 1 .. Value: the partition numbers.
   Check (0, 1);
   Check (5, 7);
   Check (12, 77);
   --  Beyond the old table (targets <= 12), by Euler's pentagonal-number
   --  recurrence p (n) = p (n - 1) + p (n - 2) - p (n - 5) - p (n - 7) + ..:
   --  p (13) = p (12) + p (11) - p (8) - p (6) + p (1) = 77 + 56 - 22 - 11 + 1
   --  = 101 (generalized pentagonals 1, 2, 5, 7, 12; signs + + - - +).
   Check (13, 101);
   Check (20, 627);
   Check (30, 5_604);
   --  The top of the range (see the package comment): p (31) = 6_842 by the
   --  same recurrence; 31 from {1, 2}: floor (31 / 2) + 1 = 16.
   Check (31, 6_842);
   Check (31, 31, 6_842);
   Check (31, 2, 16);
   --  Fewer candidates. 5 from {1, 2}: 2+2+1, 2+1+1+1, 1+1+1+1+1 -> 3.
   --  Parts <= 2: floor (n / 2) + 1, so 30 -> 16. Parts <= 3: the nearest
   --  integer to (n + 3) ** 2 / 12, so 10 -> 169 / 12 -> 14 and 6 -> 7.
   --  Parts <= 1: one way. No candidates: only the target 0 is reachable.
   Check (5, 2, 3);
   Check (30, 2, 16);
   Check (10, 3, 14);
   Check (6, 3, 7);
   Check (30, 1, 1);
   Check (7, 0, 0);
   Check (0, 0, 1);
   Check (4, 9, 5);   --  candidates above the target change nothing: p (4)
   Own_Checks;
   Ada.Text_IO.Put_Line ("PASS Combination_Sum");
end Tests;
