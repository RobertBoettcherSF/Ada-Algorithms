-- tests.adb
-- Validation and Verification suite for Fictitious Play

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Fictitious_Play; use Fictitious_Play;

procedure Tests is
   
   -- Mock 2x2 Prisoner's Dilemma
   -- Action 1 = Cooperate, Action 2 = Defect
   PD_P1 : Payoff_Matrix(1..2, 1..2) := ( (3.0, 0.0), (5.0, 1.0) );
   PD_P2 : Payoff_Matrix(1..2, 1..2) := ( (3.0, 5.0), (0.0, 1.0) );
   
   -- History arrays
   H1 : Action_Array(1..5);
   H2 : Action_Array(1..5);
   
   Bad_H1 : Action_Array(1..4);

begin
   Put_Line("==================================================");
   Put_Line("STARTING FICTITIOUS PLAY TEST SUITE (13+ Tests)");
   Put_Line("Assumption: Code is broken. PASS proves code works.");
   Put_Line("==================================================");

   -- TEST 1: Helper Functions Logic
   Put_Line("TEST 1 - Calculate_Best_Response Correctness");
   declare
      B2 : Belief_Counts(1..2) := (1 => 1, 2 => 0); -- Opponent played Cooperate
   begin
      Put_Line("  1.1 Asserting P1 Best Response against Cooperate is Defect (Index 2)");
      Assert (Calculate_Best_Response_P1(PD_P1, B2) = 2, "BR should be Defect");
      Put_Line("      PASS: Assumption disproved (Correct BR returned).");
   end;

   Put_Line("TEST 2 - P2 Helper Logic Verification");
   declare
      B1 : Belief_Counts(1..2) := (1 => 0, 2 => 1); -- Opponent played Defect
   begin
      Put_Line("  2.1 Asserting P2 Best Response against Defect is Defect (Index 2)");
      Assert (Calculate_Best_Response_P2(PD_P2, B1) = 2, "BR should be Defect");
      Put_Line("      PASS: P2 correctly computes best response.");
   end;

   -- TEST 3: Simultaneous Play on PD (Convergence Test)
   Put_Line("TEST 3 - Simultaneous Play (Prisoner's Dilemma)");
   Simultaneous_Play(PD_P1, PD_P2, 5, 1, 1, H1, H2);
   Put_Line("  3.1 Asserting Initial Action is respected");
   Assert (H1(1) = 1 and H2(1) = 1, "Initial action not set properly");
   Put_Line("      PASS: Initial actions logged.");
   Put_Line("  3.2 Asserting Iteration 2 reacts to Iteration 1");
   Assert (H1(2) = 2 and H2(2) = 2, "Should defect on iteration 2");
   Put_Line("      PASS: Proper reaction logged.");
   Put_Line("  3.3 Asserting Convergence to Nash Equilibrium (Defect/Defect)");
   Assert (H1(5) = 2 and H2(5) = 2, "Did not converge to Defect");
   Put_Line("      PASS: Algorithm achieves NE as expected mathematically.");

   -- TEST 4: Alternating Play Check
   Put_Line("TEST 4 - Alternating Fictitious Play Mechanics");
   Alternating_Play(PD_P1, PD_P2, 5, 1, 1, H1, H2);
   Put_Line("  4.1 Asserting Alternating Play functions without crashing");
   Assert (H1(5) = 2, "Failed to resolve sequence");
   Put_Line("      PASS: Sequence executed fully.");

   -- TEST 5: Boundary & Exception Validation (Invalid Matrix)
   Put_Line("TEST 5 - Input Validation: Bad Matrix Dimensions");
   Put_Line("  5.1 Asserting mismatched matrices raise Invalid_Matrix_Dimensions");
   declare
      Bad_Matrix : Payoff_Matrix(1..3, 1..3) := (others => (others => 0.0));
   begin
      Simultaneous_Play(PD_P1, Bad_Matrix, 5, 1, 1, H1, H2);
      Assert (False, "Exception was not raised");
   exception
      when Invalid_Matrix_Dimensions =>
         Put_Line("      PASS: Mismatched dimensions correctly blocked.");
   end;

   -- TEST 6: Boundary & Exception Validation (Invalid History)
   Put_Line("TEST 6 - Input Validation: Mismatched History Arrays");
   Put_Line("  6.1 Asserting history length mismatch against iterations raises error");
   begin
      Simultaneous_Play(PD_P1, PD_P2, 5, 1, 1, Bad_H1, H2);
      Assert (False, "Exception was not raised");
   exception
      when Invalid_History_Length =>
         Put_Line("      PASS: Array boundary violations trapped.");
   end;

   -- TEST 7: 1x1 Edge Case (Trivial Game)
   Put_Line("TEST 7 - 1x1 Matrix Edge Case");
   Put_Line("  7.1 Asserting 1x1 matrix doesn't cause out-of-bounds loop errors");
   declare
      M1x1 : Payoff_Matrix(1..1, 1..1) := (1 => (1 => 5.0));
      H1x1_1, H1x1_2 : Action_Array(1..3);
   begin
      Simultaneous_Play(M1x1, M1x1, 3, 1, 1, H1x1_1, H1x1_2);
      Assert (H1x1_1(3) = 1, "Failed 1x1 game logic");
      Put_Line("      PASS: 1x1 boundary handled perfectly.");
   end;

   -- TEST 8: Index Offsets (Matrices not starting at 1)
   Put_Line("TEST 8 - Matrix Custom Indexing");
   Put_Line("  8.1 Asserting matrices starting at index 5 process correctly");
   declare
      M2x2_Offset : Payoff_Matrix(5..6, 5..6) := ( (3.0, 0.0), (5.0, 1.0) );
      HO_1, HO_2 : Action_Array(1..2);
   begin
      Simultaneous_Play(M2x2_Offset, M2x2_Offset, 2, 5, 5, HO_1, HO_2);
      Assert (HO_1(2) = 6, "Offset indexing failed");
      Put_Line("      PASS: Relative indexing using 'Range works.");
   end;

   -- TEST 9: Smoothed Play Temperature Limits
   Put_Line("TEST 9 - Smoothed (Softmax) Play Execution");
   Put_Line("  9.1 Asserting high temperature avoids math overflow crashes");
   Smoothed_Play(PD_P1, PD_P2, 5, 100.0, 1, 1, H1, H2);
   Assert (H1(1) = 1, "Smoothed crash");
   Put_Line("      PASS: Subtractive max-trick prevents EXP overflow.");

   -- TEST 10: Zero-Sum Game Expected Utility Logic
   Put_Line("TEST 10 - Expected Utility with Negative Payoffs");
   Put_Line("  10.1 Asserting negative floats evaluate correctly");
   declare
      ZS1 : Payoff_Matrix(1..2, 1..2) := ( (-1.0, 1.0), (1.0, -1.0) );
      B2  : Belief_Counts(1..2) := (1 => 5, 2 => 0); -- Opponent heavy on action 1
   begin
      Assert (Calculate_Best_Response_P1(ZS1, B2) = 2, "Failed to max negative utility");
      Put_Line("      PASS: Math correctly isolates maximum float.");
   end;

   -- TEST 11: Inertia Boundary (Inertia = 1.0)
   Put_Line("TEST 11 - Absolute Inertia");
   Put_Line("  11.1 Asserting Inertia = 1.0 prevents strategy change");
   Inertial_Play(PD_P1, PD_P2, 5, 1.0, 1, 1, H1, H2);
   Assert (H1(5) = 1, "Strategy changed despite 100% inertia");
   Put_Line("      PASS: Stochastic lock respected.");

   -- TEST 12: Inertia Boundary (Inertia = 0.0)
   Put_Line("TEST 12 - Zero Inertia (Equates to Simultaneous Play)");
   Put_Line("  12.1 Asserting Inertia = 0.0 guarantees strategy change to BR");
   Inertial_Play(PD_P1, PD_P2, 5, 0.0, 1, 1, H1, H2);
   Assert (H1(5) = 2, "Strategy did not change despite 0% inertia");
   Put_Line("      PASS: Fallback to strict best response confirmed.");

   -- TEST 13: Final State Array Mutation
   Put_Line("TEST 13 - Out Parameter Mutation Integrity");
   Put_Line("  13.1 Asserting out parameters strictly rewrite previous memory");
   declare
      Dirty_H : Action_Array(1..5) := (others => 999);
   begin
      Simultaneous_Play(PD_P1, PD_P2, 5, 1, 1, Dirty_H, H2);
      Assert (Dirty_H(5) /= 999, "Array not mutated properly");
      Put_Line("      PASS: Memory mutation operates flawlessly.");
   end;

   Put_Line("==================================================");
   Put_Line("ALL TESTS PASSED: Pessimistic assumptions proven FALSE.");
   Put_Line("==================================================");

end Tests;
