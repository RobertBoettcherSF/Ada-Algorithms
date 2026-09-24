-- tests.adb
-- Standalone V&V testing suite for Subset Sum algorithms.
pragma Assertion_Policy (Assert => Check);

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Subset_Sum; use Subset_Sum;

procedure Tests is
begin
   Put_Line ("=================================================");
   Put_Line ("Starting V&V Subset Sum Test Suite");
   Put_Line ("Assuming code is incorrect. Tests PASS when proven false.");
   Put_Line ("=================================================");

   -- TEST 1
   Put_Line ("TEST 1 - Recursive Functional (Positive)");
   Put_Line ("  1.1 Assume code misses obvious valid subset (3+4+2=9)");
   Assert (Recursive_Subset_Sum ((3, 34, 4, 12, 5, 2), 9), "Should find sum 9");
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Recursive Functional (Negative)");
   Put_Line ("  2.1 Assume code hallucinates an invalid subset (30)");
   Assert (not Recursive_Subset_Sum ((3, 34, 4, 12, 5, 2), 30), "Should not find sum 30");
   Put_Line ("      PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Recursive Edge Case (Empty Set)");
   Put_Line ("  3.1 Assume empty set fails mathematically correct base case for Target 0");
   Assert (Recursive_Subset_Sum ((1 .. 0 => 0), 0), "Empty set achieves sum 0");
   Put_Line ("      PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Recursive Edge Case (Empty Set, Non-Zero Target)");
   Put_Line ("  4.1 Assume empty set erroneously matches non-zero targets");
   Assert (not Recursive_Subset_Sum ((1 .. 0 => 0), 5), "Empty set cannot achieve > 0");
   Put_Line ("      PASS");

   -- TEST 5
   Put_Line ("TEST 5 - DP Functional (Positive)");
   Put_Line ("  5.1 Assume DP table fails to propagate overlapping sums");
   Assert (DP_Subset_Sum ((1, 2, 3, 4, 5), 15), "Should find sum 15 (all elements)");
   Put_Line ("      PASS");

   -- TEST 6
   Put_Line ("TEST 6 - DP Functional (Negative)");
   Put_Line ("  6.1 Assume DP table generates false positives for parity violations");
   Assert (not DP_Subset_Sum ((2, 4, 6, 8), 11), "Even numbers cannot sum to odd target");
   Put_Line ("      PASS");

   -- TEST 7
   Put_Line ("TEST 7 - DP Robustness (Negative Inputs)");
   Put_Line ("  7.1 Assume DP accepts invalid negative elements without raising Constraint_Error");
   begin
      declare
         B : Boolean := DP_Subset_Sum ((1, -2, 3), 2);
      begin
         Assert (False, "Should have raised Constraint_Error");
      end;
   exception
      when Constraint_Error => Put_Line ("      PASS");
   end;

   -- TEST 8
   Put_Line ("TEST 8 - DP Edge Case (Target 0)");
   Put_Line ("  8.1 Assume DP fails to validate the subset for 0 Target");
   Assert (DP_Subset_Sum ((5, 10, 15), 0), "DP should always achieve 0 target");
   Put_Line ("      PASS");

   -- TEST 9
   Put_Line ("TEST 9 - Meet-In-The-Middle Functional (Positive)");
   Put_Line ("  9.1 Assume MITM loses subsets during array split & merge operations");
   Assert (Meet_In_The_Middle_Subset_Sum ((1, 3, 5, 2, 8, 4), 10), "Should find 5+3+2 = 10");
   Put_Line ("      PASS");

   -- TEST 10
   Put_Line ("TEST 10 - Meet-In-The-Middle Robustness (Negative Operands)");
   Put_Line ("  10.1 Assume MITM fails with negative elements / target boundaries");
   Assert (Meet_In_The_Middle_Subset_Sum ((10, -5, 20, -10), -15), "Should find -5 + -10 = -15");
   Put_Line ("      PASS");

   -- TEST 11
   Put_Line ("TEST 11 - Meet-In-The-Middle Singleton Array");
   Put_Line ("  11.1 Assume MITM split logic crashes when N=1");
   Assert (Meet_In_The_Middle_Subset_Sum ((1 => 7), 7), "Should find 7 in single-element set");
   Put_Line ("      PASS");

   -- TEST 12
   Put_Line ("TEST 12 - Approximation Scheme Functional (Exact Threshold)");
   Put_Line ("  12.1 Assume FPTAS misses exact sum when Delta bound allows it");
   Assert (Approximate_Subset_Sum ((10, 20, 30), 60, 0.1) = 60, "FPTAS should find exact sum 60");
   Put_Line ("      PASS");

   -- TEST 13
   Put_Line ("TEST 13 - Approximation Scheme Functional (Trimmed Boundary)");
   Put_Line ("  13.1 Assume FPTAS fails to return bounded mathematical maximum when trimmed");
   -- For Set (40, 50, 60) and Target 100, the maximum valid sum <= 100 is 90 (40+50)
   Assert (Approximate_Subset_Sum ((40, 50, 60), 100, 0.5) = 90, "FPTAS should find 90");
   Put_Line ("      PASS");

   -- TEST 14
   Put_Line ("TEST 14 - Approximation Scheme Edge Case (All Oversized)");
   Put_Line ("  14.1 Assume FPTAS erroneously returns elements > Target");
   Assert (Approximate_Subset_Sum ((50, 60), 40, 0.1) = 0, "Should return 0, none <= 40");
   Put_Line ("      PASS");

   Put_Line ("=================================================");
   Put_Line ("SUCCESS: All 14 tests completed and passed.");
end Tests;
