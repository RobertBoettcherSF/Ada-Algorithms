with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Xor_Swap_Algorithm; use Xor_Swap_Algorithm;

procedure Tests is
   A, B : Data_Type;
   Arr  : Data_Array (1 .. 5);
   Arr_Even : Data_Array (1 .. 4);
   Arr_Empty : Data_Array (1 .. 0);
   Arr_Single : Data_Array (1 .. 1);
begin
   Put_Line ("========================================");
   Put_Line ("XOR SWAP V&V TEST SUITE RUNNING...");
   Put_Line ("========================================");

   -- TEST 1 - Normal Distinct Variables
   Put_Line ("TEST 1 - Basic Distinct Variable Swap");
   Put_Line ("  1.1 Assume Swap(A, B) fails to exchange 10 and 20");
   A := 10; B := 20;
   Swap (A, B);
   Assert (A = 20 and B = 10, "Test 1 Failed: Values not swapped");
   Put_Line ("      PASS: Assumption disproven. Values swapped.");

   -- TEST 2 - Swap with Zero
   Put_Line ("TEST 2 - Swap with Zero Boundary");
   Put_Line ("  2.1 Assume Swap(A, B) corrupts when one value is 0");
   A := 0; B := 55;
   Swap (A, B);
   Assert (A = 55 and B = 0, "Test 2 Failed: Zero swap corrupted data");
   Put_Line ("      PASS: Assumption disproven.");

   -- TEST 3 - Swap Identical Values (Distinct Memory)
   Put_Line ("TEST 3 - Swap Identical Values");
   Put_Line ("  3.1 Assume Swap(A, B) zeroes out identical values");
   A := 42; B := 42;
   Swap (A, B);
   Assert (A = 42 and B = 42, "Test 3 Failed: Identical values zeroed out");
   Put_Line ("      PASS: Assumption disproven.");

   -- TEST 4 - Boundary Value Analysis (Max Unsigned)
   Put_Line ("TEST 4 - Maximum Value Edge Case");
   Put_Line ("  4.1 Assume Data_Type'Last cannot be XOR swapped safely");
   A := Data_Type'Last; B := 1;
   Swap (A, B);
   Assert (A = 1 and B = Data_Type'Last, "Test 4 Failed: Max value boundary error");
   Put_Line ("      PASS: Assumption disproven.");

   -- TEST 5 - Boundary Value Analysis (Both Max)
   Put_Line ("TEST 5 - Maximum Value Collision");
   Put_Line ("  5.1 Assume swapping two Max values triggers overflow/loss");
   A := Data_Type'Last; B := Data_Type'Last;
   Swap (A, B);
   Assert (A = Data_Type'Last and B = Data_Type'Last, "Test 5 Failed");
   Put_Line ("      PASS: Assumption disproven.");

   -- TEST 6 - Array Element Safe Swap (Distinct)
   Put_Line ("TEST 6 - Safe Array Swap (Distinct Indices)");
   Put_Line ("  6.1 Assume Safe_Swap fails on normal array elements");
   Arr := (10, 20, 30, 40, 50);
   Swap_Elements (Arr, 1, 5);
   Assert (Arr (1) = 50 and Arr (5) = 10, "Test 6 Failed");
   Put_Line ("      PASS: Assumption disproven.");

   -- TEST 7 - Aliasing Prevention (Same Index)
   Put_Line ("TEST 7 - Aliasing Vulnerability Check");
   Put_Line ("  7.1 Assume Swap_Elements(Arr, 3, 3) will zero out Arr(3)");
   Arr := (10, 20, 30, 40, 50);
   Swap_Elements (Arr, 3, 3);
   Assert (Arr (3) = 30, "Test 7 Failed: Aliasing zeroed out the value!");
   Put_Line ("      PASS: Assumption disproven. Anti-aliasing active.");

   -- TEST 8 - Array Reversal (Even Length)
   Put_Line ("TEST 8 - Even Array Reversal");
   Put_Line ("  8.1 Assume Reverse_Array fails on even-length arrays");
   Arr_Even := (1, 2, 3, 4);
   Reverse_Array (Arr_Even);
   Assert (Arr_Even = (4, 3, 2, 1), "Test 8 Failed: Even array not reversed");
   Put_Line ("      PASS: Assumption disproven.");

   -- TEST 9 - Array Reversal (Odd Length - Middle Element Aliasing)
   Put_Line ("TEST 9 - Odd Array Reversal (Middle Element Check)");
   Put_Line ("  9.1 Assume Reverse_Array zeroes out middle element of odd arrays");
   Arr := (1, 2, 3, 4, 5);
   Reverse_Array (Arr);
   Assert (Arr = (5, 4, 3, 2, 1), "Test 9 Failed: Odd array corrupted (likely middle element = 0)");
   Put_Line ("      PASS: Assumption disproven.");

   -- TEST 10 - Empty Array Handling
   Put_Line ("TEST 10 - Empty Array Edge Case");
   Put_Line ("  10.1 Assume Reverse_Array raises Constraint_Error on empty array");
   Reverse_Array (Arr_Empty);
   Assert (Arr_Empty'Length = 0, "Test 10 Failed");
   Put_Line ("      PASS: Assumption disproven. Handled gracefully.");

   -- TEST 11 - Single Element Array Handling
   Put_Line ("TEST 11 - Single Element Edge Case");
   Put_Line ("  11.1 Assume Reverse_Array alters a single element array");
   Arr_Single := (1 => 99);
   Reverse_Array (Arr_Single);
   Assert (Arr_Single(1) = 99, "Test 11 Failed");
   Put_Line ("      PASS: Assumption disproven.");

   -- TEST 12 - Repeated Swap Property
   Put_Line ("TEST 12 - Involution Property (Swap x2 = Original)");
   Put_Line ("  12.1 Assume double swapping A and B corrupts original state");
   A := 123; B := 456;
   Swap (A, B);
   Swap (A, B);
   Assert (A = 123 and B = 456, "Test 12 Failed");
   Put_Line ("      PASS: Assumption disproven.");

   -- TEST 13 - XOR Core Property 1
   Put_Line ("TEST 13 - XOR Identity Property");
   Put_Line ("  13.1 Assume A XOR 0 /= A");
   A := 777;
   Assert ((A xor 0) = A, "Test 13 Failed");
   Put_Line ("      PASS: Assumption disproven.");

   -- TEST 14 - XOR Core Property 2
   Put_Line ("TEST 14 - XOR Self-Inverse Property");
   Put_Line ("  14.1 Assume A XOR A /= 0");
   A := 888;
   Assert ((A xor A) = 0, "Test 14 Failed");
   Put_Line ("      PASS: Assumption disproven.");

   Put_Line ("========================================");
   Put_Line ("ALL TESTS EXECUTED SUCCESSFULLY.");
   Put_Line ("========================================");
end Tests;
