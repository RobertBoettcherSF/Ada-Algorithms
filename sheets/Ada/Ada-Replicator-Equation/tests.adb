-- tests.adb
-- Standalone test suite with 13+ tests to verify and validate the Replicator Equation code.
-- The tests challenge assumptions of broken code, and PASS when the codebase works.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Replicator_Equation; use Replicator_Equation;

procedure Tests is

   -- Helper variables for testing
   Pop_2   : Population_Vector(1..2) := (0.4, 0.6);
   Pop_2_U : Population_Vector(1..2) := (0.5, 0.5); 
   Pop_3   : Population_Vector(1..3) := (0.2, 0.3, 0.5);

   -- Classic Hawk-Dove Payoff Matrix
   Payoff_HD : Payoff_Matrix(1..2, 1..2) := 
     (( -1.0, 2.0 ),
      (  0.0, 1.0 ));
      
   Payoff_Uniform : Payoff_Matrix(1..2, 1..2) := 
     (( 1.0, 1.0 ),
      ( 1.0, 1.0 ));

   -- Mutation Matrix (Identity = No mutation)
   Mut_Identity : Payoff_Matrix(1..2, 1..2) := 
     (( 1.0, 0.0 ),
      ( 0.0, 1.0 ));

   Result_Pop : Population_Vector(1..2);
   Fitness    : Population_Vector(1..2);
   Avg_Fit    : Float;

   Epsilon : constant Float := 0.0001;

   -- Custom assert to avoid immediate program crash and allow printing PASS format
   procedure Verify(Condition : Boolean; Msg : String) is
   begin
      if Condition then
         Put_Line("      PASS");
      else
         Put_Line("      FAIL: " & Msg);
         raise Assertion_Error with Msg;
      end if;
   end Verify;

begin
   Put_Line("==================================================");
   Put_Line("  STARTING V&V TEST SUITE: REPLICATOR EQUATION");
   Put_Line("==================================================");

   Put_Line("TEST 1 - Vector Normalization (Correctness)");
   Put_Line("  1.1 Assert unnormalized vector is correctly scaled to 1.0 sum");
   declare
      Unnorm : Population_Vector(1..2) := (1.0, 3.0);
      Normed : Population_Vector := Normalize(Unnorm);
   begin
      Verify (abs(Normed(1) - 0.25) < Epsilon and abs(Normed(2) - 0.75) < Epsilon, "Normalization incorrect");
   end;

   Put_Line("TEST 2 - Fitness Calculation (Functional)");
   Put_Line("  2.1 Assert linear fitness matches matrix multiplication expectations");
   Fitness := Calculate_Fitness(Pop_2, Payoff_HD);
   Verify (abs(Fitness(1) - 0.8) < Epsilon and abs(Fitness(2) - 0.6) < Epsilon, "Fitness incorrect");

   Put_Line("TEST 3 - Average Fitness Calculation (Functional)");
   Put_Line("  3.1 Assert phi(x) matches expected dot product");
   Avg_Fit := Average_Fitness(Pop_2, Fitness);
   Verify (abs(Avg_Fit - 0.68) < Epsilon, "Average fitness incorrect");

   Put_Line("TEST 4 - Discrete Step Dynamics (Correctness)");
   Put_Line("  4.1 Assert discrete step drives population in mathematically correct direction");
   Result_Pop := Step_Discrete(Pop_2, Payoff_HD);
   -- Expected logic: Hawk fitness (0.8) > Dove fitness (0.6). Hawk should increase from 0.4.
   Verify (Result_Pop(1) > 0.4, "Discrete step did not favor higher fitness");

   Put_Line("TEST 5 - Continuous Step Dynamics (Euler Integrity)");
   Put_Line("  5.1 Assert continuous step updates according to derivative");
   Result_Pop := Step_Continuous(Pop_2, Payoff_HD, 0.1);
   -- dx1/dt = 0.4 * (0.8 - 0.68) = 0.4 * 0.12 = 0.048. New pop = 0.4 + 0.1*(0.048) = 0.4048
   Verify (abs(Result_Pop(1) - 0.4048) < Epsilon, "Continuous step derivative calculation failed");

   Put_Line("TEST 6 - Extinction Preservation (Edge Case)");
   Put_Line("  6.1 Assert an extinct species (0.0) cannot respawn through standard replication");
   declare
      Pop_Extinct : Population_Vector(1..2) := (0.0, 1.0);
      Res_Extinct : Population_Vector := Step_Discrete(Pop_Extinct, Payoff_HD);
   begin
      Verify (abs(Res_Extinct(1) - 0.0) < Epsilon, "Extinct species respawned organically");
   end;

   Put_Line("TEST 7 - Uniform Equilibrium (Edge Case)");
   Put_Line("  7.1 Assert uniform payoff matrix preserves current population ratios");
   Result_Pop := Step_Discrete(Pop_2, Payoff_Uniform);
   Verify (abs(Result_Pop(1) - Pop_2(1)) < Epsilon, "Uniform payoff altered ratios");

   Put_Line("TEST 8 - Mutator Equation Identity (Correctness)");
   Put_Line("  8.1 Assert mutator equation with identity matrix matches standard continuous");
   declare
      Res_Standard : Population_Vector := Step_Continuous(Pop_2, Payoff_HD, 0.1);
      Res_Mutator  : Population_Vector := Step_Mutator_Continuous(Pop_2, Payoff_HD, Mut_Identity, 0.1);
   begin
      Verify (abs(Res_Standard(1) - Res_Mutator(1)) < Epsilon, "Identity mutator diverged from standard");
   end;

   Put_Line("TEST 9 - Exception Handling: Dimension Mismatch on Fitness (Robustness)");
   Put_Line("  9.1 Assert mismatch between population and payoff matrix raises Dimension_Mismatch");
   begin
      declare
         Bad_Fit : Population_Vector := Calculate_Fitness(Pop_3, Payoff_HD);
      begin
         Verify (False, "Expected Dimension_Mismatch not raised");
      end;
   exception
      when Dimension_Mismatch =>
         Verify (True, "Passed Exception");
   end;

   Put_Line("TEST 10 - Exception Handling: Dimension Mismatch on Asymmetric (Robustness)");
   Put_Line("  10.1 Assert invalid dimensions between two asymmetric populations raises exception");
   begin
      declare
         P_A : Population_Vector(1..2) := (0.5, 0.5);
         P_B : Population_Vector(1..3) := (0.3, 0.3, 0.4);
      begin
         -- Payoff_HD is 2x2, but B is size 3. Should fail.
         Step_Asymmetric_Discrete(P_A, P_B, Payoff_HD, Payoff_HD);
         Verify(False, "Expected Dimension_Mismatch not raised");
      end;
   exception
      when Dimension_Mismatch =>
         Verify (True, "Passed Exception");
   end;

   Put_Line("TEST 11 - Exception Handling: Empty Population (Robustness)");
   Put_Line("  11.1 Assert normalizing an empty or negative population raises Invalid_Population");
   begin
      declare
         Empty_Pop : Population_Vector(1..0);
         Res       : Population_Vector := Normalize(Empty_Pop);
      begin
         Verify(False, "Expected Invalid_Population not raised");
      end;
   exception
      when Invalid_Population =>
         Verify(True, "Passed Exception");
   end;

   Put_Line("TEST 12 - Asymmetric Equilibrium Verification (Functional)");
   Put_Line("  12.1 Assert asymmetric updating preserves probability invariants in bounded game");
   declare
      P_A : Population_Vector(1..2) := (0.5, 0.5);
      P_B : Population_Vector(1..2) := (0.5, 0.5);
   begin
      Step_Asymmetric_Discrete(P_A, P_B, Payoff_HD, Payoff_HD);
      Verify (abs(P_A(1) + P_A(2) - 1.0) < Epsilon and abs(P_B(1) + P_B(2) - 1.0) < Epsilon, 
              "Asymmetric step broke population sum invariant");
   end;

   Put_Line("TEST 13 - Float Drift Prevention Check (Safety)");
   Put_Line("  13.1 Assert extreme derivative with large Delta_T does not produce negative populations");
   declare
      Pop_Drift : Population_Vector(1..2) := (0.01, 0.99);
      Payoff_Extreme : Payoff_Matrix(1..2, 1..2) := (( -100.0, 0.0 ), ( 0.0, 100.0 ));
      Res_Drift : Population_Vector := Step_Continuous(Pop_Drift, Payoff_Extreme, 1.0);
   begin
      Verify(Res_Drift(1) >= 0.0, "Population drifted into negative bounds");
   end;

   Put_Line("==================================================");
   Put_Line("  ALL TESTS PASSED SUCCESSFULLY");
   Put_Line("==================================================");

end Tests;
