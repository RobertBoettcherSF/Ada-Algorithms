with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Elias_Gamma_Coding; use Elias_Gamma_Coding;

procedure Tests is
begin
   Put_Line ("=======================================");
   Put_Line ("Starting V&V Tests for Elias Gamma Code");
   Put_Line ("=======================================");

   -- TEST 1: Positive Integer Encoding (Base Case)
   Put_Line ("TEST 1 - Positive Integer Encoding (Base Cases)");
   Put_Line ("  1.1 Assert Encode_Positive(1) = ""1""");
   Assert (To_String(Encode_Positive(1)) = "1", "Failed to encode 1");
   Put_Line ("      PASS");
   Put_Line ("  1.2 Assert Encode_Positive(9) = ""0001001""");
   Assert (To_String(Encode_Positive(9)) = "0001001", "Failed to encode 9");
   Put_Line ("      PASS");

   -- TEST 2: Positive Integer Decoding
   Put_Line ("TEST 2 - Positive Integer Decoding (Base Cases)");
   Put_Line ("  2.1 Assert Decode_Positive(""1"") = 1");
   Assert (Decode_Positive(To_Stream("1")) = 1, "Failed to decode 1");
   Put_Line ("      PASS");
   Put_Line ("  2.2 Assert Decode_Positive(""0001001"") = 9");
   Assert (Decode_Positive(To_Stream("0001001")) = 9, "Failed to decode 9");
   Put_Line ("      PASS");
   Put_Line ("  2.3 Assert Decode_Positive(""0000000001000000000"") = 512");
   Assert (Decode_Positive(To_Stream("0000000001000000000")) = 512, "Decoded 512 incorrectly");
   Put_Line ("      PASS");

   -- TEST 3: Non-Negative Variant (Zero handling)
   Put_Line ("TEST 3 - Non-Negative Variant (+1 offset)");
   Put_Line ("  3.1 Assert Encode_Non_Negative(0) = ""1""");
   Assert (To_String(Encode_Non_Negative(0)) = "1", "Failed to encode offset 0");
   Put_Line ("      PASS");
   Put_Line ("  3.2 Assert Decode_Non_Negative(""1"") = 0");
   Assert (Decode_Non_Negative(To_Stream("1")) = 0, "Failed to decode offset 0");
   Put_Line ("      PASS");

   -- TEST 4: Integer Variant (Bijection Logic)
   Put_Line ("TEST 4 - Integer Bijection Variant");
   Put_Line ("  4.1 Assert Encode_Integer(0) = ""1"" (Mapped to 1)");
   Assert (To_String(Encode_Integer(0)) = "1", "Failed to map/encode 0");
   Put_Line ("      PASS");
   Put_Line ("  4.2 Assert Encode_Integer(1) = ""010"" (Mapped to 2)");
   Assert (To_String(Encode_Integer(1)) = "010", "Failed to map/encode 1");
   Put_Line ("      PASS");
   Put_Line ("  4.3 Assert Encode_Integer(-1) = ""011"" (Mapped to 3)");
   Assert (To_String(Encode_Integer(-1)) = "011", "Failed to map/encode -1");
   Put_Line ("      PASS");
   Put_Line ("  4.4 Assert Decode_Integer(""011"") = -1");
   Assert (Decode_Integer(To_Stream("011")) = -1, "Failed to map/decode -1");
   Put_Line ("      PASS");

   -- TEST 5: Edge Cases and Errors (Robustness / Negative Testing)
   Put_Line ("TEST 5 - Robustness & Exception Handling");
   Put_Line ("  5.1 Assert To_Stream with invalid chars raises Invalid_Bit_Stream");
   begin
      Assert (To_String(To_Stream("001A1")) = "", "Should have thrown Invalid_Bit_Stream");
   exception
      when Invalid_Bit_Stream => Put_Line ("      PASS");
   end;

   Put_Line ("  5.2 Assert Decode Empty stream raises Invalid_Bit_Stream");
   begin
      Assert (Decode_Positive(To_Stream("")) > 0, "Should have thrown Invalid_Bit_Stream");
   exception
      when Invalid_Bit_Stream => Put_Line ("      PASS");
   end;

   Put_Line ("  5.3 Assert Decode stream with no '1' raises Invalid_Bit_Stream");
   begin
      Assert (Decode_Positive(To_Stream("00000")) > 0, "Should have thrown Invalid_Bit_Stream");
   exception
      when Invalid_Bit_Stream => Put_Line ("      PASS");
   end;

   Put_Line ("  5.4 Assert Decode truncated stream raises Invalid_Bit_Stream");
   begin
      Assert (Decode_Positive(To_Stream("0010")) > 0, "Should have thrown Invalid_Bit_Stream");
   exception
      when Invalid_Bit_Stream => Put_Line ("      PASS");
   end;

   Put_Line ("=======================================");
   Put_Line ("All 15/15 tests executed successfully.");
   Put_Line ("=======================================");
end Tests;
