with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Marzullo; use Marzullo;

procedure Tests is
   Best_Int  : Time_Interval;
   Overlaps  : Natural;
   Res_Array : Result_Array (1 .. 10);
   Res_Count : Natural;
begin
   Put_Line ("Starting Marzullo's Algorithm Verification Suite");
   Put_Line ("------------------------------------------------");

   -- TEST 1
   Put_Line ("TEST 1 - Standard Overlapping Intervals");
   Put_Line ("  1.1 Assert correct max overlap count");
   Put_Line ("  1.2 Assert correct start time of optimal interval");
   Put_Line ("  1.3 Assert correct end time of optimal interval");
   declare
      Input : Interval_Array := ((8.0, 12.0), (10.0, 14.0), (11.0, 15.0));
   begin
      Basic_Marzullo (Input, Best_Int, Overlaps);
      Assert (Overlaps = 3, "Failed: Expected overlap 3");
      Assert (Best_Int.Start_Time = 11.0, "Failed: Expected Start 11.0");
      Assert (Best_Int.End_Time = 12.0, "Failed: Expected End 12.0");
      Put_Line ("      PASS");
   end;

   -- TEST 2
   Put_Line ("TEST 2 - Fully Disjoint Intervals");
   Put_Line ("  2.1 Assert max overlaps is exactly 1");
   declare
      Input : Interval_Array := ((1.0, 2.0), (4.0, 5.0), (7.0, 8.0));
   begin
      Basic_Marzullo (Input, Best_Int, Overlaps);
      Assert (Overlaps = 1, "Failed: Disjoint sets must have overlap 1");
      Put_Line ("      PASS");
   end;

   -- TEST 3
   Put_Line ("TEST 3 - Exact Touching Boundaries");
   Put_Line ("  3.1 Assert touching edges are treated as overlaps");
   declare
      Input : Interval_Array := ((1.0, 3.0), (3.0, 5.0));
   begin
      Basic_Marzullo (Input, Best_Int, Overlaps);
      Assert (Overlaps = 2, "Failed: Touching edges should overlap at a point");
      Assert (Best_Int.Start_Time = 3.0, "Failed: Best start should be 3.0");
      Assert (Best_Int.End_Time = 3.0, "Failed: Best end should be 3.0");
      Put_Line ("      PASS");
   end;

   -- TEST 4
   Put_Line ("TEST 4 - Fully Nested/Concentric Intervals");
   Put_Line ("  4.1 Assert deepest nested interval is chosen");
   declare
      Input : Interval_Array := ((0.0, 10.0), (2.0, 8.0), (4.0, 6.0));
   begin
      Basic_Marzullo (Input, Best_Int, Overlaps);
      Assert (Overlaps = 3, "Failed: Overlap count should be 3");
      Assert (Best_Int.Start_Time = 4.0 and Best_Int.End_Time = 6.0, "Failed: Incorrect nested bounds");
      Put_Line ("      PASS");
   end;

   -- TEST 5
   Put_Line ("TEST 5 - Empty Input Error Handling");
   Put_Line ("  5.1 Assert Empty_Input_Error is raised on []");
   begin
      declare
         Input : Interval_Array (1 .. 0);
      begin
         Basic_Marzullo (Input, Best_Int, Overlaps);
         Assert (False, "Failed: Exception not raised");
      end;
   exception
      when Empty_Input_Error => Put_Line ("      PASS");
   end;

   -- TEST 6
   Put_Line ("TEST 6 - Invalid Interval Bounds (Start > End)");
   Put_Line ("  6.1 Assert Invalid_Interval_Error is raised");
   begin
      declare
         Input : Interval_Array := (1 => Time_Interval'(5.0, 2.0));
      begin
         Basic_Marzullo (Input, Best_Int, Overlaps);
         Assert (False, "Failed: Exception not raised");
      end;
   exception
      when Invalid_Interval_Error => Put_Line ("      PASS");
   end;

   -- TEST 7
   Put_Line ("TEST 7 - Single Interval Input");
   Put_Line ("  7.1 Assert algorithm mirrors the single input");
   declare
      Input : Interval_Array := (1 => Time_Interval'(5.5, 9.5));
   begin
      Basic_Marzullo (Input, Best_Int, Overlaps);
      Assert (Overlaps = 1 and Best_Int.Start_Time = 5.5, "Failed on single element");
      Put_Line ("      PASS");
   end;

   -- TEST 8
   Put_Line ("TEST 8 - Negative Time Coordinates");
   Put_Line ("  8.1 Assert negative float times are handled correctly");
   declare
      Input : Interval_Array := ((-10.0, -5.0), (-7.0, -2.0));
   begin
      Basic_Marzullo (Input, Best_Int, Overlaps);
      Assert (Overlaps = 2 and Best_Int.Start_Time = -7.0, "Failed on negative bounds");
      Put_Line ("      PASS");
   end;

   -- TEST 9
   Put_Line ("TEST 9 - Identical Duplicated Intervals");
   Put_Line ("  9.1 Assert identical inputs sum overlaps");
   declare
      Input : Interval_Array := ((1.0, 5.0), (1.0, 5.0), (1.0, 5.0));
   begin
      Basic_Marzullo (Input, Best_Int, Overlaps);
      Assert (Overlaps = 3, "Failed: Duplicate instances not counted");
      Put_Line ("      PASS");
   end;

   -- TEST 10
   Put_Line ("TEST 10 - Extended Marzullo (Multiple Disjoint Peaks)");
   Put_Line ("  10.1 Assert multiple peaks are independently captured");
   declare
      Input : Interval_Array := ((1.0, 3.0), (2.0, 4.0), (6.0, 8.0), (7.0, 9.0));
   begin
      Extended_Marzullo (Input, Res_Array, Res_Count, Overlaps);
      Assert (Overlaps = 2, "Failed: Expected 2 max overlaps");
      Assert (Res_Count = 2, "Failed: Expected 2 separate intervals");
      Assert (Res_Array(1).Start_Time = 2.0, "Failed: First peak start");
      Assert (Res_Array(2).Start_Time = 7.0, "Failed: Second peak start");
      Put_Line ("      PASS");
   end;

   -- TEST 11
   Put_Line ("TEST 11 - Extended Marzullo (Capacity constraint)");
   Put_Line ("  11.1 Assert output respects array boundaries safely");
   declare
      Input    : Interval_Array := ((1.0, 2.0), (3.0, 4.0), (5.0, 6.0));
      Tiny_Res : Result_Array (1 .. 1); 
      T_Count  : Natural;
   begin
      Extended_Marzullo (Input, Tiny_Res, T_Count, Overlaps);
      Assert (T_Count = 3, "Failed: Should still count true number of peaks");
      Put_Line ("      PASS");
   end;

   -- TEST 12
   Put_Line ("TEST 12 - Stability with Point-Intervals (Start = End)");
   Put_Line ("  12.1 Assert intervals of 0 length are processed");
   declare
      Input : Interval_Array := ((4.0, 4.0), (4.0, 4.0));
   begin
      Basic_Marzullo (Input, Best_Int, Overlaps);
      Assert (Overlaps = 2 and Best_Int.End_Time = 4.0, "Failed on 0-length intervals");
      Put_Line ("      PASS");
   end;

   -- TEST 13
   Put_Line ("TEST 13 - Asymmetric Overlap Densities");
   Put_Line ("  13.1 Assert algorithm doesn't latch on early suboptimal overlaps");
   declare
      Input : Interval_Array := ((0.0, 5.0), (1.0, 4.0), (6.0, 10.0), (7.0, 9.0), (8.0, 9.0));
   begin
      Basic_Marzullo (Input, Best_Int, Overlaps);
      Assert (Overlaps = 3, "Failed: Peak overlap should be 3");
      Assert (Best_Int.Start_Time = 8.0, "Failed: Should ignore the earlier overlap of 2");
      Put_Line ("      PASS");
   end;

   Put_Line ("------------------------------------------------");
   Put_Line ("ALL TESTS COMPLETED SUCCESSFULLY");
end Tests;
