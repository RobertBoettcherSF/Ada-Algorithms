pragma Ada_2022;
with Ada.Text_IO;
with Combination_Sum_II; use Combination_Sum_II;
with Own_Checks;

procedure Tests with SPARK_Mode => Off is
   --  Candidates 1 .. Max_Part, each usable at most once; order does not
   --  matter, so a combination is a set of distinct parts.
   procedure Check (Value, Max_Part : Target; Want : Combination_Count) is
      Got : constant Combination_Count := Count_Limited (Value, Max_Part);
   begin
      if Got /= Want then
         raise Program_Error with "Count_Limited (" & Value'Image & "," & Max_Part'Image & ") ="
           & Got'Image & ", expected" & Want'Image;
      end if;
   end Check;

   procedure Check (Value : Target; Want : Combination_Count) is
      Got : constant Combination_Count := Count_Distinct_Combinations (Value);
   begin
      if Got /= Want then
         raise Program_Error with "Count_Distinct_Combinations (" & Value'Image & ") =" & Got'Image
           & ", expected" & Want'Image;
      end if;
   end Check;
begin
   --  Candidates 1 .. Value: partitions into distinct parts, q (n).
   Check (0, 1);
   Check (6, 4);
   Check (12, 15);
   --  Beyond the old table (targets <= 12). q (13) = 18, listed by hand:
   --  13; 12+1; 11+2; 10+3; 10+2+1; 9+4; 9+3+1; 8+5; 8+4+1; 8+3+2; 7+6;
   --  7+5+1; 7+4+2; 7+3+2+1; 6+5+2; 6+4+3; 6+4+2+1; 5+4+3+1.
   --  q (20) = 64 and q (30) = 296 (equal to the number of partitions into
   --  odd parts, Euler; own_checks.adb counts those independently).
   Check (13, 18);
   Check (20, 64);
   Check (30, 296);
   --  Fewer candidates, by hand: 10 from {1 .. 4} only 1+2+3+4; 7 from
   --  {1 .. 4}: 3+4, 1+2+4; 5 from {1, 2}: none (at most 3); 3 from {1, 2}:
   --  1+2; 5 from {1, 2, 3}: 2+3; no candidates: only target 0; candidates
   --  above the target change nothing: 4 from {1 .. 9} = q (4) = 2 (4, 1+3).
   Check (10, 4, 1);
   Check (7, 4, 2);
   Check (5, 2, 0);
   Check (3, 2, 1);
   Check (5, 3, 1);
   Check (4, 0, 0);
   Check (0, 0, 1);
   Check (4, 9, 2);
   Own_Checks;
   Ada.Text_IO.Put_Line ("PASS Combination_Sum_II");
end Tests;
