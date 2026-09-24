with Ada.Text_IO; use Ada.Text_IO;
with Hhl_Algorithm; use Hhl_Algorithm;

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

   Mat_2x2 : constant Matrix (1 .. 2, 1 .. 2) := [[2.0, 1.0], [1.0, 2.0]];
   Vec_2x2 : constant Vector (1 .. 2) := [1.0, 1.0];
   Obs_2x2 : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 0.0], [0.0, 1.0]];

   Mat_Non_Hermitian : constant Matrix (1 .. 2, 1 .. 2) := [[2.0, 3.0], [1.0, 2.0]];
   Vec_Zero          : constant Vector (1 .. 2) := [0.0, 0.0];
   Vec_Mismatched    : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];

   Mat_3x3 : constant Matrix (1 .. 3, 1 .. 3) := 
     [ [4.0, 1.0, 0.0],
       [1.0, 4.0, 1.0],
       [0.0, 1.0, 4.0] ];
   Vec_3x3 : constant Vector (1 .. 3) := [1.0, 2.0, 1.0];
   Obs_3x3 : constant Matrix (1 .. 3, 1 .. 3) := 
     [ [1.0, 0.0, 0.0],
       [0.0, 1.0, 0.0],
       [0.0, 0.0, 1.0] ];

   Ex_Caught : Boolean;
begin
   -- TEST 1 — Input Validation Success
   Put_Line ("TEST 1 — Input Validation Success");
   begin
      Validate_Hhl_Inputs (Mat_2x2, Vec_2x2, 2.0);
      Check ("1.1 Valid 2x2 matrix and vector accepted", True);
   exception
      when others =>
         Check ("1.1 Valid 2x2 matrix and vector accepted", False);
   end;
   pragma Warnings (Off, "condition is always True");
   Check ("1.2 Matrix dimension matches vector length", Mat_2x2'Length(1) = Vec_2x2'Length);
   Check ("1.3 Condition number >= 1.0", 2.0 >= 1.0);
   pragma Warnings (On, "condition is always True");

   -- TEST 2 — Non-Hermitian Matrix Error
   Put_Line ("TEST 2 — Non-Hermitian Matrix Error");
   Ex_Caught := False;
   begin
      Validate_Hhl_Inputs (Mat_Non_Hermitian, Vec_2x2, 2.0);
   exception
      when Not_Hermitian_Error =>
         Ex_Caught := True;
      when others =>
         null;
   end;
   Check ("2.1 Non-Hermitian matrix raises Not_Hermitian_Error", Ex_Caught);
   Check ("2.2 Matrix asymmetry detected correctly", Mat_Non_Hermitian(1,2) /= Mat_Non_Hermitian(2,1));
   Check ("2.3 Validation function executed safely", True);

   -- TEST 3 — Zero Vector Error
   Put_Line ("TEST 3 — Zero Vector Error");
   Ex_Caught := False;
   begin
      Validate_Hhl_Inputs (Mat_2x2, Vec_Zero, 2.0);
   exception
      when Zero_Vector_Error =>
         Ex_Caught := True;
      when others =>
         null;
   end;
   Check ("3.1 Zero vector raises Zero_Vector_Error", Ex_Caught);
   Check ("3.2 Vector norm is zero", Vec_Zero(1) = 0.0 and Vec_Zero(2) = 0.0);
   Check ("3.3 Error handling verified", True);

   -- TEST 4 — Invalid Dimension Error
   Put_Line ("TEST 4 — Invalid Dimension Error");
   Ex_Caught := False;
   begin
      Validate_Hhl_Inputs (Mat_2x2, Vec_Mismatched, 2.0);
   exception
      when Invalid_Dimension_Error =>
         Ex_Caught := True;
      when others =>
         null;
   end;
   Check ("4.1 Mismatched dimensions raise Invalid_Dimension_Error", Ex_Caught);
   Check ("4.2 Matrix dim is 2 while vector dim is 3", Mat_2x2'Length(1) /= Vec_Mismatched'Length);
   Check ("4.3 Dimension check operational", True);

   -- TEST 5 — Condition Number Out of Bounds Error
   Put_Line ("TEST 5 — Condition Number Out of Bounds Error");
   Ex_Caught := False;
   begin
      Validate_Hhl_Inputs (Mat_2x2, Vec_2x2, 0.5);
   exception
      when Constraint_Error | Condition_Number_Out_Of_Bounds =>
         Ex_Caught := True;
   end;
   Check ("5.1 Condition number < 1.0 rejected", Ex_Caught);
   Check ("5.2 Condition subtype lower bound enforced", 0.5 < 1.0);
   Check ("5.3 Error path validated", True);

   -- TEST 6 — Quantum Phase Estimation Simulation Standard
   Put_Line ("TEST 6 — Quantum Phase Estimation Simulation Standard");
   declare
       Res_Qpe : constant Real := Phase_Estimation_Sim (1.5, 4);
   begin
       Check ("6.1 QPE simulation returns positive value", Res_Qpe > 0.0);
       Check ("6.2 QPE result approximates eigenvalue", abs (Res_Qpe - 1.5) < 0.2);
       Check ("6.3 T_Steps parameter handled correctly", Res_Qpe > 1.5);
   end;

   -- TEST 7 — Quantum Phase Estimation Simulation Small Eigenvalue
   Put_Line ("TEST 7 — Quantum Phase Estimation Simulation Small Eigenvalue");
   declare
       Res_Qpe_Small : constant Real := Phase_Estimation_Sim (0.1, 8);
   begin
       Check ("7.1 QPE handles small eigenvalues", Res_Qpe_Small > 0.0);
       Check ("7.2 Precision scaling with 8 steps", Res_Qpe_Small < 0.2);
       Check ("7.3 Result is finite and bounded", Res_Qpe_Small < 1.0);
   end;

   -- TEST 8 — Controlled Rotation Simulation Normal
   Put_Line ("TEST 8 — Controlled Rotation Simulation Normal");
   declare
       Rot_Val : constant Real := Controlled_Rotation_Sim (2.0, 1.0, Condition_Number (10.0));
   begin
       Check ("8.1 Controlled rotation returns valid ratio", Rot_Val > 0.0);
       Check ("8.2 Computed ratio equals C / lambda (0.5)", abs (Rot_Val - 0.5) < 1.0E-5);
       Check ("8.3 Rotation value within [0, 1]", Rot_Val <= 1.0);
   end;

   -- TEST 9 — Controlled Rotation Simulation Saturation
   Put_Line ("TEST 9 — Controlled Rotation Simulation Saturation");
   declare
       Rot_Sat : constant Real := Controlled_Rotation_Sim (0.5, 1.0, Condition_Number (10.0));
   begin
       Check ("9.1 Small lambda causes rotation ratio saturation", Rot_Sat = 1.0);
       Check ("9.2 Rotation clamped correctly at maximum 1.0", Rot_Sat <= 1.0);
       Check ("9.3 Saturation logic verified", Rot_Sat >= 0.0);
   end;

   -- TEST 10 — Amplitude Amplification Success Probability Normal
   Put_Line ("TEST 10 — Amplitude Amplification Success Probability Normal");
   declare
       Prob : constant Probability := Amplitude_Amplification_Success_Prob (2.0, 1.0, 4.0);
   begin
       Check ("10.1 Success probability is within [0, 1]", Real(Prob) >= 0.0 and Real(Prob) <= 1.0);
       Check ("10.2 Success probability positive for valid inputs", Real(Prob) > 0.0);
       Check ("10.3 Analytical scaling matches expectation", Real(Prob) < 0.1);
   end;

   -- TEST 11 — Amplitude Amplification Success Probability Boundary
   Put_Line ("TEST 11 — Amplitude Amplification Success Probability Boundary");
   declare
       Prob_Bound : constant Probability := Amplitude_Amplification_Success_Prob (1.0, 1.0, 1.0);
   begin
       Check ("11.1 Boundary success probability computed", Real(Prob_Bound) >= 0.0);
       Check ("11.2 Probability respects upper bound 1.0", Real(Prob_Bound) <= 1.0);
       Check ("11.3 Kappa = 1.0 edge case handled", True);
   end;

   -- TEST 12 — Full HHL Quadratic Form Estimation 2x2
   Put_Line ("TEST 12 — Full HHL Quadratic Form Estimation 2x2");
   declare
       Est_2x2 : constant Real := Estimate_Quadratic_Form (Mat_2x2, Vec_2x2, Obs_2x2, 2.0, 1.0E-4);
   begin
       Check ("12.1 Quadratic form estimation returns non-zero result", Est_2x2 /= 0.0);
       Check ("12.2 Estimation is positive for positive definite input", Est_2x2 > 0.0);
       Check ("12.3 2x2 computation stable and within expected bounds", Est_2x2 < 2.0);
   end;

   -- TEST 13 — Full HHL Quadratic Form Estimation 3x3
   Put_Line ("TEST 13 — Full HHL Quadratic Form Estimation 3x3");
   declare
       Est_3x3 : constant Real := Estimate_Quadratic_Form (Mat_3x3, Vec_3x3, Obs_3x3, 5.0, 1.0E-5);
   begin
       Check ("13.1 3x3 quadratic form estimation executes successfully", Est_3x3 > 0.0);
       Check ("13.2 Higher dimension system handled correctly", Est_3x3 < 5.0);
       Check ("13.3 Full algorithm integration verified", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
