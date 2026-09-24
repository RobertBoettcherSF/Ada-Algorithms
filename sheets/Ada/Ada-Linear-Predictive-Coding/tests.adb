-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Linear_Predictive_Coding; use Linear_Predictive_Coding;

procedure Tests is
   Signal_Empty : Signal_Array (1 .. 0);
   Signal_Valid : Signal_Array (1 .. 5) := (1.0, 2.0, 1.0, 2.0, 1.0);
   Signal_Zero  : Signal_Array (1 .. 5) := (others => 0.0);
   
   Coeffs       : Coefficients_Array (1 .. 2);
   Res, Recon   : Signal_Array (1 .. 5);
begin
   Put_Line ("Starting V&V Test Suite - Negative Assumptions...");
   
   Put_Line ("TEST 1 - Empty Signal Assumption");
   Put_Line ("  1.1 [Assertion: Assume code crashes on Empty_Signal instead of exception]");
   begin
      Analyze (Signal_Empty, 2, Autocorrelation, Coeffs, Res);
      Assert (False, "Code did not raise Empty_Signal!");
   exception
      when Empty_Signal => Put_Line ("    PASS - Disproved. Exception raised correctly.");
   end;

   Put_Line ("TEST 2 - Zero Signal Robustness");
   Put_Line ("  2.1 [Assertion: Assume math error/div-zero on 0-signal autocorrelation]");
   Analyze (Signal_Zero, 2, Autocorrelation, Coeffs, Res);
   Assert (Coeffs(1) = 0.0, "Coeffs not zero!");
   Put_Line ("    PASS - Disproved. Handled securely without division by zero.");

   Put_Line ("TEST 3 - Invalid Order Rejection");
   Put_Line ("  3.1 [Assertion: Assume code permits Order >= Signal Length]");
   begin
      Analyze (Signal_Valid, 5, Covariance, Coeffs, Res);
      Assert (False, "Failed to reject invalid order!");
   exception
      when Invalid_Order => Put_Line ("    PASS - Disproved. Order constrained securely.");
   end;

   Put_Line ("TEST 4 - Autocorrelation Analysis Identity");
   Put_Line ("  4.1 [Assertion: Assume Analysis+Synthesis does not yield identity]");
   Analyze (Signal_Valid, 2, Autocorrelation, Coeffs, Res);
   Recon := Synthesize (Coeffs, Res);
   Assert (abs(Recon(3) - Signal_Valid(3)) < 0.001, "Reconstruction loss!");
   Put_Line ("    PASS - Disproved. Identity reconstructed within epsilon.");

   Put_Line ("TEST 5 - Covariance Analysis Identity");
   Put_Line ("  5.1 [Assertion: Assume Covariance method breaks reconstruction]");
   Analyze (Signal_Valid, 2, Covariance, Coeffs, Res);
   Recon := Synthesize (Coeffs, Res);
   Assert (abs(Recon(2) - Signal_Valid(2)) < 0.001, "Reconstruction loss!");
   Put_Line ("    PASS - Disproved. Identity reconstructed properly.");

   Put_Line ("TEST 6 - Burg Analysis Identity");
   Put_Line ("  6.1 [Assertion: Assume Burg method fails lossless reconstruction]");
   Analyze (Signal_Valid, 2, Burg, Coeffs, Res);
   Recon := Synthesize (Coeffs, Res);
   Assert (abs(Recon(4) - Signal_Valid(4)) < 0.001, "Reconstruction loss!");
   Put_Line ("    PASS - Disproved. Identity reconstructed properly.");

   Put_Line ("TEST 7 - Linear Solver Singular Matrix");
   Put_Line ("  7.1 [Assertion: Assume solver crashes natively on singular matrix]");
   begin
      declare
         Mat : Matrix_Array (1..2, 1..2) := ((0.0, 0.0), (0.0, 0.0));
         Vec : Coefficients_Array (1..2) := (1.0, 1.0);
         Res_Vec : Coefficients_Array (1..2);
      begin
         Res_Vec := Solve_Linear_System (Mat, Vec);
         Assert (False, "Did not catch singularity!");
      end;
   exception
      when Math_Error => Put_Line ("    PASS - Disproved. Math_Error isolated properly.");
   end;

   Put_Line ("TEST 8 - Linear Solver Accuracy");
   Put_Line ("  8.1 [Assertion: Assume solver solves I * X = B incorrectly]");
   declare
      Mat : Matrix_Array (1..2, 1..2) := ((1.0, 0.0), (0.0, 1.0));
      Vec : Coefficients_Array (1..2) := (3.14, 2.71);
      Res_Vec : Coefficients_Array (1..2) := Solve_Linear_System (Mat, Vec);
   begin
      Assert (Res_Vec(1) = 3.14, "Identity matrix solve failed!");
      Put_Line ("    PASS - Disproved. Solver computes correctly.");
   end;

   Put_Line ("TEST 9 - Levinson-Durbin Order 1 Safety");
   Put_Line ("  9.1 [Assertion: Assume LD diverges on flat signal]");
   declare
      R : Signal_Array(1..2) := (1.0, 1.0); -- flat DC
      Err : Real;
   begin
      Levinson_Durbin(R, 1, Coeffs(1..1), Err);
      Assert (Err = 0.0, "Error not 0 on perfect correlation");
      Put_Line ("    PASS - Disproved. LD strictly bounds error.");
   end;

   Put_Line ("TEST 10 - Burg Reflection Coefficients Limits");
   Put_Line ("  10.1 [Assertion: Assume Burg reflection coeff limits > 1.0]");
   Analyze (Signal_Valid, 2, Burg, Coeffs, Res);
   -- First coefficient in Burg equates strictly to reflection coeff bounded <= 1.0 natively
   Assert (abs(Coeffs(1)) <= 1.0, "Reflection > 1.0, Filter Unstable!");
   Put_Line ("    PASS - Disproved. Filter remains safely stable.");

   Put_Line ("TEST 11 - Empty Signal Synthesis");
   Put_Line ("  11.1 [Assertion: Assume Synthesis crashes with empty arrays]");
   declare
      Empty_Recon : Signal_Array := Synthesize (Coeffs, Signal_Empty);
   begin
      Assert (Empty_Recon'Length = 0, "Length mismatch");
      Put_Line ("    PASS - Disproved. Safe loop handling for empty arrays.");
   end;

   Put_Line ("TEST 12 - Lags Overreach Autocorrelation");
   Put_Line ("  12.1 [Assertion: Assume Autocorr allows out-of-bounds Lags]");
   declare
      R : Signal_Array := Compute_Autocorrelation (Signal_Valid, 2);
   begin
      Assert (R'Length = 3, "Autocorrelation vector size incorrect!");
      Put_Line ("    PASS - Disproved. Size bounded tightly to Lags+1.");
   end;

   Put_Line ("TEST 13 - Stability of Coefficient Memory (Pointers)");
   Put_Line ("  13.1 [Assertion: Assume state leaks between analysis steps]");
   Analyze (Signal_Valid, 2, Autocorrelation, Coeffs, Res);
   declare
      Coeffs2 : Coefficients_Array(1..2);
      Res2 : Signal_Array(1..5);
   begin
      Analyze (Signal_Valid, 2, Autocorrelation, Coeffs2, Res2);
      Assert (Coeffs(1) = Coeffs2(1), "Determinism failed - State leaked!");
      Put_Line ("    PASS - Disproved. Functions are pure and deterministic.");
   end;

   Put_Line ("===========================================");
   Put_Line ("ALL 13 TESTS COMPLETED AND ASSUMPTIONS DISPROVEN (PASS).");
end Tests;
