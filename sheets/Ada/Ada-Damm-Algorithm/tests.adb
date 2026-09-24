--  tests.adb
--  13+ V&V terminal-executable tests validating the Damm implementation.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Damm_Algorithm; use Damm_Algorithm;

procedure Tests is
begin
   Put_Line ("Running Damm Algorithm V&V Test Suite...");
   Put_Line ("----------------------------------------");

   --  TEST 1 - Normal Calculation (Array)
   Put_Line ("TEST 1 - Array Calculation");
   Put_Line ("  1.1 Assert check digit for [5, 7, 2] is 4");
   Assert (Calculate_Check_Digit ((5, 7, 2)) = 4,
           "Array calculation failed");
   Put_Line ("      PASS");

   --  TEST 2 - Normal Verification (Array)
   Put_Line ("TEST 2 - Array Verification");
   Put_Line ("  2.1 Assert [5, 7, 2, 4] verifies as True");
   Assert (Verify_Number ((5, 7, 2, 4)) = True,
           "Array verification failed");
   Put_Line ("      PASS");

   --  TEST 3 - String Calculation Variant
   Put_Line ("TEST 3 - String Calculation");
   Put_Line ("  3.1 Assert check digit for ""572"" is 4");
   Assert (Calculate_Check_Digit_Str ("572") = 4, "String calc failed");
   Put_Line ("      PASS");

   --  TEST 4 - String Verification Variant
   Put_Line ("TEST 4 - String Verification");
   Put_Line ("  4.1 Assert ""5724"" verifies as True");
   Assert (Verify_Number_Str ("5724") = True,
           "String verification failed");
   Put_Line ("      PASS");

   --  TEST 5 - Detect Single Digit Error
   Put_Line ("TEST 5 - Single Digit Error Detection");
   Put_Line ("  5.1 Assert ""5734"" (wrong 3rd digit) evaluates to False");
   Assert (Verify_Number_Str ("5734") = False,
           "Failed to catch single-digit error");
   Put_Line ("      PASS");

   --  TEST 6 - Detect Adjacent Transposition Error
   Put_Line ("TEST 6 - Adjacent Transposition Detection");
   Put_Line ("  6.1 Assert ""5274"" (transposed 7 and 2) is False");
   Assert (Verify_Number_Str ("5274") = False,
           "Failed to catch transposition error");
   Put_Line ("      PASS");

   --  TEST 7 - Empty Array Handling (Calculation)
   Put_Line ("TEST 7 - Edge Case: Empty Array Calculation");
   Put_Line ("  7.1 Assert empty array raises Invalid_Input");
   begin
      declare
         Empty_Arr : constant Digit_Array (1 .. 0) := (others => 0);
         Dummy     : Digit;
      begin
         Dummy := Calculate_Check_Digit (Empty_Arr);
         Assert (False, "Did not raise exception on empty array");
      end;
   exception
      when Invalid_Input => Put_Line ("      PASS");
   end;

   --  TEST 8 - Edge Case: Single Digit Verification
   Put_Line ("TEST 8 - Edge Case: Short Array Verification");
   Put_Line ("  8.1 Assert 1-digit array raises Invalid_Input");
   begin
      declare
         Short_Arr : constant Digit_Array (1 .. 1) := (others => 5);
         Dummy     : Boolean;
      begin
         Dummy := Verify_Number (Short_Arr);
         Assert (False, "Did not raise exception on short array");
      end;
   exception
      when Invalid_Input => Put_Line ("      PASS");
   end;

   --  TEST 9 - String Variant Invalid Character
   Put_Line ("TEST 9 - Invalid String Inputs");
   Put_Line ("  9.1 Assert alpha character raises Invalid_Input");
   begin
      declare
         Dummy : Digit;
      begin
         Dummy := Calculate_Check_Digit_Str ("57A2");
         Assert (False, "Did not catch alphabetical character");
      end;
   exception
      when Invalid_Input => Put_Line ("      PASS");
   end;

   --  TEST 10 - Array Appending Function
   Put_Line ("TEST 10 - Append Check Digit Utility");
   Put_Line ("  10.1 Assert [5, 7, 2] appends to [5, 7, 2, 4]");
   declare
      Expected : constant Digit_Array := (5, 7, 2, 4);
      Result   : constant Digit_Array := Append_Check_Digit ((5, 7, 2));
   begin
      Assert (Result = Expected, "Append utility failed");
      Put_Line ("      PASS");
   end;

   --  TEST 11 - All Zeros Check
   Put_Line ("TEST 11 - All Zeros Input");
   Put_Line ("  11.1 Assert check digit for ""000"" is 0");
   Assert (Calculate_Check_Digit_Str ("000") = 0,
           "Zeros calculation failed");
   Put_Line ("  11.2 Assert ""0000"" verifies as True");
   Assert (Verify_Number_Str ("0000") = True,
           "Zeros verification failed");
   Put_Line ("      PASS");

   --  TEST 12 - Single Digit Check Generation
   Put_Line ("TEST 12 - Single Digit Base");
   Put_Line ("  12.1 Assert check digit for ""5"" is 9");
   Assert (Calculate_Check_Digit_Str ("5") = 9,
           "Single digit calculation failed");
   Put_Line ("      PASS");

   --  TEST 13 - Minimal Valid String Verification
   Put_Line ("TEST 13 - Minimal Valid String Verification");
   Put_Line ("  13.1 Assert ""59"" verifies as True");
   Assert (Verify_Number_Str ("59") = True,
           "Minimal string verification failed");
   Put_Line ("      PASS");
   
   --  TEST 14 - Long String of Digits
   Put_Line ("TEST 14 - Stress/Long String");
   Put_Line ("  14.1 Assert check digit for long string works");
   declare
      Res : constant Digit :=
        Calculate_Check_Digit_Str ("12345678901234567890");
   begin
      Assert (Res'Valid, "Long string output out of bounds");
      Put_Line ("      PASS");
   end;

   Put_Line ("----------------------------------------");
   Put_Line ("All tests passed successfully.");
end Tests;
