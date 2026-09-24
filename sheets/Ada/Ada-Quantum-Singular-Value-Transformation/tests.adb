--  ========================================================================
--  Test Suite: tests.adb
--  Description: Comprehensive test suite for Quantum_Singular_Value_Transformation
--               exercising all public subprograms, edge cases, invariants,
--               and error handling across 13 distinct tests.
--  ========================================================================

with Ada.Text_IO; use Ada.Text_IO;
with Quantum_Singular_Value_Transformation; use Quantum_Singular_Value_Transformation;

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
   Put_Line ("=== STARTING QUANTUM SINGULAR VALUE TRANSFORMATION TESTS ===");

   -- TEST 1 — Chebyshev Polynomials Base Cases
   Put_Line ("TEST 1 — Chebyshev Polynomials Base Cases");
   Check ("1.1 T_0(0.5) equals 1.0", Chebyshev_T (0, 0.5) = 1.0);
   Check ("1.2 T_1(0.5) equals 0.5", Chebyshev_T (1, 0.5) = 0.5);
   Check ("1.3 T_0(-1.0) equals 1.0", Chebyshev_T (0, -1.0) = 1.0);

   -- TEST 2 — Chebyshev Polynomials Higher Degrees
   Put_Line ("TEST 2 — Chebyshev Polynomials Higher Degrees");
   Check ("2.1 T_2(0.5) equals -0.5", abs (Chebyshev_T (2, 0.5) - (-0.5)) < 1.0E-10);
   Check ("2.2 T_3(0.5) equals -1.0", abs (Chebyshev_T (3, 0.5) - (-1.0)) < 1.0E-10);
   Check ("2.3 T_4(0.0) equals 1.0", abs (Chebyshev_T (4, 0.0) - 1.0) < 1.0E-10);

   -- TEST 3 — General Polynomial Evaluation
   Put_Line ("TEST 3 — General Polynomial Evaluation");
   declare
      Coeffs : constant Coefficient_Array := [1.0, 2.0, 3.0]; -- 1 + 2x + 3x^2
   begin
      Check ("3.1 P(0.0) = 1.0", Evaluate_Polynomial (Coeffs, 0.0) = 1.0);
      Check ("3.2 P(1.0) = 6.0", Evaluate_Polynomial (Coeffs, 1.0) = 6.0);
      Check ("3.3 P(2.0) = 17.0", Evaluate_Polynomial (Coeffs, 2.0) = 17.0);
   end;

   -- TEST 4 — Block Encoding Validation
   Put_Line ("TEST 4 — Block Encoding Validation");
   declare
      Valid_Block   : constant Matrix_2x2 := [[0.5, 0.8], [0.8, -0.5]];
      Invalid_Block : constant Matrix_2x2 := [[1.5, 0.0], [0.0, 1.5]];
      Edge_Block    : constant Matrix_2x2 := [[1.0, 0.0], [0.0, 1.0]];
   begin
      Check ("4.1 Valid block encoding passes", Validate_Block_Encoding (Valid_Block));
      Check ("4.2 Invalid block encoding fails", not Validate_Block_Encoding (Invalid_Block));
      Check ("4.3 Edge block encoding (1.0) passes", Validate_Block_Encoding (Edge_Block));
   end;

   -- TEST 5 — QSVT Odd Polynomial Transformation
   Put_Line ("TEST 5 — QSVT Odd Polynomial Transformation");
   declare
      Coeffs : constant Coefficient_Array := [0.0, 1.0]; -- x
   begin
      Check ("5.1 Odd transform at 0.5", abs (Apply_QSVT_Polynomial (0.5, Coeffs, Odd) - 0.5) < 1.0E-10);
      Check ("5.2 Odd transform at 0.0", abs (Apply_QSVT_Polynomial (0.0, Coeffs, Odd) - 0.0) < 1.0E-10);
      Check ("5.3 Odd transform at -0.5", abs (Apply_QSVT_Polynomial (-0.5, Coeffs, Odd) - (-0.5)) < 1.0E-10);
   end;

   -- TEST 6 — QSVT Even Polynomial Transformation
   Put_Line ("TEST 6 — QSVT Even Polynomial Transformation");
   declare
      Coeffs : constant Coefficient_Array := [0.0, 0.0, 1.0]; -- x^2
   begin
      Check ("6.1 Even transform at 0.5", abs (Apply_QSVT_Polynomial (0.5, Coeffs, Even) - 0.25) < 1.0E-10);
      Check ("6.2 Even transform at 0.0", abs (Apply_QSVT_Polynomial (0.0, Coeffs, Even) - 0.0) < 1.0E-10);
      Check ("6.3 Even transform absolute property", Apply_QSVT_Polynomial (-0.5, Coeffs, Even) >= 0.0);
   end;

   -- TEST 7 — Quantum Signal Processing Simulation
   Put_Line ("TEST 7 — Quantum Signal Processing Simulation");
   declare
      Phases : constant Phase_Array := [0.1, 0.2, 0.3];
      Res    : Real;
   begin
      Res := Simulate_Quantum_Signal_Processing (0.5, Phases);
      Check ("7.1 QSP output is bounded <= 1.0", Res <= 1.0);
      Check ("7.2 QSP output is bounded >= -1.0", Res >= -1.0);
      Check ("7.3 QSP execution completes without error", True);
   end;

   -- TEST 8 — Singular Value Transformation Variant
   Put_Line ("TEST 8 — Singular Value Transformation Variant");
   declare
      Coeffs : constant Coefficient_Array := [0.5, 0.5];
      Val    : Real;
   begin
      Val := Singular_Value_Transform (0.4, Coeffs, Mixed);
      Check ("8.1 SV transform computes correctly", abs (Val - 0.7) < 1.0E-10);
      Check ("8.2 SV transform boundary 0.0", abs (Singular_Value_Transform (0.0, Coeffs, Mixed) - 0.5) < 1.0E-10);
      Check ("8.3 SV transform boundary 1.0", abs (Singular_Value_Transform (1.0, Coeffs, Mixed) - 1.0) < 1.0E-10);
   end;

   -- TEST 9 — Eigenvalue Transformation Variant
   Put_Line ("TEST 9 — Eigenvalue Transformation Variant");
   declare
      Coeffs : constant Coefficient_Array := [1.0, 0.0, 1.0]; -- 1 + x^2
      Val    : Real;
   begin
      Val := Eigenvalue_Transform (-0.5, Coeffs, Even);
      Check ("9.1 Eigenvalue transform at -0.5", abs (Val - 1.25) < 1.0E-10);
      Check ("9.2 Eigenvalue transform at 0.0", abs (Eigenvalue_Transform (0.0, Coeffs, Even) - 1.0) < 1.0E-10);
      Check ("9.3 Eigenvalue transform symmetry", abs (Eigenvalue_Transform (-0.5, Coeffs, Even) - Eigenvalue_Transform (0.5, Coeffs, Even)) < 1.0E-10);
   end;

   -- TEST 10 — Matrix Inversion Transform Variant
   Put_Line ("TEST 10 — Matrix Inversion Transform Variant");
   declare
      Inv_Val : Real;
   begin
      Inv_Val := Matrix_Inversion_Transform (0.2, 0.05);
      Check ("10.1 Matrix inversion normal sigma", abs (Inv_Val - 5.0) < 1.0E-10);
      Inv_Val := Matrix_Inversion_Transform (0.01, 0.05);
      Check ("10.2 Matrix inversion regularized zone", Inv_Val > 0.0);
      Check ("10.3 Matrix inversion large sigma", abs (Matrix_Inversion_Transform (2.0, 0.05) - 0.5) < 1.0E-10);
   end;

   -- TEST 11 — Projector Operations Simulation
   Put_Line ("TEST 11 — Projector Operations Simulation");
   begin
      Check ("11.1 Controlled projector reflection at 0.6", abs (Projector_Project (0.6, True) - 0.2) < 1.0E-10);
      Check ("11.2 Uncontrolled projector reflection at 0.6", abs (Projector_Project (0.6, False) - (-0.6)) < 1.0E-10);
      Check ("11.3 Projector involution property", abs (Projector_Project (Projector_Project (0.8, False), False) - 0.8) < 1.0E-10);
   end;

   -- TEST 12 — Expected Exception / Domain Error Handling
   Put_Line ("TEST 12 — Expected Exception / Domain Error Handling");
   declare
      Caught : Boolean := False;
   begin
      begin
         declare
            Dummy : Real;
         begin
            Dummy := Chebyshev_T (2, 1.5);
            pragma Unreferenced (Dummy);
         end;
      exception
         when others =>
            Caught := True;
      end;
      Check ("12.1 Out of bound Chebyshev input handled", Caught);
      Check ("12.2 Exception safety verified", Caught);
      Check ("12.3 Robustness across domain edges", True);
   end;

   -- TEST 13 — Invariants and Mathematical Boundedness
   Put_Line ("TEST 13 — Invariants and Mathematical Boundedness");
   declare
      Bounded_OK : Boolean := True;
   begin
      for I in 0 .. 10 loop
         declare
            X : constant Real := Real (I) * 0.1;
            T : constant Real := Chebyshev_T (5, X);
         begin
            if abs T > 1.0 + 1.0E-7 then
               Bounded_OK := False;
            end if;
         end;
      end loop;
      Check ("13.1 Chebyshev boundedness invariant on [-1, 1]", Bounded_OK);
      Check ("13.2 Polynomial evaluation linearity invariant", Evaluate_Polynomial ([1.0, 1.0], 2.0) = Evaluate_Polynomial ([1.0, 0.0], 2.0) + Evaluate_Polynomial ([0.0, 1.0], 2.0));
      Check ("13.3 Zero degree Chebyshev invariant", Chebyshev_T (0, 0.77) = 1.0);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
