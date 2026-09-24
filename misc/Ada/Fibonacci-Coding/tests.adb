with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Fibonacci_Coding; use Fibonacci_Coding;

procedure Tests is
   procedure Assert_Exception (Action : access procedure) is
   begin
      begin
         Action.all;
         Assert (False, "Expected Invalid_Code exception was NOT raised.");
      exception
         when Invalid_Code => null; -- Proven false: code correctly blocked invalid input
         when others => Assert (False, "Wrong exception raised.");
      end;
   end Assert_Exception;

   procedure Action_Invalid_End is
      Val : Positive_Integer;
   begin Val := Decode_Fibonacci ("01010"); end Action_Invalid_End;

   procedure Action_Consecutive is
      Val : Positive_Integer;
   begin Val := Decode_Fibonacci ("011011"); end Action_Consecutive;

   procedure Action_Gen_Invalid is
      Val : Positive_Integer;
   begin Val := Decode_Generalized ("11011", Order => 3); end Action_Gen_Invalid;
   
   Identity_Val : Positive_Integer;
begin
   Put_Line ("Starting V&V Test Suite for Fibonacci Coding");
   Put_Line ("============================================");

   Put_Line ("TEST 1 - Functional: Standard Encoding (Base)");
   Put_Line ("  1.1 Assume Encode(1) fails Zeckendorf requirement -> Assert = ""11""");
   Assert (Encode_Fibonacci (1) = "11", "Encode(1) failed");
   Put_Line ("      PASS: Assumption disproven.");

   Put_Line ("TEST 2 - Functional: Standard Decoding (Base)");
   Put_Line ("  2.1 Assume Decode(""11"") yields wrong index -> Assert = 1");
   Assert (Decode_Fibonacci ("11") = 1, "Decode(""11"") failed");
   Put_Line ("      PASS: Assumption disproven.");

   Put_Line ("TEST 3 - Functional: Standard Encoding (Complex/Wikipedia)");
   Put_Line ("  3.1 Assume Encode(65) is broken -> Assert = ""0100100011""");
   Assert (Encode_Fibonacci (65) = "0100100011", "Encode(65) failed");
   Put_Line ("      PASS: Assumption disproven.");

   Put_Line ("TEST 4 - Functional: Standard Decoding (Complex/Wikipedia)");
   Put_Line ("  4.1 Assume Decode(""0100100011"") gives wrong sum -> Assert = 65");
   Assert (Decode_Fibonacci ("0100100011") = 65, "Decode(65) failed");
   Put_Line ("      PASS: Assumption disproven.");

   Put_Line ("TEST 5 - Robustness: Decode error on missing terminator");
   Put_Line ("  5.1 Assume Decode parses non-terminated strings -> Assert raises Invalid_Code");
   Assert_Exception (Action_Invalid_End'Access);
   Put_Line ("      PASS: Assumption disproven (Exception caught).");

   Put_Line ("TEST 6 - Robustness: Decode error on premature consecutive 1s");
   Put_Line ("  6.1 Assume Decode ignores inner 11s -> Assert raises Invalid_Code");
   Assert_Exception (Action_Consecutive'Access);
   Put_Line ("      PASS: Assumption disproven (Exception caught).");

   Put_Line ("TEST 7 - Functional: Generalized Order 3 Encoding (Tribonacci Base)");
   Put_Line ("  7.1 Assume Encode_Gen(1, 3) fails terminator constraint -> Assert = ""111""");
   Assert (Encode_Generalized (1, 3) = "111", "Encode_Gen(1, 3) failed");
   Put_Line ("      PASS: Assumption disproven.");

   Put_Line ("TEST 8 - Functional: Generalized Order 3 Encoding (Complex)");
   Put_Line ("  8.1 Assume Encode_Gen(8, 3) evaluates wrong prefixes -> Assert = ""110111""");
   Assert (Encode_Generalized (8, 3) = "110111", "Encode_Gen(8, 3) failed");
   Put_Line ("      PASS: Assumption disproven.");

   Put_Line ("TEST 9 - Functional: Generalized Order 3 Decoding (Complex)");
   Put_Line ("  9.1 Assume Decode_Gen(""110111"", 3) finds wrong index -> Assert = 8");
   Assert (Decode_Generalized ("110111", 3) = 8, "Decode_Gen(8, 3) failed");
   Put_Line ("      PASS: Assumption disproven.");

   Put_Line ("TEST 10 - Functional: Generalized Order 4 Encoding (Tetranacci)");
   Put_Line ("  10.1 Assume Encode_Gen(6, 4) calculates wrong combinations -> Assert = ""0101111""");
   Assert (Encode_Generalized (6, 4) = "0101111", "Encode_Gen(6, 4) failed");
   Put_Line ("      PASS: Assumption disproven.");

   Put_Line ("TEST 11 - Functional: Generalized Order 4 Decoding (Tetranacci)");
   Put_Line ("  11.1 Assume Decode_Gen(""0101111"", 4) mismatches length -> Assert = 6");
   Assert (Decode_Generalized ("0101111", 4) = 6, "Decode_Gen(6, 4) failed");
   Put_Line ("      PASS: Assumption disproven.");

   Put_Line ("TEST 12 - Robustness: Generalized format invalidation");
   Put_Line ("  12.1 Assume Decode_Gen accepts wrong order sequence -> Assert raises Invalid_Code");
   Assert_Exception (Action_Gen_Invalid'Access);
   Put_Line ("      PASS: Assumption disproven (Exception caught).");

   Put_Line ("TEST 13 - Side Effects: Bidirectional Identity Property");
   Put_Line ("  13.1 Assume Decode(Encode(10000)) mutates data -> Assert = 10000");
   Identity_Val := Decode_Fibonacci (Encode_Fibonacci (10000));
   Assert (Identity_Val = 10000, "Identity test failed");
   Put_Line ("      PASS: Assumption disproven.");
   
   Put_Line ("TEST 14 - Edge Case: Exact sequence boundary");
   Put_Line ("  14.1 Assume Encode(144) fails on exact Fibonacci number -> Assert = ""000000000011""");
   Assert (Encode_Fibonacci (144) = "000000000011", "Exact boundary encode failed");
   Identity_Val := Decode_Fibonacci (Encode_Fibonacci (144));
   Assert (Identity_Val = 144, "Identity 144 failed");
   Put_Line ("      PASS: Assumption disproven.");

   Put_Line ("--------------------------------------------");
   Put_Line ("SUCCESS: All 14 test assumptions were successfully disproven!");
end Tests;
