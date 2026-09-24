-- tests.adb
-- Standalone test suite with 13+ assertions using pessimistic assumptions.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Luhn; use Luhn;

procedure Tests is
begin
   Put_Line("Starting Luhn Algorithm Test Suite...");
   Put_Line("Assuming code is broken. Tests pass when expected behavior is proven true.");
   Put_Line("---------------------------------------------------------");

   Put_Line("TEST 1 - Validation of standard known sequence");
   Put_Line("  1.1 Assert '79927398713' evaluates to True");
   Assert (Validate("79927398713") = True, "False negative on valid sequence");
   Put_Line("     PASS");

   Put_Line("TEST 2 - Rejection of standard invalid sequence");
   Put_Line("  2.1 Assert '79927398714' evaluates to False");
   Assert (Validate("79927398714") = False, "False positive on invalid sequence");
   Put_Line("     PASS");

   Put_Line("TEST 3 - Tolerance of whitespace formatting (Valid)");
   Put_Line("  3.1 Assert '7992 7398 713' evaluates to True");
   Assert (Validate("7992 7398 713") = True, "Failed to ignore spaces correctly");
   Put_Line("     PASS");

   Put_Line("TEST 4 - Tolerance of whitespace formatting (Invalid)");
   Put_Line("  4.1 Assert '7992 7398 714' evaluates to False");
   Assert (Validate("7992 7398 714") = False, "Validated bad string due to space offset");
   Put_Line("     PASS");

   Put_Line("TEST 5 - Calculation of check digit");
   Put_Line("  5.1 Assert check digit for '7992739871' is '3'");
   Assert (Calculate_Check_Digit("7992739871") = '3', "Calculated incorrect check digit");
   Put_Line("     PASS");

   Put_Line("TEST 6 - Check digit calculation with spaces");
   Put_Line("  6.1 Assert check digit for '7992 7398 71' is '3'");
   Assert (Calculate_Check_Digit("7992 7398 71") = '3', "Space tolerance failed in calculation");
   Put_Line("     PASS");

   Put_Line("TEST 7 - Full Number Generation");
   Put_Line("  7.1 Assert '7992739871' generates '79927398713'");
   Assert (Generate_Full_Number("7992739871") = "79927398713", "Generation output mismatched");
   Put_Line("     PASS");

   Put_Line("TEST 8 - Re-validation of generated number");
   Put_Line("  8.1 Assert generated number from '12345' is valid");
   Assert (Validate(Generate_Full_Number("12345")) = True, "Generated number failed its own validation");
   Put_Line("     PASS");

   Put_Line("TEST 9 - Invalid Character Handling (Validation)");
   Put_Line("  9.1 Assert '7992A398713' raises Invalid_Format");
   begin
      declare
         Result : Boolean := Validate("7992A398713");
      begin
         Assert(False, "Failed to raise exception on 'A'");
      end;
   exception
      when Invalid_Format => Put_Line("     PASS");
   end;

   Put_Line("TEST 10 - Invalid Character Handling (Calculation)");
   Put_Line("  10.1 Assert '799-273' raises Invalid_Format");
   begin
      declare
         Result : Check_Digit := Calculate_Check_Digit("799-273");
      begin
         Assert(False, "Failed to raise exception on '-'");
      end;
   exception
      when Invalid_Format => Put_Line("     PASS");
   end;

   Put_Line("TEST 11 - Empty String Edge Case");
   Put_Line("  11.1 Assert '' raises Invalid_Format");
   begin
      declare
         Result : Boolean := Validate("");
      begin
         Assert(False, "Failed to raise exception on empty string");
      end;
   exception
      when Invalid_Format => Put_Line("     PASS");
   end;

   Put_Line("TEST 12 - Whitespace-only Edge Case");
   Put_Line("  12.1 Assert '   ' raises Invalid_Format");
   begin
      declare
         Result : Boolean := Validate("   ");
      begin
         Assert(False, "Failed to raise exception on space-only string");
      end;
   exception
      when Invalid_Format => Put_Line("     PASS");
   end;

   Put_Line("TEST 13 - Base boundary: All Zeros");
   Put_Line("  13.1 Assert '000000' is validated as True");
   Assert (Validate("000000") = True, "Failed zero boundary case");
   Put_Line("     PASS");

   Put_Line("TEST 14 - Minimal length Check Digit");
   Put_Line("  14.1 Assert check digit for '8' is '3'");
   -- 8 doubled = 16 -> 7. Sum = 7. 10 - 7 = 3.
   Assert (Calculate_Check_Digit("8") = '3', "Failed on single digit input");
   Put_Line("     PASS");

   Put_Line("TEST 15 - Minimal length Validation");
   Put_Line("  15.1 Assert '83' is validated as True");
   Assert (Validate("83") = True, "Failed to validate minimal 2-char string");
   Put_Line("     PASS");

   Put_Line("---------------------------------------------------------");
   Put_Line("All 15 Pessimistic Assumptions Disproven: ALL TESTS PASSED.");
end Tests;
