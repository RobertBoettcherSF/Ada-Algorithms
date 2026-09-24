-- tests.adb
-- Verification and Validation Test Suite for Tarski-Kuratowski Algorithm
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Tarski_Kuratowski; use Tarski_Kuratowski;

procedure Tests is
   Result : Complexity_Bound;

   -- Helper variables for defining prefixes
   E0 : constant Quantifier := (Existential, First_Order);
   A0 : constant Quantifier := (Universal, First_Order);
   E1 : constant Quantifier := (Existential, Second_Order);
   A1 : constant Quantifier := (Universal, Second_Order);

   Empty_Prefix : constant Quantifier_Prefix(1 .. 0) := (others => E0);
begin
   Put_Line ("=================================================");
   Put_Line ("TARSKI-KURATOWSKI V&V TEST SUITE");
   Put_Line ("=================================================");

   -- FUNCTIONAL CORRECTNESS: Arithmetical Hierarchy
   Put_Line ("TEST 1 - Empty Prefix (Arithmetical)");
   Put_Line ("  1.1 Assert algorithm safely handles empty arrays and returns Delta^0_0");
   Result := Evaluate_Arithmetical (Empty_Prefix);
   Assert (Result.Class = Class_Delta and Result.Level = 0 and Result.V_Order = First_Order, "Failed Empty Arithmetical");
   Put_Line ("     PASS");

   Put_Line ("TEST 2 - Single Existential (Arithmetical)");
   Put_Line ("  1.2 Assert 'Exists' returns Sigma^0_1");
   Result := Evaluate_Arithmetical ((1 => E0));
   Assert (Result.Class = Class_Sigma and Result.Level = 1, "Failed Single E0");
   Put_Line ("     PASS");

   Put_Line ("TEST 3 - Single Universal (Arithmetical)");
   Put_Line ("  1.3 Assert 'For_All' returns Pi^0_1");
   Result := Evaluate_Arithmetical ((1 => A0));
   Assert (Result.Class = Class_Pi and Result.Level = 1, "Failed Single A0");
   Put_Line ("     PASS");

   Put_Line ("TEST 4 - One Alternation: Exists -> For_All");
   Put_Line ("  1.4 Assert 'Exists, For_All' computes to Sigma^0_2");
   Result := Evaluate_Arithmetical ((1 => E0, 2 => A0));
   Assert (Result.Class = Class_Sigma and Result.Level = 2, "Failed E0->A0");
   Put_Line ("     PASS");

   Put_Line ("TEST 5 - Double Alternation: For_All -> Exists -> For_All");
   Put_Line ("  1.5 Assert 3-block sequence computes to Pi^0_3");
   Result := Evaluate_Arithmetical ((1 => A0, 2 => E0, 3 => A0));
   Assert (Result.Class = Class_Pi and Result.Level = 3, "Failed A0->E0->A0");
   Put_Line ("     PASS");

   Put_Line ("TEST 6 - Quantifier Block Collapse");
   Put_Line ("  1.6 Assert 'Exists, Exists' collapses to Sigma^0_1 (not 2)");
   Result := Evaluate_Arithmetical ((1 => E0, 2 => E0));
   Assert (Result.Class = Class_Sigma and Result.Level = 1, "Failed Block Collapse E0,E0");
   Put_Line ("     PASS");

   -- ERROR HANDLING & BOUNDARIES
   Put_Line ("TEST 7 - Invalid Hierarchy Exception Handling");
   Put_Line ("  2.1 Assert Second_Order in Arithmetical raises Invalid_Hierarchy_Prefix");
   begin
      Result := Evaluate_Arithmetical ((1 => E1));
      Assert (False, "Expected Invalid_Hierarchy_Prefix not raised");
   exception
      when Invalid_Hierarchy_Prefix =>
         Put_Line ("     PASS");
   end;

   Put_Line ("TEST 8 - Complex Block Collapsing");
   Put_Line ("  2.2 Assert 'A0, A0, E0, E0, E0, A0' computes to Pi^0_3");
   Result := Evaluate_Arithmetical ((1 => A0, 2 => A0, 3 => E0, 4 => E0, 5 => E0, 6 => A0));
   Assert (Result.Class = Class_Pi and Result.Level = 3, "Failed Complex Collapse");
   Put_Line ("     PASS");

   -- FUNCTIONAL CORRECTNESS: Analytical Hierarchy
   Put_Line ("TEST 9 - Single Second_Order Existential");
   Put_Line ("  3.1 Assert 'Exists^1' returns Sigma^1_1");
   Result := Evaluate_Analytical ((1 => E1));
   Assert (Result.Class = Class_Sigma and Result.Level = 1 and Result.V_Order = Second_Order, "Failed E1");
   Put_Line ("     PASS");

   Put_Line ("TEST 10 - Analytical Absorption of First_Order");
   Put_Line ("  3.2 Assert 'E1, A0, E0' ignores A0/E0 and returns Sigma^1_1");
   Result := Evaluate_Analytical ((1 => E1, 2 => A0, 3 => E0));
   Assert (Result.Class = Class_Sigma and Result.Level = 1, "Failed First_Order Absorption");
   Put_Line ("     PASS");

   Put_Line ("TEST 11 - Analytical Alternations");
   Put_Line ("  3.3 Assert 'A1, E1, A1' returns Pi^1_3");
   Result := Evaluate_Analytical ((1 => A1, 2 => E1, 3 => A1));
   Assert (Result.Class = Class_Pi and Result.Level = 3, "Failed A1->E1->A1");
   Put_Line ("     PASS");

   Put_Line ("TEST 12 - Mixed Hierarchy Alternations");
   Put_Line ("  3.4 Assert 'E0, A1, E1' skips E0 and computes based on A1->E1 (Pi^1_2)");
   Result := Evaluate_Analytical ((1 => E0, 2 => A1, 3 => E1));
   Assert (Result.Class = Class_Pi and Result.Level = 2, "Failed Mixed Alternation");
   Put_Line ("     PASS");

   -- FUNCTIONAL CORRECTNESS: Dynamic Resolver
   Put_Line ("TEST 13 - Dynamic Resolver (Pure Arithmetical)");
   Put_Line ("  4.1 Assert Get_Upper_Bound routes pure Type 0 to Arithmetical");
   Result := Get_Upper_Bound ((1 => A0, 2 => E0));
   Assert (Result.Level = 2 and Result.V_Order = First_Order, "Failed Dynamic Type 0");
   Put_Line ("     PASS");

   Put_Line ("TEST 14 - Dynamic Resolver (Mixed)");
   Put_Line ("  4.2 Assert Get_Upper_Bound routes mixed Type 0/1 to Analytical");
   Result := Get_Upper_Bound ((1 => E0, 2 => E1));
   Assert (Result.V_Order = Second_Order, "Failed Dynamic Type 1");
   Put_Line ("     PASS");

   Put_Line ("TEST 15 - Analytical Empty/Pure Type 0 Fallback");
   Put_Line ("  4.3 Assert pure Type 0 sent to Analytical evaluates as Delta^1_1");
   Result := Evaluate_Analytical ((1 => E0, 2 => A0));
   Assert (Result.Class = Class_Delta and Result.Level = 1 and Result.V_Order = Second_Order, "Failed Type 0 in Type 1 bounds");
   Put_Line ("     PASS");

   Put_Line ("=================================================");
   Put_Line ("ALL 15 TESTS COMPLETED SUCCESSFULLY");
   Put_Line ("=================================================");
end Tests;
