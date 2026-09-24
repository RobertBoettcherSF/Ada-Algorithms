with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Interfaces; use Interfaces;
with Hamming_Distance; use Hamming_Distance;

procedure Tests is
   -- Helper strings for slice testing
   Slice_A : constant String := "xxxxkarolinxxxx";
   Slice_B : constant String := "yykathrinyyyyyy";
   
   B_Arr_1 : constant Bit_Array := (True, False, True, True, False);
   B_Arr_2 : constant Bit_Array := (True, False, False, True, True);
begin
   Put_Line ("Initiating V&V Assumption-Disproval Suite for Hamming_Distance...");
   Put_Line ("--------------------------------------------------------------");

   -- TEST 1 - Empty Strings
   Put_Line ("TEST 1 - Edge Case: Empty Strings");
   Put_Line ("  1.1 Assert distance between zero-length strings is 0");
   Assert (Distance ("", "") = 0, "Empty string handling failed");
   Put_Line ("     PASS");

   -- TEST 2 - Identical Strings
   Put_Line ("TEST 2 - Functional: Identical Sequences");
   Put_Line ("  2.1 Assert distance between identical strings is 0");
   Assert (Distance ("ada", "ada") = 0, "Identical strings reported non-zero");
   Put_Line ("     PASS");

   -- TEST 3 - Single Difference
   Put_Line ("TEST 3 - Functional: Single Difference (Boundary)");
   Put_Line ("  3.1 Assert distance between 'car' and 'cat' is 1");
   Assert (Distance ("car", "cat") = 1, "Single difference calculation failed");
   Put_Line ("     PASS");

   -- TEST 4 - Wikipedia Reference Test 1
   Put_Line ("TEST 4 - Functional: Wiki Example 'karolin' vs 'kathrin'");
   Put_Line ("  4.1 Assert distance is 3");
   Assert (Distance ("karolin", "kathrin") = 3, "Wiki reference test 1 failed");
   Put_Line ("     PASS");

   -- TEST 5 - Wikipedia Reference Test 2
   Put_Line ("TEST 5 - Functional: Wiki Example 'karolin' vs 'kerstin'");
   Put_Line ("  5.1 Assert distance is 3");
   Assert (Distance ("karolin", "kerstin") = 3, "Wiki reference test 2 failed");
   Put_Line ("     PASS");

   -- TEST 6 - Wikipedia Reference Test 3 (Numeric Strings)
   Put_Line ("TEST 6 - Functional: Wiki Example '2173896' vs '2233796'");
   Put_Line ("  6.1 Assert distance is 3");
   Assert (Distance ("2173896", "2233796") = 3, "Wiki reference numeric string failed");
   Put_Line ("     PASS");

   -- TEST 7 - Unaligned Index/Bounds Mapping
   Put_Line ("TEST 7 - Robustness: Slice Bounds Independence");
   Put_Line ("  7.1 Assert distances compute safely with unaligned String indices");
   Assert (Distance (Slice_A(5..11), Slice_B(3..9)) = 3, "Slice alignment handling failed");
   Put_Line ("     PASS");

   -- TEST 8 - String Length Mismatch
   Put_Line ("TEST 8 - Error Handling: Unequal String Lengths");
   Put_Line ("  8.1 Assert Length_Mismatch_Error is raised");
   begin
      declare
         Result : Natural := Distance ("short", "verylong");
      begin
         Assert (False, "Expected Length_Mismatch_Error was not raised");
      end;
   exception
      when Length_Mismatch_Error =>
         Put_Line ("     PASS");
   end;

   -- TEST 9 - Bit Array Identical
   Put_Line ("TEST 9 - Functional: Identical Bit Arrays");
   Put_Line ("  9.1 Assert distance is 0");
   Assert (Distance (B_Arr_1, B_Arr_1) = 0, "Identical bit arrays failed");
   Put_Line ("     PASS");

   -- TEST 10 - Bit Array Mismatch
   Put_Line ("TEST 10 - Functional: Bit Array calculation");
   Put_Line ("  10.1 Assert specific distance matches manual count");
   Assert (Distance (B_Arr_1, B_Arr_2) = 2, "Bit array calculation failed");
   Put_Line ("     PASS");

   -- TEST 11 - Bit Array Length Exception
   Put_Line ("TEST 11 - Error Handling: Bit Array Length Mismatch");
   Put_Line ("  11.1 Assert Length_Mismatch_Error on unequal Bit Arrays");
   begin
      declare
         Result : Natural := Distance (B_Arr_1, B_Arr_2(B_Arr_2'First .. B_Arr_2'Last - 1));
      begin
         Assert (False, "Expected Length_Mismatch_Error was not raised");
      end;
   exception
      when Length_Mismatch_Error =>
         Put_Line ("     PASS");
   end;

   -- TEST 12 - Performance/Functional: U64 XOR Identical
   Put_Line ("TEST 12 - Performance/Functional: U64 XOR Identical");
   Put_Line ("  12.1 Assert popcount distance of same integer is 0");
   Assert (Distance (Unsigned_64'(16#FF00#), Unsigned_64'(16#FF00#)) = 0, "U64 identity failed");
   Put_Line ("     PASS");

   -- TEST 13 - Performance/Functional: U64 Binary distance calculation
   Put_Line ("TEST 13 - Performance/Functional: U64 Binary distance calculation");
   Put_Line ("  13.1 Assert distance between binary 1011 (11) and 0011 (3) is 1");
   Assert (Distance (Unsigned_64'(11), Unsigned_64'(3)) = 1, "U64 bitwise calculation failed");
   Put_Line ("     PASS");

   -- TEST 14 - Maximum Theoretical Hamming Distance
   Put_Line ("TEST 14 - Edge Case: Maximum U64 Bit Divergence");
   Put_Line ("  14.1 Assert max possible 64-bit distance equals 64");
   Assert (Distance (Unsigned_64'(0), Unsigned_64'Last) = 64, "U64 boundary counting failed");
   Put_Line ("     PASS");

   -- TEST 15 - Hamming Weight Calculation
   Put_Line ("TEST 15 - Functional: Hamming Weight");
   Put_Line ("  15.1 Assert weight calculates distance from zero-vector (spaces)");
   Assert (Weight ("ada is safe ") = 9, "Weight calculation failed");
   Put_Line ("     PASS");

   Put_Line ("--------------------------------------------------------------");
   Put_Line ("All assumptions disproved: SYSTEM PASSED.");
end Tests;
