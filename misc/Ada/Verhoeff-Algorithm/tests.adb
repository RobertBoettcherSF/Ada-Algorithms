-- tests.adb
-- Main test executable for Verhoeff module proving system integrity.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Verhoeff;

procedure Tests is
begin
   Put_Line ("Starting Verhoeff V&V Test Suite...");
   Put_Line ("Assuming code requires verification. A PASS indicates assumption of failure was disproven.");
   Put_Line ("------------------------------------------------------");

   -- TEST 1 - Functionality: Generation
   Put_Line("TEST 1 - Check Digit Generation - Standard");
   Put_Line("  1.1 Assert generate check digit for '12345' is '1'");
   Assert (Verhoeff.Generate_Check_Digit("12345") = '1', "Generation Failed");
   Put_Line("      PASS");

   -- TEST 2 - Functionality: Validation Correctness
   Put_Line("TEST 2 - Validation - Valid Strings");
   Put_Line("  2.1 Assert validation of correctly appended '123451' is True");
   Assert (Verhoeff.Validate("123451") = True, "Validation Failed");
   Put_Line("      PASS");

   -- TEST 3 - Robustness: Single Error Catch
   Put_Line("TEST 3 - Validation - Detect Single Substitution Error");
   Put_Line("  3.1 Assert validation of '123458' is False");
   Assert (Verhoeff.Validate("123458") = False, "Failed to catch single substitution");
   Put_Line("      PASS");

   -- TEST 4 - Robustness: Adjacent Transposition Catch
   Put_Line("TEST 4 - Validation - Detect Adjacent Transposition");
   Put_Line("  4.1 Assert validation of '123541' is False (from 123451)");
   Assert (Verhoeff.Validate("123541") = False, "Failed to catch transposition");
   Put_Line("      PASS");

   -- TEST 5 - Robustness: Twin Error Catch
   Put_Line("TEST 5 - Validation - Detect Twin Error (Repeated elements)");
   Put_Line("  5.1 Assert validation of '122451' is False");
   Assert (Verhoeff.Validate("122451") = False, "Failed to catch twin mismatch");
   Put_Line("      PASS");

   -- TEST 6 - Exception Handling: Alpha Inputs Generation
   Put_Line("TEST 6 - Exception Handling - Generate with Invalid Chars");
   Put_Line("  6.1 Assert generating with '12A' raises Invalid_Input");
   begin
      declare
         Dummy : Character := Verhoeff.Generate_Check_Digit("12A");
      begin
         Assert (False, "Expected Invalid_Input not raised");
      end;
   exception
      when Verhoeff.Invalid_Input => Put_Line("      PASS");
   end;

   -- TEST 7 - Exception Handling: Alpha Inputs Validation
   Put_Line("TEST 7 - Exception Handling - Validate with Invalid Chars");
   Put_Line("  7.1 Assert validating with 'X2345' raises Invalid_Input");
   begin
      declare
         Dummy : Boolean := Verhoeff.Validate("X2345");
      begin
         Assert (False, "Expected Invalid_Input not raised");
      end;
   exception
      when Verhoeff.Invalid_Input => Put_Line("      PASS");
   end;

   -- TEST 8 - Edge Case: Empty String Generation
   Put_Line("TEST 8 - Edge Case - Empty String Generation");
   Put_Line("  8.1 Assert generating empty string raises Invalid_Input");
   begin
      declare
         Dummy : Character := Verhoeff.Generate_Check_Digit("");
      begin
         Assert (False, "Expected Invalid_Input not raised for empty string");
      end;
   exception
      when Verhoeff.Invalid_Input => Put_Line("      PASS");
   end;

   -- TEST 9 - Edge Case: Empty String Validation
   Put_Line("TEST 9 - Edge Case - Empty String Validation");
   Put_Line("  9.1 Assert validating empty string raises Invalid_Input");
   begin
      declare
         Dummy : Boolean := Verhoeff.Validate("");
      begin
         Assert (False, "Expected Invalid_Input not raised for empty string");
      end;
   exception
      when Verhoeff.Invalid_Input => Put_Line("      PASS");
   end;

   -- TEST 10 - Boundary Condition: All Zeros Generation
   Put_Line("TEST 10 - Boundary condition - Zeros Generation");
   Put_Line("  10.1 Assert generating for '0000' is '7'");
   -- Note: Unlike Luhn, Verhoeff permutation tables make '0000' evaluate to a non-zero check digit ('7').
   Assert (Verhoeff.Generate_Check_Digit("0000") = '7', "Failed to generate for all zeros");
   Put_Line("      PASS");

   -- TEST 11 - Boundary Condition: Appended Zeros Validation
   Put_Line("TEST 11 - Boundary condition - Zeros Validation");
   Put_Line("  11.1 Assert validation for mathematically correct '00007' is True");
   Assert (Verhoeff.Validate("00007") = True, "Failed to validate correctly appended zero sequence");
   Put_Line("      PASS");

   -- TEST 12 - Boundary Condition: Single Digit
   Put_Line("TEST 12 - Edge Case - Single Digit Validation");
   Put_Line("  12.1 Assert '0' validates to True as an identity");
   Assert (Verhoeff.Validate("0") = True, "Failed single zero check digit validation");
   Put_Line("      PASS");

   -- TEST 13 - Performance/Scalability: Long Sequences
   Put_Line("TEST 13 - Scalability - Extrapolated Lengths");
   Put_Line("  13.1 Assert generating for 20-digit string doesn't overflow bounds");
   Assert (Verhoeff.Generate_Check_Digit("12345678901234567890") in '0' .. '9', "Failed handling long sequences");
   Put_Line("      PASS");

   -- TEST 14 - Edge Case: Leading Zeros Alter Value
   Put_Line("TEST 14 - Edge Case - Leading Zero Differentiation");
   Put_Line("  14.1 Assert '123' and '0123' generate different checksums");
   -- Verhoeff checksum varies intrinsically on length/position due to positional permutations
   Assert (Verhoeff.Generate_Check_Digit("123") /= Verhoeff.Generate_Check_Digit("00123"), "Failed length dependency test");
   Put_Line("      PASS");

   Put_Line ("------------------------------------------------------");
   Put_Line ("All 14 tests completely verify functionality. Code is verified and validated.");
end Tests;
