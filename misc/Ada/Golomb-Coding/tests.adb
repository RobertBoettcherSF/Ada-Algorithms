-- tests.adb
-- A comprehensive validation suite verifying correct behavior of the Golomb algorithms

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Golomb_Coding; use Golomb_Coding;

procedure Tests is
   Consumed_Count : Natural;
begin
   Put_Line ("Starting V&V Test Suite for Golomb Coding Modules...");
   Put_Line ("Assuming failure, passing tests proves reliability.");
   New_Line;

   -- TEST 1
   Put_Line ("TEST 1 - Standard Golomb Encoding (Normal)");
   Put_Line ("  1.1 Assert N=42, M=10 correctly encodes as 11110010");
   Assert (Encode_Golomb (42, 10) = "11110010", "Encoding failed for 42, 10");
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Standard Golomb Decoding (Normal)");
   Put_Line ("  2.1 Assert bits 11110010 decode exactly to N=42 with M=10");
   Assert (Decode_Golomb_Exact ("11110010", 10) = 42, "Decoding failed for 42");
   Put_Line ("      PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Truncated Binary Cutoff Logic (Upper Bound)");
   Put_Line ("  3.1 Assert N=46, M=10 correctly encodes as 111101100 (using 4 bits for remainder)");
   Assert (Encode_Golomb (46, 10) = "111101100", "Encoding failed for upper limit remainder");
   Put_Line ("  3.2 Assert bits 111101100 decode exactly to N=46 with M=10");
   Assert (Decode_Golomb_Exact ("111101100", 10) = 46, "Decoding failed for upper limit remainder");
   Put_Line ("      PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Unary Extreme Edge Case (M=1)");
   Put_Line ("  4.1 Assert N=5, M=1 uses pure unary encoding (111110)");
   Assert (Encode_Golomb (5, 1) = "111110", "Pure unary encoding failed");
   Put_Line ("  4.2 Assert 111110 with M=1 decodes back to 5");
   Assert (Decode_Golomb_Exact ("111110", 1) = 5, "Pure unary decoding failed");
   Put_Line ("      PASS");

   -- TEST 5
   Put_Line ("TEST 5 - Base Value Edge Case (N=0)");
   Put_Line ("  5.1 Assert N=0 encodes properly depending on M (M=10 -> 0000)");
   Assert (Encode_Golomb (0, 10) = "0000", "Zero encoding failed");
   Put_Line ("      PASS");

   -- TEST 6
   Put_Line ("TEST 6 - Rice Coding Variant Encoding (M=2^K)");
   Put_Line ("  6.1 Assert N=10, K=2 (M=4) encodes correctly as 11010");
   Assert (Encode_Rice (10, 2) = "11010", "Rice encoding failed");
   Put_Line ("      PASS");

   -- TEST 7
   Put_Line ("TEST 7 - Rice Coding Variant Decoding");
   Put_Line ("  7.1 Assert bits 11010 decode to N=10 with K=2");
   Assert (Decode_Rice_Exact ("11010", 2) = 10, "Rice decoding failed");
   Put_Line ("      PASS");

   -- TEST 8
   Put_Line ("TEST 8 - Signed Golomb Variant (Negative N)");
   Put_Line ("  8.1 Assert N=-1, M=10 Zig-Zag maps correctly and encodes to 0001");
   Assert (Encode_Signed_Golomb (-1, 10) = "0001", "Signed negative encoding failed");
   Put_Line ("  8.2 Assert bits 0001 decode properly to N=-1");
   Assert (Decode_Signed_Golomb_Exact ("0001", 10) = -1, "Signed negative decoding failed");
   Put_Line ("      PASS");

   -- TEST 9
   Put_Line ("TEST 9 - Signed Golomb Variant (Positive N)");
   Put_Line ("  9.1 Assert N=2, M=10 Zig-Zag maps correctly and encodes to 0100");
   Assert (Encode_Signed_Golomb (2, 10) = "0100", "Signed positive encoding failed");
   Put_Line ("      PASS");

   -- TEST 10
   Put_Line ("TEST 10 - Buffer Over-read Resistance (Consumed Tracking)");
   Put_Line ("  10.1 Assert Decoding 1111001011 (with garbage '11' at end) ignores garbage");
   Assert (Decode_Golomb ("1111001011", 10, Consumed_Count) = 42, "Failed to decode padded string");
   Put_Line ("  10.2 Assert Consumed_Count returns exactly 8 bits consumed");
   Assert (Consumed_Count = 8, "Consumed count tracking is incorrect");
   Put_Line ("      PASS");

   -- TEST 11
   Put_Line ("TEST 11 - Error Handling: Missing Stop Bit");
   Put_Line ("  11.1 Assert missing '0' in unary raises Invalid_Bit_String");
   begin
      declare
         Dummy : Natural := Decode_Golomb_Exact ("11111", 10);
      begin
         Assert (False, "Exception not raised for missing stop bit");
      end;
   exception
      when Invalid_Bit_String =>
         Put_Line ("      PASS");
   end;

   -- TEST 12
   Put_Line ("TEST 12 - Error Handling: Non-Binary Characters");
   Put_Line ("  12.1 Assert non-binary characters raise Invalid_Bit_String");
   begin
      declare
         Dummy : Natural := Decode_Golomb_Exact ("110A", 10);
      begin
         Assert (False, "Exception not raised for garbage char");
      end;
   exception
      when Invalid_Bit_String =>
         Put_Line ("      PASS");
   end;

   -- TEST 13
   Put_Line ("TEST 13 - Error Handling: Exact Decode Mismatch");
   Put_Line ("  13.1 Assert Exact Decode raises error if bits are unconsumed");
   begin
      declare
         Dummy : Natural := Decode_Rice_Exact ("110101", 2);
      begin
         Assert (False, "Exception not raised for unconsumed bits in Exact decode");
      end;
   exception
      when Invalid_Bit_String =>
         Put_Line ("      PASS");
   end;
   
   -- TEST 14
   Put_Line ("TEST 14 - Error Handling: Truncated Binary Underflow");
   Put_Line ("  14.1 Assert Exception when remainder bits are completely missing");
   begin
      declare
         Dummy : Natural := Decode_Golomb_Exact ("1110", 10);
      begin
         Assert (False, "Exception not raised for truncated remainder");
      end;
   exception
      when Invalid_Bit_String =>
         Put_Line ("      PASS");
   end;

   New_Line;
   Put_Line ("=====================================");
   Put_Line ("ALL TESTS SUCCESSFULLY PASSED!");
   Put_Line ("System Validation Verified.");
   Put_Line ("=====================================");

end Tests;
