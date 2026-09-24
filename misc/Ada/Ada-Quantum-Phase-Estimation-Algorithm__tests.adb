with Ada.Text_IO; use Ada.Text_IO;
with Quantum_Phase_Estimation; use Quantum_Phase_Estimation;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;
begin
   Put_Line ("=== Running Quantum Phase Estimation Test Suite ===");

   -- TEST 1 — Standard QPE with Theta = 0.0
   Put_Line ("TEST 1 — Standard QPE with Theta = 0.0");
   declare
      Res : constant QPE_Result := Simulate_QPE (3, 0.0);
   begin
      Check ("1.1 Outcome integer is 0", Res.Outcome_Integer = 0);
      Check ("1.2 Estimated phase is 0.0", Res.Estimated_Phase = 0.0);
      Check ("1.3 Probability is 1.0 for exact theta", abs (Float (Res.Prob) - 1.0) < 1.0E-5);
   end;

   -- TEST 2 — Standard QPE with Theta = 0.5
   Put_Line ("TEST 2 — Standard QPE with Theta = 0.5");
   declare
      Res : constant QPE_Result := Simulate_QPE (4, 0.5);
   begin
      Check ("2.1 Outcome integer is 8 (half of 16)", Res.Outcome_Integer = 8);
      Check ("2.2 Estimated phase is 0.5", abs (Float (Res.Estimated_Phase) - 0.5) < 1.0E-5);
      Check ("2.3 Probability is 1.0 for exact dyadic fraction", abs (Float (Res.Prob) - 1.0) < 1.0E-5);
   end;

   -- TEST 3 — Standard QPE with Arbitrary Theta = 0.333333
   Put_Line ("TEST 3 — Standard QPE with Arbitrary Theta");
   declare
      Res : constant QPE_Result := Simulate_QPE (5, 0.333333);
   begin
      Check ("3.1 Outcome integer is within valid range 0..31", Res.Outcome_Integer <= 31);
      Check ("3.2 Estimated phase is close to 0.333333", abs (Float (Res.Estimated_Phase) - 0.333333) < 0.05);
      Check ("3.3 Probability is within [0, 1]", Float (Res.Prob) >= 0.0 and then Float (Res.Prob) <= 1.0);
   end;

   -- TEST 4 — Success Probability for Exact Match (delta = 0)
   Put_Line ("TEST 4 — Success Probability Exact Match");
   declare
      Prob : constant Probability := Compute_Success_Probability (4, 0.25, 4); -- 4/16 = 0.25
   begin
      Check ("4.1 Probability for exact match is 1.0", abs (Float (Prob) - 1.0) < 1.0E-5);
      Check ("4.2 Probability is non-negative", Float (Prob) >= 0.0);
      Check ("4.3 Probability does not exceed 1.0", Float (Prob) <= 1.0);
   end;

   -- TEST 5 — Success Probability for Non-Exact Match (delta != 0)
   Put_Line ("TEST 5 — Success Probability Non-Exact Match");
   declare
      Prob : constant Probability := Compute_Success_Probability (3, 0.3, 2); -- 2/8 = 0.25, theta = 0.3
   begin
      Check ("5.1 Probability is calculated successfully", Float (Prob) > 0.0);
      Check ("5.2 Probability is less than 1.0 for non-exact", Float (Prob) < 1.0);
      Check ("5.3 Probability is bounded correctly", Float (Prob) <= 1.0);
   end;

   -- TEST 6 — Success Probability Lower Bound (>= 4/pi^2 approx 0.405)
   Put_Line ("TEST 6 — Success Probability Lower Bound Verification");
   declare
      Prob : constant Probability := Compute_Success_Probability (4, 0.09375, 1);
      Lower_Bound : constant Float := 4.0 / (3.14159265358979323846 ** 2);
   begin
      Check ("6.1 Probability exceeds theoretical lower bound ~0.405", Float (Prob) >= Lower_Bound - 1.0E-3);
      Check ("6.2 Probability is positive", Float (Prob) > 0.0);
      Check ("6.3 Probability is valid", Float (Prob) <= 1.0);
   end;

   -- TEST 7 — Toy 1-Qubit QPE with Theta = 0.0 (lambda = 1)
   Put_Line ("TEST 7 — Toy 1-Qubit QPE Theta = 0.0");
   declare
      Toy : constant Two_Probabilities := Toy_One_Qubit_QPE (0.0);
   begin
      Check ("7.1 P_plus is 1.0 for lambda = 1", abs (Float (Toy.P_Plus) - 1.0) < 1.0E-5);
      Check ("7.2 P_minus is 0.0 for lambda = 1", abs (Float (Toy.P_Minus) - 0.0) < 1.0E-5);
      Check ("7.3 Sum of probabilities is 1.0", abs (Float (Toy.P_Plus + Toy.P_Minus) - 1.0) < 1.0E-5);
   end;

   -- TEST 8 — Toy 1-Qubit QPE with Theta = 0.5 (lambda = -1)
   Put_Line ("TEST 8 — Toy 1-Qubit QPE Theta = 0.5");
   declare
      Toy : constant Two_Probabilities := Toy_One_Qubit_QPE (0.5);
   begin
      Check ("8.1 P_plus is 0.0 for lambda = -1", abs (Float (Toy.P_Plus) - 0.0) < 1.0E-5);
      Check ("8.2 P_minus is 1.0 for lambda = -1", abs (Float (Toy.P_Minus) - 1.0) < 1.0E-4);
      Check ("8.3 Sum of probabilities is 1.0", abs (Float (Toy.P_Plus + Toy.P_Minus) - 1.0) < 1.0E-4);
   end;

   -- TEST 9 — Toy 1-Qubit QPE with Theta = 1.0 / 3.0
   Put_Line ("TEST 9 — Toy 1-Qubit QPE Theta = 1/3");
   declare
      Toy : constant Two_Probabilities := Toy_One_Qubit_QPE (0.333333333333);
   begin
      Check ("9.1 P_plus is positive", Float (Toy.P_Plus) > 0.0);
      Check ("9.2 P_minus is greater than P_plus for theta=1/3", Float (Toy.P_Minus) > Float (Toy.P_Plus));
      Check ("9.3 Sum of probabilities is 1.0", abs (Float (Toy.P_Plus + Toy.P_Minus) - 1.0) < 1.0E-4);
   end;

   -- TEST 10 — Required Qubits for High Precision (epsilon = 0.001)
   Put_Line ("TEST 10 — Required Qubits High Precision");
   declare
      N : constant Qubit_Count := Required_Qubits (0.001);
   begin
      Check ("10.1 Required qubits >= 10 for epsilon = 0.001", N >= 10);
      pragma Warnings (Off, "explicit membership test may be optimized away");
      Check ("10.2 Required qubits within valid range", N in 1 .. 24);
      pragma Warnings (On, "explicit membership test may be optimized away");
      Check ("10.3 Required qubits correct order of magnitude", N <= 15);
   end;

   -- TEST 11 — Required Qubits for Moderate Precision (epsilon = 0.01)
   Put_Line ("TEST 11 — Required Qubits Moderate Precision");
   declare
      N : constant Qubit_Count := Required_Qubits (0.01);
   begin
      Check ("11.1 Required qubits >= 7 for epsilon = 0.01", N >= 7);
      pragma Warnings (Off, "explicit membership test may be optimized away");
      Check ("11.2 Required qubits within valid range", N in 1 .. 24);
      pragma Warnings (On, "explicit membership test may be optimized away");
      Check ("11.3 Required qubits <= 10", N <= 10);
   end;

   -- TEST 12 — Phase Validation Helper (Valid Phases)
   Put_Line ("TEST 12 — Phase Validation Valid");
   declare
      Valid_Passed : Boolean := True;
   begin
      begin
         Validate_Phase (0.0);
         Validate_Phase (0.5);
         Validate_Phase (0.9999);
      exception
         when others =>
            Valid_Passed := False;
      end;
      Check ("12.1 Valid phase 0.0 accepted", Valid_Passed);
      Check ("12.2 Valid phase 0.5 accepted", Valid_Passed);
      Check ("12.3 Valid phase 0.9999 accepted", Valid_Passed);
   end;

   -- TEST 13 — Phase Validation Exception Handling (Invalid Phases)
   Put_Line ("TEST 13 — Phase Validation Exception Handling");
   declare
      Negative_Caught : Boolean := False;
      Too_Large_Caught : Boolean := False;
   begin
      begin
         Validate_Phase (-0.1);
      exception
         when Invalid_Phase =>
            Negative_Caught := True;
      end;

      begin
         Validate_Phase (1.0);
      exception
         when Invalid_Phase =>
            Too_Large_Caught := True;
      end;

      Check ("13.1 Negative phase raises Invalid_Phase", Negative_Caught);
      Check ("13.2 Phase >= 1.0 raises Invalid_Phase", Too_Large_Caught);
      Check ("13.3 Exception handling verified across range", Negative_Caught and Too_Large_Caught);
   end;

   -- TEST 14 — Edge Cases: Minimum and Maximum Qubit Bounds
   Put_Line ("TEST 14 — Edge Cases Qubit Bounds");
   declare
      Res_Min : constant QPE_Result := Simulate_QPE (1, 0.25);
      Res_Max : constant QPE_Result := Simulate_QPE (24, 0.123456);
   begin
      Check ("14.1 Min qubit N=1 executes successfully", Res_Min.Outcome_Integer <= 1);
      Check ("14.2 Max qubit N=24 executes successfully", Res_Max.Outcome_Integer <= 16777215);
      Check ("14.3 Probabilities for boundary tests are valid", Float (Res_Min.Prob) >= 0.0 and then Float (Res_Max.Prob) <= 1.0);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
              & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
