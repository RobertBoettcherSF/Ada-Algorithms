-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Unary_Coding; use Unary_Coding;

procedure Tests is
begin
   Put_Line("=================================================");
   Put_Line(" UNARY CODING ALGORITHM: V&V TEST SUITE RUNNING  ");
   Put_Line(" Assuming code is BROKEN. Proving assumption FALSE");
   Put_Line("=================================================");
   Put_Line("");

   -- TEST 1 - Variant 1 (Ones-Zero) Base Case
   Put_Line("TEST 1 - Variant 1 (Ones-Zero) Base Case");
   Put_Line("  1.1 Assume Encode(0) fails to return '0'. Asserting equality to disprove.");
   Assert (Encode_Ones_Zero(0) = "0", "Encode_Ones_Zero(0) is broken");
   Put_Line("     PASS");

   -- TEST 2 - Variant 1 Normal Case
   Put_Line("TEST 2 - Variant 1 (Ones-Zero) Standard Usage");
   Put_Line("  2.1 Assume Encode(5) does not equal '111110'. Asserting equality to disprove.");
   Assert (Encode_Ones_Zero(5) = "111110", "Encode_Ones_Zero(5) is broken");
   Put_Line("     PASS");

   -- TEST 3 - Variant 1 Decode Normal Case
   Put_Line("TEST 3 - Variant 1 Decode Standard Usage");
   Put_Line("  3.1 Assume Decode('1110') != 3. Asserting equality to disprove.");
   Assert (Decode_Ones_Zero("1110") = 3, "Decode_Ones_Zero('1110') is broken");
   Put_Line("     PASS");

   -- TEST 4 - Variant 2 (Zeros-One) Base Case
   Put_Line("TEST 4 - Variant 2 (Zeros-One) Base Case");
   Put_Line("  4.1 Assume Encode(0) fails to return '1'. Asserting equality to disprove.");
   Assert (Encode_Zeros_One(0) = "1", "Encode_Zeros_One(0) is broken");
   Put_Line("     PASS");

   -- TEST 5 - Variant 2 Normal Case
   Put_Line("TEST 5 - Variant 2 (Zeros-One) Standard Usage");
   Put_Line("  5.1 Assume Encode(4) does not equal '00001'. Asserting equality to disprove.");
   Assert (Encode_Zeros_One(4) = "00001", "Encode_Zeros_One(4) is broken");
   Put_Line("     PASS");

   -- TEST 6 - Variant 2 Decode Normal Case
   Put_Line("TEST 6 - Variant 2 Decode Standard Usage");
   Put_Line("  6.1 Assume Decode('0001') != 3. Asserting equality to disprove.");
   Assert (Decode_Zeros_One("0001") = 3, "Decode_Zeros_One('0001') is broken");
   Put_Line("     PASS");

   -- TEST 7 - Variant 3 (Positive 1-based) Base Case
   Put_Line("TEST 7 - Variant 3 (Positive 1-Based) Minimum Boundary");
   Put_Line("  7.1 Assume Encode(1) != '0'. Asserting equality to disprove.");
   Assert (Encode_Positive_Ones(1) = "0", "Encode_Positive_Ones(1) is broken");
   Put_Line("     PASS");

   -- TEST 8 - Variant 3 Normal Case
   Put_Line("TEST 8 - Variant 3 (Positive 1-Based) Decode Usage");
   Put_Line("  8.1 Assume Decode('11110') != 5. Asserting equality to disprove.");
   Assert (Decode_Positive_Ones("11110") = 5, "Decode_Positive_Ones('11110') is broken");
   Put_Line("     PASS");

   -- TEST 9 - Robustness: Missing Terminator
   Put_Line("TEST 9 - Error Handling: Missing Terminator");
   Put_Line("  9.1 Assume Decode('1111') does not raise Invalid_Encoding.");
   begin
      declare
         Val : Unary_Value := Decode_Ones_Zero("1111");
      begin
         Assert (False, "Code failed to catch missing terminator.");
      end;
   exception
      when Invalid_Encoding => Put_Line("     PASS");
   end;

   -- TEST 10 - Robustness: Terminator in middle of string
   Put_Line("TEST 10 - Error Handling: Premature Terminator");
   Put_Line("  10.1 Assume Decode('1101') does not raise Invalid_Encoding.");
   begin
      declare
         Val : Unary_Value := Decode_Ones_Zero("1101");
      begin
         Assert (False, "Code failed to catch premature terminator.");
      end;
   exception
      when Invalid_Encoding => Put_Line("     PASS");
   end;

   -- TEST 11 - Robustness: Empty String
   Put_Line("TEST 11 - Error Handling: Empty Input");
   Put_Line("  11.1 Assume decoding empty string skips validation.");
   begin
      declare
         Val : Unary_Value := Decode_Zeros_One("");
      begin
         Assert (False, "Code failed to catch empty string input.");
      end;
   exception
      when Invalid_Encoding => Put_Line("     PASS");
   end;

   -- TEST 12 - Robustness: Invalid Characters
   Put_Line("TEST 12 - Error Handling: Invalid Characters");
   Put_Line("  12.1 Assume '11X0' processes without error.");
   begin
      declare
         Val : Unary_Value := Decode_Ones_Zero("11X0");
      begin
         Assert (False, "Code failed to catch illegal character.");
      end;
   exception
      when Invalid_Encoding => Put_Line("     PASS");
   end;

   -- TEST 13 - Performance/Boundary: Large Encode/Decode
   Put_Line("TEST 13 - Boundary: Large Values");
   Put_Line("  13.1 Assume roundtrip of 10,000 mutates data or causes buffer overflow.");
   declare
      Large_Code : String := Encode_Ones_Zero(10_000);
      Decoded_Val : Unary_Value := Decode_Ones_Zero(Large_Code);
   begin
      Assert(Decoded_Val = 10_000, "Large boundary string logic is broken");
      Put_Line("     PASS");
   end;

   -- TEST 14 - Invalid Zeros_One Decode
   Put_Line("TEST 14 - Error Handling: Zeros_One Invalid Character");
   Put_Line("  14.1 Assume '0010' does not raise exception in Decode_Zeros_One.");
   begin
      declare
         Val : Unary_Value := Decode_Zeros_One("0010");
      begin
         Assert (False, "Code failed to catch trailing garbage after terminator.");
      end;
   exception
      when Invalid_Encoding => Put_Line("     PASS");
   end;

   Put_Line("");
   Put_Line("=================================================");
   Put_Line(" ALL ASSUMPTIONS DISPROVEN. SYSTEM IS FUNCTIONAL.");
   Put_Line("=================================================");
end Tests;
