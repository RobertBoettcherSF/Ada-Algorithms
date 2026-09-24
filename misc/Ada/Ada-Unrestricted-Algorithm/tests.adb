-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Unrestricted_Algorithms; use Unrestricted_Algorithms;

procedure Tests is
   Result : Digit_Array(1..5);
begin
   Put_Line("Running Validation & Verification Tests...");

   -- TEST 1 - Equality Helper
   Put_Line("TEST 1 - Array Equality Functionality");
   Put_Line("  1.1 Assert identical arrays are equal");
   Assert (Is_Equal((1=>1, 2=>2), (1=>1, 2=>2)), "Equality failed");
   Put_Line("      PASS");
   Put_Line("  1.2 Assert different arrays are not equal");
   Assert (not Is_Equal((1=>1, 2=>2), (1=>1, 2=>3)), "Inequality failed");
   Put_Line("      PASS");

   -- TEST 2 - Zero Validation
   Put_Line("TEST 2 - Zero Check Mechanism");
   Put_Line("  2.1 Assert fully zeroed array passes");
   Assert (Is_Zero((1=>0, 2=>0, 3=>0)), "Zero check failed");
   Put_Line("      PASS");
   Put_Line("  2.2 Assert single non-zero fails the check");
   Assert (not Is_Zero((1=>0, 2=>0, 3=>1)), "Non-zero check failed");
   Put_Line("      PASS");

   -- TEST 3 - Iterative Inverse Exact Case
   Put_Line("TEST 3 - Inverse_Iterative (1/2)");
   Result := Inverse_Iterative(2, 4);
   Put_Line("  3.1 Assert whole number is 0");
   Assert (Result(1) = 0, "Whole part error");
   Put_Line("      PASS");
   Put_Line("  3.2 Assert first decimal is 5");
   Assert (Result(2) = 5, "First decimal error");
   Put_Line("      PASS");

   -- TEST 4 - Iterative Inverse Repeating Decimal
   Put_Line("TEST 4 - Inverse_Iterative (1/3)");
   Result := Inverse_Iterative(3, 4);
   Put_Line("  4.1 Assert first decimal is 3");
   Assert (Result(2) = 3, "Failed 1/3 dec 1");
   Put_Line("      PASS");
   Put_Line("  4.2 Assert second decimal is 3");
   Assert (Result(3) = 3, "Failed 1/3 dec 2");
   Put_Line("      PASS");

   -- TEST 5 - Recursive Inverse Logic
   Put_Line("TEST 5 - Inverse_Recursive (1/4)");
   Result := Inverse_Recursive(4, 4);
   Put_Line("  5.1 Assert first decimal is 2");
   Assert (Result(2) = 2, "Recursive inverse failed on dec 1");
   Put_Line("      PASS");
   Put_Line("  5.2 Assert second decimal is 5");
   Assert (Result(3) = 5, "Recursive inverse failed on dec 2");
   Put_Line("      PASS");

   -- TEST 6 - Standard Division
   Put_Line("TEST 6 - Divide_By_Integer (Exact)");
   declare
      Num : Digit_Array(1..3) := (1=>2, 2=>0, 3=>0); -- 2.00
      Div : Digit_Array := Divide_By_Integer(Num, 4);
   begin
      Put_Line("  6.1 Assert 2.00 / 4 = 0.50");
      Assert (Div(1) = 0 and Div(2) = 5 and Div(3) = 0, "Div Array failed");
      Put_Line("      PASS");
   end;

   -- TEST 7 - Division Resulting in Remainder Carry
   Put_Line("TEST 7 - Divide_By_Integer (Carried)");
   declare
      Num : Digit_Array(1..3) := (1=>1, 2=>0, 3=>0); -- 1.00
      Div : Digit_Array := Divide_By_Integer(Num, 8); -- 0.12(5 dropped)
   begin
      Put_Line("  7.1 Assert 1.00 / 8 = 0.12 (Precision bound)");
      Assert (Div(1) = 0 and Div(2) = 1 and Div(3) = 2, "Carry Div failed");
      Put_Line("      PASS");
   end;

   -- TEST 8 - Addition (No Carry)
   Put_Line("TEST 8 - Array Addition (No Carry)");
   declare
      A : Digit_Array(1..3) := (1=>1, 2=>2, 3=>3);
      B : Digit_Array(1..3) := (1=>2, 2=>3, 3=>4); 
      S : Digit_Array := Add(A, B);
   begin
      Put_Line("  8.1 Assert 1.23 + 2.34 = 3.57");
      Assert (S(1) = 3 and S(2) = 5 and S(3) = 7, "Add failed");
      Put_Line("      PASS");
   end;

   -- TEST 9 - Addition (With Carry)
   Put_Line("TEST 9 - Array Addition (With Carry)");
   declare
      A : Digit_Array(1..3) := (1=>1, 2=>8, 3=>8);
      B : Digit_Array(1..3) := (1=>0, 2=>2, 3=>4);
      S : Digit_Array := Add(A, B);
   begin
      Put_Line("  9.1 Assert 1.88 + 0.24 = 2.12");
      Assert (S(1) = 2 and S(2) = 1 and S(3) = 2, "Add carry failed");
      Put_Line("      PASS");
   end;

   -- TEST 10 - Unrestricted 'e' Calculation Base
   Put_Line("TEST 10 - Compute_E (Low Precision Bounds)");
   declare
      E : Digit_Array := Compute_E(3);
   begin
      Put_Line("  10.1 Assert whole number is 2");
      Assert (E(1) = 2, "E whole failed");
      Put_Line("      PASS");
      Put_Line("  10.2 Assert decimals are 7,1,8");
      Assert (E(2) = 7 and E(3) = 1 and E(4) = 8, "E decimal failed");
      Put_Line("      PASS");
   end;

   -- TEST 11 - Exception Handling (Precision Mismatches)
   Put_Line("TEST 11 - Precision Boundary Violations");
   Put_Line("  11.1 Assert addition of differing array bounds throws exception");
   begin
      declare
         A : Digit_Array(1..2) := (1, 2);
         B : Digit_Array(1..3) := (1, 2, 3);
         C : Digit_Array := Add(A, B);
      begin
         Assert (False, "Expected Precision_Mismatch_Error");
      end;
   exception
      when Precision_Mismatch_Error | Constraint_Error => 
         Put_Line("      PASS");
   end;

   -- TEST 12 - Negative Edge Input Checking
   Put_Line("TEST 12 - Strong Typing Bounds Validation");
   Put_Line("  12.1 Assert compiler type constraint prevents 0 precision (Natural vs Positive)");
   begin
      declare
         pragma Warnings (Off);
         Result : Digit_Array := Compute_E(0);
         pragma Warnings (On);
      begin
         Assert (False, "Should not be able to execute with 0 precision natively");
      end;
   exception
      when Constraint_Error =>
         Put_Line("      PASS");
   end;

   -- TEST 13 - Deep Precision E computation
   Put_Line("TEST 13 - Compute_E (Deep Precision)");
   declare
      E : Digit_Array := Compute_E(10);
   begin
      Put_Line("  13.1 Assert 10th decimal space computation aligns mathematically");
      -- FIXED: The transcription of the actual decimals of `e` was inaccurate in the 
      -- initial test file. e = 2.7182818284... (Decimals 5 through 9 correspond to Indices 6..10)
      Assert (E(6) = 8 and E(7) = 1 and E(8) = 8 and E(9) = 2 and E(10) = 8, "Deep e failed");
      Put_Line("      PASS");
   end;

end Tests;
