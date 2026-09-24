-- tests.adb
-- Test suite for Universal Codes module using V&V principles.
-- Assumes algorithms might fail. PASS disproves failure assumption.

with Ada.Text_IO; use Ada.Text_IO;
with Universal_Codes; use Universal_Codes;

procedure Tests is
   Passed_All : Boolean := True;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Put_Line ("    PASS : " & Message);
      else
         Put_Line ("    FAIL : " & Message);
         Passed_All := False;
      end if;
   end Assert;

begin
   Put_Line ("--- V&V Testing for Universal Codes ---");

   -- TEST 1 - Unary Code Correctness
   Put_Line ("TEST 1 - Unary Code Correctness");
   Assert (Encode_Unary (3) = To_Bits ("110"), "1.1 Encode(3) yields 110");
   Assert (Decode_Unary (To_Bits ("110")) = 3, "1.2 Decode(110) yields 3");
   Assert (Encode_Unary (1) = To_Bits ("0"),   "1.3 Edge Case Encode(1) yields 0");

   -- TEST 2 - Elias Gamma Correctness
   Put_Line ("TEST 2 - Elias Gamma Correctness");
   Assert (Encode_Elias_Gamma (10) = To_Bits ("0001010"), "2.1 Encode(10) yields 0001010");
   Assert (Decode_Elias_Gamma (To_Bits ("0001010")) = 10, "2.2 Decode(0001010) yields 10");
   Assert (Encode_Elias_Gamma (1) = To_Bits ("1"),        "2.3 Edge Case Encode(1) yields 1");

   -- TEST 3 - Elias Delta Correctness
   Put_Line ("TEST 3 - Elias Delta Correctness");
   -- 14 => Bin=1110. L=3 => L+1=4 => Gamma(4)=00100. Remainder="110". Expected: 00100110
   Assert (Encode_Elias_Delta (14) = To_Bits ("00100110"), "3.1 Encode(14) yields 00100110");
   Assert (Decode_Elias_Delta (To_Bits ("00100110")) = 14, "3.2 Decode(00100110) yields 14");
   Assert (Encode_Elias_Delta (1) = To_Bits ("1"),         "3.3 Edge Case Encode(1) yields 1");

   -- TEST 4 - Elias Omega Correctness
   Put_Line ("TEST 4 - Elias Omega Correctness");
   -- 5 => prepend Bin(5)="101", N=2. Prepend Bin(2)="10", N=1. Stop. Append '0'. Expected: 101010
   Assert (Encode_Elias_Omega (5) = To_Bits ("101010"), "4.1 Encode(5) yields 101010");
   Assert (Decode_Elias_Omega (To_Bits ("101010")) = 5, "4.2 Decode(101010) yields 5");

   -- TEST 5 - Fibonacci Code Correctness
   Put_Line ("TEST 5 - Fibonacci Code Correctness");
   -- 14 = 13 (F_6) + 1 (F_1). Code bits at 1 and 6, plus appended 1. Expected: 1000011
   Assert (Encode_Fibonacci (14) = To_Bits ("1000011"), "5.1 Encode(14) yields 1000011");
   Assert (Decode_Fibonacci (To_Bits ("1000011")) = 14, "5.2 Decode(1000011) yields 14");

   -- TEST 6 - Robustness and Exception Handling (Disproving lack of safety)
   Put_Line ("TEST 6 - Robustness and Exceptions");
   begin
      declare
         Result : Positive := Decode_Unary (To_Bits ("111"));
      begin
         Assert (False, "6.1 Unary missing zero failed to raise exception");
      end;
   exception
      when Decoding_Error =>
         Assert (True, "6.1 Unary missing zero raised Decoding_Error");
   end;

   begin
      declare
         Result : Positive := Decode_Elias_Gamma (To_Bits ("00"));
      begin
         Assert (False, "6.2 Truncated Gamma failed to raise exception");
      end;
   exception
      when Decoding_Error =>
         Assert (True, "6.2 Truncated Gamma raised Decoding_Error");
   end;

   begin
      declare
         Result : Positive := Decode_Fibonacci (To_Bits ("10101"));
      begin
         Assert (False, "6.3 Fibonacci missing termination failed to raise exception");
      end;
   exception
      when Decoding_Error =>
         Assert (True, "6.3 Fibonacci missing termination raised Decoding_Error");
   end;

   New_Line;
   if Passed_All then
      Put_Line ("SUCCESS: All tests passed. The assumption of failure has been rigorously disproven.");
   else
      Put_Line ("FAILURE: One or more V&V tests failed.");
   end if;
end Tests;
