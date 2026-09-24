-- tests.adb
-- Comprehensive testing suite using pessimistic initial assumptions.
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Rice_Coding; use Rice_Coding;

procedure Tests is
   Encoded : Unbounded_String;
   Decoded : Unsigned_Value;
   Dec_Sgn : Signed_Value;
begin
   Put_Line ("--- V&V TEST SUITE: RICE & GOLOMB CODING ---");

   -- TEST 1 - Functional: Standard Rice Encoding (Basic case)
   Put_Line ("TEST 1 - Standard Rice Encoding (Value=10, K=2)");
   Put_Line ("  1.1 Assert Q=2, R=2 encoded as 11010");
   Encoded := Encode_Rice (10, 2);
   Assert (To_String (Encoded) = "11010", "Encoding mismatch");
   Put_Line ("     PASS");

   -- TEST 2 - Functional: Standard Rice Decoding
   Put_Line ("TEST 2 - Standard Rice Decoding");
   Put_Line ("  2.1 Assert decoding '11010' with K=2 equals 10");
   Decoded := Decode_Rice (To_Unbounded_String ("11010"), 2);
   Assert (Decoded = 10, "Decoding mismatch");
   Put_Line ("     PASS");

   -- TEST 3 - Edge Case: Minimal Parameters
   Put_Line ("TEST 3 - Rice Edge Case (Value=0, K=0)");
   Put_Line ("  3.1 Assert Value=0, K=0 encodes to just terminator '0'");
   Encoded := Encode_Rice (0, 0);
   Assert (To_String (Encoded) = "0", "Minimal parameter encoding failed");
   Put_Line ("     PASS");

   -- TEST 4 - Edge Case: Round-Trip Minimal Parameters
   Put_Line ("TEST 4 - Rice Round-Trip Edge Case (Value=0, K=0)");
   Put_Line ("  4.1 Assert decoding '0' with K=0 is 0");
   Decoded := Decode_Rice (To_Unbounded_String ("0"), 0);
   Assert (Decoded = 0, "Minimal parameter round-trip failed");
   Put_Line ("     PASS");

   -- TEST 5 - Functional: Large Value Rice Coding
   Put_Line ("TEST 5 - Large Value Handling (Value=255, K=4)");
   Put_Line ("  5.1 Assert 255 encoded / decoded smoothly");
   Encoded := Encode_Rice (255, 4);
   Decoded := Decode_Rice (Encoded, 4);
   Assert (Decoded = 255, "Large value mismatch");
   Put_Line ("     PASS");

   -- TEST 6 - Robustness: Signed Rice Encoding (Positive)
   Put_Line ("TEST 6 - Signed Rice Encoding (Positive value +1)");
   Put_Line ("  6.1 Assert ZigZag map maps +1 to 2 -> Unary '110' (if K=0)");
   Encoded := Encode_Signed_Rice (1, 0);
   Assert (To_String (Encoded) = "110", "Signed positive mapping failed");
   Put_Line ("     PASS");

   -- TEST 7 - Robustness: Signed Rice Encoding (Negative)
   Put_Line ("TEST 7 - Signed Rice Encoding (Negative value -1)");
   Put_Line ("  7.1 Assert ZigZag map maps -1 to 1 -> Unary '10' (if K=0)");
   Encoded := Encode_Signed_Rice (-1, 0);
   Assert (To_String (Encoded) = "10", "Signed negative mapping failed");
   Put_Line ("     PASS");

   -- TEST 8 - Robustness: Signed Rice Decoding Round-trip
   Put_Line ("TEST 8 - Signed Rice Decoding (Negative extreme)");
   Put_Line ("  8.1 Assert round-trip of -420 works");
   Encoded := Encode_Signed_Rice (-420, 3);
   Dec_Sgn := Decode_Signed_Rice (Encoded, 3);
   Assert (Dec_Sgn = -420, "Signed negative roundtrip failed");
   Put_Line ("     PASS");

   -- TEST 9 - Functional: Golomb Encoding (R < Cutoff)
   Put_Line ("TEST 9 - Generalized Golomb Encoding (M=10, Value=42)");
   Put_Line ("  9.1 Assert encode format matching wiki math (R=2 < Cutoff=6)");
   -- Q=4 (11110), R=2. Cutoff for M=10 is 6. C=4. R encoded in C-1 (3) bits -> '010'
   Encoded := Encode_Golomb (42, 10);
   Assert (To_String (Encoded) = "11110010", "Golomb R < Cutoff failed");
   Put_Line ("     PASS");

   -- TEST 10 - Functional: Golomb Decoding (R < Cutoff)
   Put_Line ("TEST 10 - Generalized Golomb Decoding (M=10, R < Cutoff)");
   Put_Line ("  10.1 Assert stream '11110010' decodes back to 42");
   Decoded := Decode_Golomb (To_Unbounded_String ("11110010"), 10);
   Assert (Decoded = 42, "Golomb decode (short path) failed");
   Put_Line ("     PASS");

   -- TEST 11 - Functional: Golomb Encoding (R >= Cutoff)
   Put_Line ("TEST 11 - Generalized Golomb Encoding (M=10, Value=47)");
   Put_Line ("  11.1 Assert encode formats shifted remainder (R=7 >= Cutoff=6)");
   -- Q=4 (11110), R=7. Shifted=13. Encoded in C (4) bits -> '1101'
   Encoded := Encode_Golomb (47, 10);
   Assert (To_String (Encoded) = "111101101", "Golomb R >= Cutoff failed");
   Put_Line ("     PASS");

   -- TEST 12 - Functional: Golomb Decoding (R >= Cutoff)
   Put_Line ("TEST 12 - Generalized Golomb Decoding (M=10, R >= Cutoff)");
   Put_Line ("  12.1 Assert stream '111101101' decodes back to 47");
   Decoded := Decode_Golomb (To_Unbounded_String ("111101101"), 10);
   Assert (Decoded = 47, "Golomb decode (long path) failed");
   Put_Line ("     PASS");

   -- TEST 13 - Error Handling: Missing Unary Terminator
   Put_Line ("TEST 13 - Robustness: Malformed Unary Stream");
   Put_Line ("  13.1 Assert Decoding_Error on missing '0' terminator");
   begin
      Decoded := Decode_Rice (To_Unbounded_String ("1111"), 2);
      Assert (False, "Exception missed");
   exception
      when Decoding_Error => Put_Line ("     PASS");
   end;

   -- TEST 14 - Error Handling: Truncated Remainder Bits
   Put_Line ("TEST 14 - Robustness: Truncated Remainder");
   Put_Line ("  14.1 Assert Decoding_Error on prematurely ended stream");
   begin
      -- '10' implies Q=1. K=3 expects 3 more bits, but only 1 ('1') is provided
      Decoded := Decode_Rice (To_Unbounded_String ("101"), 3);
      Assert (False, "Exception missed");
   exception
      when Decoding_Error => Put_Line ("     PASS");
   end;

   Put_Line ("--- ALL 14 TESTS PASSED ---");
end Tests;
