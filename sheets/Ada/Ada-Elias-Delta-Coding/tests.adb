-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Elias_Delta; use Elias_Delta;

procedure Tests is

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Put_Line("      PASS: " & Message);
      else
         Put_Line("      FAIL: " & Message);
         raise Ada.Assertions.Assertion_Error;
      end if;
   end Check;

begin
   Put_Line("==================================================");
   Put_Line("  ELIAS DELTA CODING - COMPREHENSIVE TEST SUITE");
   Put_Line("==================================================");

   -- TEST 1 - Basic Integer Encoding (Small Values)
   Put_Line("TEST 1 - Basic Integer Encoding (Small Values)");
   Put_Line("   1.1 Verify encoding of integer 1 produces '1'");
   Check(Encode(1) = "1", "Encode(1) should be '1'");
   Put_Line("   1.2 Verify encoding of integer 2 produces '0100'");
   Check(Encode(2) = "0100", "Encode(2) should be '0100'");
   Put_Line("   1.3 Verify encoding of integer 3 produces '0101'");
   Check(Encode(3) = "0101", "Encode(3) should be '0101'");

   -- TEST 2 - Basic Integer Decoding (Small Values)
   Put_Line("TEST 2 - Basic Integer Decoding (Small Values)");
   Put_Line("   2.1 Verify decoding of '1' yields 1");
   Check(Decode("1") = 1, "Decode('1') should be 1");
   Put_Line("   2.2 Verify decoding of '0100' yields 2");
   Check(Decode("0100") = 2, "Decode('0100') should be 2");
   Put_Line("   2.3 Verify decoding of '0101' yields 3");
   Check(Decode("0101") = 3, "Decode('0101') should be 3");

   -- TEST 3 - Power of Two Values (Boundaries)
   Put_Line("TEST 3 - Power of Two Values (Boundaries)");
   Put_Line("   3.1 Verify encoding of 4");
   Check(Encode(4) = "01100", "Encode(4) should be '01100'");
   Put_Line("   3.2 Verify decoding of '01100' yields 4");
   Check(Decode("01100") = 4, "Decode('01100') should be 4");
   Put_Line("   3.3 Verify round-trip for 8 (2^3)");
   Check(Decode(Encode(8)) = 8, "Round-trip for 8 failed");

   -- TEST 4 - Round-Trip Consistency across Medium Integers
   Put_Line("TEST 4 - Round-Trip Consistency across Medium Integers");
   Put_Line("   4.1 Round-trip for integer 15");
   Check(Decode(Encode(15)) = 15, "Round-trip for 15 failed");
   Put_Line("   4.2 Round-trip for integer 16");
   Check(Decode(Encode(16)) = 16, "Round-trip for 16 failed");
   Put_Line("   4.3 Round-trip for integer 100");
   Check(Decode(Encode(100)) = 100, "Round-trip for 100 failed");

   -- TEST 5 - Bit-Vector Interface
   Put_Line("TEST 5 - Bit-Vector Interface");
   Put_Line("   5.1 Encode 5 to Bit_Vector and verify length");
   declare
      BV : constant Bit_Vector := Encode_Bits(5);
   begin
      Check(BV'Length > 0, "Bit_Vector length > 0");
   end;
   Put_Line("   5.2 Decode Bit_Vector back to integer 5");
   Check(Decode_Bits(Encode_Bits(5)) = 5, "Bit_Vector round-trip for 5 failed");
   Put_Line("   5.3 Round-trip Bit_Vector for 64");
   Check(Decode_Bits(Encode_Bits(64)) = 64, "Bit_Vector round-trip for 64 failed");

   -- TEST 6 - Non-Negative Integer Variant (X >= 0)
   Put_Line("TEST 6 - Non-Negative Integer Variant (X >= 0)");
   Put_Line("   6.1 Encode non-negative integer 0");
   declare
      Enc_Zero : constant String := Encode_Non_Negative(0);
   begin
      Check(Enc_Zero = Encode(1), "Encode_Non_Negative(0) equals Encode(1)");
   end;
   Put_Line("   6.2 Decode non-negative integer 0");
   Check(Decode_Non_Negative(Encode_Non_Negative(0)) = 0, "Decode_Non_Negative(0) failed");
   Put_Line("   6.3 Round-trip non-negative integer 42");
   Check(Decode_Non_Negative(Encode_Non_Negative(42)) = 42, "Non-negative round-trip for 42 failed");

   -- TEST 7 - All Signed Integers Variant (ZigZag Mapping)
   Put_Line("TEST 7 - All Signed Integers Variant (ZigZag Mapping)");
   Put_Line("   7.1 Round-trip integer 0 via ZigZag");
   Check(Decode_Integer(Encode_Integer(0)) = 0, "Integer round-trip for 0 failed");
   Put_Line("   7.2 Round-trip negative integer -1");
   Check(Decode_Integer(Encode_Integer(-1)) = -1, "Integer round-trip for -1 failed");
   Put_Line("   7.3 Round-trip positive integer 50 and negative -50");
   Check(Decode_Integer(Encode_Integer(50)) = 50 and Decode_Integer(Encode_Integer(-50)) = -50, "Integer round-trip for +/- 50 failed");

   -- TEST 8 - Helper Function: Integer_To_Binary
   Put_Line("TEST 8 - Helper Function: Integer_To_Binary");
   Put_Line("   8.1 Binary representation of 1");
   Check(Integer_To_Binary(1) = "1", "Binary of 1 is '1'");
   Put_Line("   8.2 Binary representation of 2");
   Check(Integer_To_Binary(2) = "10", "Binary of 2 is '10'");
   Put_Line("   8.3 Binary representation of 5");
   Check(Integer_To_Binary(5) = "101", "Binary of 5 is '101'");

   -- TEST 9 - Helper Function: Binary_To_Integer
   Put_Line("TEST 9 - Helper Function: Binary_To_Integer");
   Put_Line("   9.1 Parse '1' to 1");
   Check(Binary_To_Integer("1") = 1, "Parse '1' failed");
   Put_Line("   9.2 Parse '10' to 2");
   Check(Binary_To_Integer("10") = 2, "Parse '10' failed");
   Put_Line("   9.3 Parse '1101' to 13");
   Check(Binary_To_Integer("1101") = 13, "Parse '1101' failed");

   -- TEST 10 - Helper Function: Gamma_Encode & Decode
   Put_Line("TEST 10 - Helper Function: Gamma_Encode & Decode");
   Put_Line("   10.1 Gamma encode 3");
   Check(Gamma_Encode(3) = "011", "Gamma encode(3) should be '011'");
   Put_Line("   10.2 Gamma decode '011'");
   declare
      Last : Positive;
   begin
      Check(Gamma_Decode("011", Last) = 3 and Last = 3, "Gamma decode failed");
   end;
   Put_Line("   10.3 Gamma round-trip for 10");
   declare
      Last : Positive;
   begin
      Check(Gamma_Decode(Gamma_Encode(10), Last) = 10, "Gamma round-trip failed");
   end;

   -- TEST 11 - Error Handling: Malformed / Empty Bitstreams
   Put_Line("TEST 11 - Error Handling: Malformed / Empty Bitstreams");
   Put_Line("   11.1 Verify decoding empty string raises Invalid_Code");
   begin
      declare
         Res : Positive := Decode("");
      begin
         Check(False, "Expected Invalid_Code not raised for empty string");
      end;
   exception
      when Invalid_Code =>
         Check(True, "Invalid_Code correctly raised for empty string");
   end;

   -- TEST 12 - Error Handling: Invalid Characters in Bitstream
   Put_Line("TEST 12 - Error Handling: Invalid Characters in Bitstream");
   Put_Line("   12.1 Verify decoding string with invalid characters raises Invalid_Code");
   begin
      declare
         Res : Positive := Decode("01X0");
      begin
         Check(False, "Expected Invalid_Code not raised for invalid character");
      end;
   exception
      when Invalid_Code =>
         Check(True, "Invalid_Code correctly raised for invalid character");
   end;

   -- TEST 13 - Boundary Stress Test (Large Integers)
   Put_Line("TEST 13 - Boundary Stress Test (Large Integers)");
   Put_Line("   13.1 Round-trip for 1023 (2^10 - 1)");
   Check(Decode(Encode(1023)) = 1023, "Round-trip for 1023 failed");
   Put_Line("   13.2 Round-trip for 1024 (2^10)");
   Check(Decode(Encode(1024)) = 1024, "Round-trip for 1024 failed");
   Put_Line("   13.3 Round-trip for 65535 (2^16 - 1)");
   Check(Decode(Encode(65535)) = 65535, "Round-trip for 65535 failed");

   Put_Line("==================================================");
   Put_Line("  ALL TESTS PASSED SUCCESSFULLY!");
   Put_Line("==================================================");
end Tests;
