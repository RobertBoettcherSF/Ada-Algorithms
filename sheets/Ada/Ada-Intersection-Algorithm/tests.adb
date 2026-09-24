-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Intersection_Algorithm; use Intersection_Algorithm;

procedure Tests is
   Result : Result_Record;
   
   -- Helper for approximate floating point checks
   procedure Assert_Float (Actual, Expected : Float; Msg : String) is
   begin
      Assert (abs (Actual - Expected) < 0.0001, Msg & " (Actual: " & Float'Image(Actual) & " Expected: " & Float'Image(Expected) & ")");
   end Assert_Float;

begin
   Put_Line ("=======================================");
   Put_Line ("Starting V&V Test Suite for Algorithms");
   Put_Line ("Assumption: Code broken. Target: Disprove.");
   Put_Line ("=======================================");

   -- TEST 1
   Put_Line ("TEST 1 - NTP Intersection: Perfect Overlap");
   Put_Line ("  1.1 Assert 3 identical intervals result in exact interval boundaries");
   Result := Find_Intersection ((1 => (5.0, 2.0), 2 => (5.0, 2.0), 3 => (5.0, 2.0)));
   Assert (Result.Success, "Expected Success = True");
   Assert_Float (Result.Lower, 3.0, "Lower bound mismatch");
   Assert_Float (Result.Upper, 7.0, "Upper bound mismatch");
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - NTP Intersection: Wikipedia Example 1");
   Put_Line ("  2.1 Assert correctly isolates common time frame [10, 12]");
   Result := Find_Intersection ((1 => (10.0, 2.0), 2 => (12.0, 1.0), 3 => (11.0, 1.0)));
   Assert (Result.Success, "Expected Success = True");
   Assert_Float (Result.Lower, 10.0, "Lower bound mismatch");
   Assert_Float (Result.Upper, 12.0, "Upper bound mismatch");
   Put_Line ("      PASS");

   -- TEST 3
   Put_Line ("TEST 3 - NTP Intersection: Point Intervals (Radius = 0)");
   Put_Line ("  3.1 Assert algorithm safely manages 0-width data processing");
   Result := Find_Intersection ((1 => (2.0, 0.0), 2 => (2.0, 0.0)));
   Assert (Result.Success, "Expected Success = True");
   Assert_Float (Result.Upper, 2.0, "Upper bound mismatch");
   Put_Line ("      PASS");

   -- TEST 4
   Put_Line ("TEST 4 - NTP Intersection: Falseticker Isolation");
   Put_Line ("  4.1 Assert algorithm effectively ignores outlier data (f=1)");
   Result := Find_Intersection ((1 => (2.0, 2.0), 2 => (3.0, 2.0), 3 => (4.0, 2.0), 4 => (7.5, 0.5)));
   Assert (Result.Success, "Expected Success = True");
   Assert_Float (Result.Lower, 2.0, "Lower bound mismatch");
   Assert_Float (Result.Upper, 4.0, "Upper bound mismatch");
   Put_Line ("      PASS");

   -- TEST 5
   Put_Line ("TEST 5 - NTP Intersection: Mathematical Coordinate Robustness");
   Put_Line ("  5.1 Assert negative coordinate spaces act seamlessly");
   Result := Find_Intersection ((1 => (-10.0, 2.0), 2 => (-12.0, 1.0), 3 => (-11.0, 1.0)));
   Assert (Result.Success, "Expected Success = True");
   Assert_Float (Result.Lower, -12.0, "Lower bound mismatch");
   Assert_Float (Result.Upper, -10.0, "Upper bound mismatch");
   Put_Line ("      PASS");

   -- TEST 6
   Put_Line ("TEST 6 - NTP Intersection: Critical Failure State");
   Put_Line ("  6.1 Assert f >= M/2 yields graceful rejection (Success = False)");
   Result := Find_Intersection ((1 => (0.0, 1.0), 2 => (5.0, 1.0), 3 => (10.0, 1.0)));
   Assert (not Result.Success, "Expected rejection for non-overlapping arrays");
   Put_Line ("      PASS");

   -- TEST 7
   Put_Line ("TEST 7 - NTP Intersection: Empty Edge-Case");
   Put_Line ("  7.1 Assert Array length 0 yields no crash");
   declare
      Empty_Array : Interval_Array (1 .. 0);
   begin
      Result := Find_Intersection (Empty_Array);
      Assert (not Result.Success, "Expected Success = False");
      Put_Line ("      PASS");
   end;

   -- TEST 8
   Put_Line ("TEST 8 - NTP Intersection: Single Element");
   Put_Line ("  8.1 Assert Length 1 returns boundaries implicitly");
   Result := Find_Intersection ((1 => (5.0, 3.0)));
   Assert (Result.Success, "Expected Success = True");
   Assert_Float (Result.Lower, 2.0, "Lower bound mismatch");
   Assert_Float (Result.Upper, 8.0, "Upper bound mismatch");
   Put_Line ("      PASS");

   -- TEST 9
   Put_Line ("TEST 9 - NTP Intersection: Dual Non-Overlapping");
   Put_Line ("  9.1 Assert 2 separate components reject strictly (f < 1.0 requirement)");
   Result := Find_Intersection ((1 => (1.0, 1.0), 2 => (5.0, 1.0)));
   Assert (not Result.Success, "Expected Failure");
   Put_Line ("      PASS");

   -- TEST 10
   Put_Line ("TEST 10 - Marzullo's Variant: Example 1 Standard");
   Put_Line ("  10.1 Assert strictly smallest interval bounds resolved");
   Result := Marzullo_Algorithm ((1 => (10.0, 2.0), 2 => (12.0, 1.0), 3 => (11.0, 1.0)));
   Assert (Result.Success, "Expected Success = True");
   Assert_Float (Result.Lower, 11.0, "Lower bound mismatch");
   Assert_Float (Result.Upper, 12.0, "Upper bound mismatch");
   Put_Line ("      PASS");

   -- TEST 11
   Put_Line ("TEST 11 - Marzullo's Variant: Example 2 Target Ignored");
   Put_Line ("  11.1 Assert outlier [14,15] gets rejected organically");
   Result := Marzullo_Algorithm ((1 => (10.0, 2.0), 2 => (12.0, 1.0), 3 => (14.5, 0.5)));
   Assert (Result.Success, "Expected Success = True");
   Assert_Float (Result.Lower, 11.0, "Lower bound mismatch");
   Assert_Float (Result.Upper, 12.0, "Upper bound mismatch");
   Put_Line ("      PASS");

   -- TEST 12
   Put_Line ("TEST 12 - Marzullo's Variant: Example 3 Ambiguity Rules");
   Put_Line ("  12.1 Assert first max-length block resolves deterministic output");
   Result := Marzullo_Algorithm ((1 => (8.5, 0.5), 2 => (10.0, 2.0), 3 => (11.0, 1.0)));
   Assert (Result.Success, "Expected Success = True");
   Assert_Float (Result.Lower, 8.0, "Lower bound mismatch");
   Assert_Float (Result.Upper, 9.0, "Upper bound mismatch");
   Put_Line ("      PASS");

   -- TEST 13
   Put_Line ("TEST 13 - Base Variants: Safety Edge Empty Array");
   Put_Line ("  13.1 Assert structural rejection with zero bounds on M=0");
   declare
      Empty_Array : Interval_Array (1 .. 0);
   begin
      Result := Marzullo_Algorithm (Empty_Array);
      Assert (not Result.Success, "Expected Failure");
      Put_Line ("      PASS");
   end;

   -- TEST 14
   Put_Line ("TEST 14 - System Exceptions & Guardrails");
   Put_Line ("  14.1 Assert algorithm actively defends against Invalid_Data_Error (-R)");
   begin
      Result := Find_Intersection ((1 => (5.0, -2.0)));
      Assert (False, "Should have thrown Exception.");
   exception
      when Invalid_Data_Error =>
         Put_Line ("      PASS");
   end;

   Put_Line ("=======================================");
   Put_Line ("ALL 14 ASSUMPTIONS DISPROVEN - SUITE SUCCESS");
end Tests;
