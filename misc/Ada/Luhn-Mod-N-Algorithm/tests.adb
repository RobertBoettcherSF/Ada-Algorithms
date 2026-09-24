-- tests.adb
-- Validation and Verification (V&V) Test Suite

with Ada.Text_IO;  use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Luhn_Mod_N;   use Luhn_Mod_N;

procedure Tests is
   Num_Codec   : Codec;
   Hex_Codec   : Codec;
   Alpha_Codec : Codec;
begin
   -- Initialize codecs
   Num_Codec   := Create_Codec("0123456789");
   Hex_Codec   := Create_Codec("0123456789abcdef");
   Alpha_Codec := Create_Codec("aA");

   Put_Line("=== Running V&V Test Suite ===");

   Put_Line("TEST 1 - Base 10 Generation Correctness");
   Put_Line("  1.1 Assert known generation pattern proves correct logic");
   Assert (Generate_Check_Character(Num_Codec, "7992739871") = '3', "Generation Failed");
   Put_Line("      PASS");

   Put_Line("TEST 2 - Base 10 Validation Correctness");
   Put_Line("  2.1 Assert correctly formatted strings pass validation");
   Assert (Validate(Num_Codec, "79927398713"), "Validation Failed");
   Put_Line("      PASS");

   Put_Line("TEST 3 - Invalid Check Character Detection");
   Put_Line("  3.1 Assert corrupted check character causes validation failure");
   Assert (not Validate(Num_Codec, "79927398714"), "Invalid validation succeeded");
   Put_Line("      PASS");

   Put_Line("TEST 4 - Invalid Data Character Detection");
   Put_Line("  4.1 Assert corrupted data character causes validation failure");
   Assert (not Validate(Num_Codec, "79937398713"), "Invalid validation succeeded");
   Put_Line("      PASS");

   Put_Line("TEST 5 - Append Helper Functionality");
   Put_Line("  5.1 Assert Append joins string and calculated char correctly");
   Assert (Append_Check_Character(Num_Codec, "123") = "1230", "Append failed");
   Put_Line("      PASS");

   Put_Line("TEST 6 - Empty Alphabet Handling (Boundary)");
   Put_Line("  6.1 Assert empty alphabet is rejected");
   begin
      declare
         Bad : Codec := Create_Codec("");
      begin
         Assert (False, "Expected Invalid_Alphabet exception");
      end;
   exception
      when Invalid_Alphabet => Put_Line("      PASS");
   end;

   Put_Line("TEST 7 - Undersized Alphabet Handling (Boundary)");
   Put_Line("  7.1 Assert alphabet of size 1 is rejected");
   begin
      declare
         Bad : Codec := Create_Codec("a");
      begin
         Assert (False, "Expected Invalid_Alphabet exception");
      end;
   exception
      when Invalid_Alphabet => Put_Line("      PASS");
   end;

   Put_Line("TEST 8 - Duplicate Character Detection (Integrity)");
   Put_Line("  8.1 Assert duplicated map characters are rejected");
   begin
      declare
         Bad : Codec := Create_Codec("0123345");
      begin
         Assert (False, "Expected Invalid_Alphabet exception");
      end;
   exception
      when Invalid_Alphabet => Put_Line("      PASS");
   end;

   Put_Line("TEST 9 - Empty Input Generation (Edge Case)");
   Put_Line("  9.1 Assert empty generation fails safely");
   begin
      declare
         Res : Character := Generate_Check_Character(Num_Codec, "");
      begin
         Assert (False, "Expected Empty_Input exception");
      end;
   exception
      when Empty_Input => Put_Line("      PASS");
   end;

   Put_Line("TEST 10 - Unmapped Character Input (Error Handling)");
   Put_Line("  10.1 Assert unknown character generation fails safely");
   begin
      declare
         Res : Character := Generate_Check_Character(Num_Codec, "123a");
      begin
         Assert (False, "Expected Invalid_Character exception");
      end;
   exception
      when Invalid_Character => Put_Line("      PASS");
   end;

   Put_Line("TEST 11 - Hexadecimal Generation Compatibility");
   Put_Line("  11.1 Assert algorithm scales to base-16 strings");
   Assert (Generate_Check_Character(Hex_Codec, "a") = 'b', "Hex generation failed");
   Put_Line("      PASS");

   Put_Line("TEST 12 - Hexadecimal Validation Compatibility");
   Put_Line("  12.1 Assert algorithm safely validates base-16 logic");
   Assert (Validate(Hex_Codec, "ab"), "Hex validation failed");
   Put_Line("      PASS");

   Put_Line("TEST 13 - Case Sensitivity Resolution");
   Put_Line("  13.1 Assert codec maps distinct code-points to case variances");
   Assert (Generate_Check_Character(Alpha_Codec, "a") = 'a', "Case handling failed");
   Assert (Generate_Check_Character(Alpha_Codec, "A") = 'A', "Case handling failed");
   Put_Line("      PASS");

   Put_Line("=== All V&V Tests Completed Successfully ===");
end Tests;
