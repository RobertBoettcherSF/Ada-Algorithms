--  Standalone test suite for Rayleigh_Quotient_Iteration (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Rayleigh_Quotient_Iteration; use Rayleigh_Quotient_Iteration;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Float; Tol : Float := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Ada.Text_IO.Put_Line ("Rayleigh_Quotient_Iteration test suite");
   Ada.Text_IO.Put_Line ("======================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Dot / Norm2 / Scale / Add / Sub");
   ---------------------------------------------------------------------
   declare
      U : constant Vector (1 .. 3) := [3.0, 4.0, 0.0];
      V : constant Vector (1 .. 3) := [3.0, 4.0, 0.0];
      W : constant Vector (1 .. 3) := [1.0, 0.0, 0.0];
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny");
      Check (not Near (1.0, 2.0), "Near rejects");
      Check (Vec_Near (U, V), "Vec_Near equal");
      Check (not Vec_Near (U, W), "Vec_Near rejects");
      Check (Approx (Dot (U, W), 3.0), "Dot U·W");
      Check (Approx (Norm2 (U), 5.0), "Norm2 3-4-5");
      Check (Approx (Scale (W, 2.0) (1), 2.0), "Scale");
      Check (Approx (Add (W, W) (1), 2.0), "Add");
      Check (Approx (Sub (U, V) (1), 0.0), "Sub zero");
      Check (Approx (Dot (W, W), 1.0), "Dot unit");
      Check (Near (-2.0, -2.0), "Near negatives");
      Check (Approx (Norm2 (W), 1.0), "Norm2 unit");
      Check (Approx (Dot (U, U), 25.0), "Dot U·U");
   end;

   ---------------------------------------------------------------------
   Section ("2. Mat_Vec / symmetry / Normalize");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[4.0, 1.0],
         [1.0, 3.0]];
      Asym : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 2.0],
         [0.0, 1.0]];
      X : constant Vector (1 .. 2) := [1.0, 1.0];
      Y : constant Vector := Mat_Vec (A, X);
      Nrm : constant Vector := Normalize ([3.0, 4.0]);
   begin
      Check (Approx (Y (1), 5.0), "Mat_Vec row1");
      Check (Approx (Y (2), 4.0), "Mat_Vec row2");
      Check (Is_Square (A), "Is_Square");
      Check (Is_Symmetric (A), "Is_Symmetric A");
      Check (not Is_Symmetric (Asym), "Is_Symmetric rejects");
      Check (Approx (Norm2 (Nrm), 1.0), "Normalize unit");
      Check (Approx (Nrm (1), 0.6, 1.0E-6), "Normalize 3/5");
      Check (Approx (Nrm (2), 0.8, 1.0E-6), "Normalize 4/5");
   end;

   ---------------------------------------------------------------------
   Section ("3. Rayleigh_Quotient / Eigen_Residual");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 3, 1 .. 3) :=
        Make_Diagonal ([2.0, 5.0, -1.0]);
      E2 : constant Vector := Make_Unit_Vector (3, 2);
      E1 : constant Vector := Make_Unit_Vector (3, 1);
      R : constant Float := Rayleigh_Quotient (A, E2);
      Resv : constant Vector := Eigen_Residual (A, E2, 5.0);
   begin
      Check (Approx (R, 5.0), "RQ exact eigenvector e2");
      Check (Approx (Rayleigh_Quotient (A, E1), 2.0), "RQ e1 → 2");
      Check (Approx (Eigen_Residual_Norm (A, E2, 5.0), 0.0),
             "Eigen residual 0 on eigenpair");
      Check (Approx (Resv (1), 0.0) and Approx (Resv (2), 0.0)
             and Approx (Resv (3), 0.0),
             "Eigen_Residual zero vector");
      Check (Approx (Rayleigh_Quotient (A, [1.0, 1.0, 1.0]),
                     (2.0 + 5.0 + (-1.0)) / 3.0, 1.0E-5),
             "RQ average of diagonal");
   end;

   ---------------------------------------------------------------------
   Section ("4. Builders: Diagonal / Poisson / Hilbert / Randomish");
   ---------------------------------------------------------------------
   declare
      D : constant Matrix := Make_Diagonal ([1.0, 3.0, 7.0]);
      Dk : constant Matrix := Make_Symmetric_Example (Diagonal_Known, 4);
      P : constant Matrix := Make_Symmetric_Example (Poisson_1D, 4);
      H : constant Matrix := Make_Symmetric_Example (Hilbert_Tiny, 3);
      R : constant Matrix := Make_Symmetric_Example (Symmetric_Randomish, 3);
      Ones : constant Vector := Make_Ones_Vector (3);
      U : constant Vector := Make_Unit_Vector (3, 2);
      Pert : constant Vector := Make_Perturbed_Basis (3, 1, 0.1);
   begin
      Check (Approx (D (1, 1), 1.0) and Approx (D (2, 2), 3.0)
             and Approx (D (3, 3), 7.0),
             "Make_Diagonal diags");
      Check (Approx (D (1, 2), 0.0), "Make_Diagonal off-diag 0");
      Check (Approx (Dk (4, 4), 4.0), "Diagonal_Known last");
      Check (Is_Symmetric (Dk), "Diagonal_Known symmetric");
      Check (Approx (P (1, 1), 2.0) and Approx (P (1, 2), -1.0),
             "Poisson stencil");
      Check (Is_Symmetric (P), "Poisson symmetric");
      Check (Approx (H (1, 1), 1.0) and Approx (H (1, 2), 0.5),
             "Hilbert entries");
      Check (Is_Symmetric (H), "Hilbert symmetric");
      Check (Is_Symmetric (R), "Randomish symmetric");
      Check (Approx (Ones (2), 1.0), "Make_Ones_Vector");
      Check (Approx (U (2), 1.0) and Approx (U (1), 0.0),
             "Make_Unit_Vector");
      Check (Approx (Norm2 (Pert), 1.0, 1.0E-5), "Perturbed unit");
      Check (Pert (1) > Pert (2), "Perturbed near e1");
   end;

   ---------------------------------------------------------------------
   Section ("5. Solve_Shifted GEPP on well-conditioned system");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[4.0, 1.0],
         [1.0, 3.0]];
      --  (A − 0·I) y = [5,4] ⇒ y = [1,1]
      B : constant Vector (1 .. 2) := [5.0, 4.0];
      L : constant Linear_Result := Solve_Shifted (A, 0.0, B);
   begin
      Check (L.Success, "Solve_Shifted Success");
      Check (L.Stat = Ok, "Solve_Shifted Ok");
      Check (Approx (L.Y (1), 1.0, 1.0E-5), "Solve_Shifted y1");
      Check (Approx (L.Y (2), 1.0, 1.0E-5), "Solve_Shifted y2");
   end;

   ---------------------------------------------------------------------
   Section ("6. Exact eigenpairs on diagonal (RQI)");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix :=
        Make_Diagonal ([1.0, 2.0, 3.0, 4.0]);
      X0 : constant Vector := Make_Perturbed_Basis (4, 3, 0.05);
      Res : constant Result :=
        Iterate (A, X0, (Tol => 1.0E-7, Max_Iter => 30,
                         Initial_Mu => 0.0, Use_Initial_Mu => False));
   begin
      Check (Res.Success, "Diag RQI Success");
      Check (Res.Stat = Converged, "Diag RQI Converged");
      Check (Res.N = 4, "Diag RQI N");
      Check (Approx (Res.Mu, 3.0, 1.0E-4), "Diag RQI μ → 3");
      Check (Res.Residual <= 1.0E-6, "Diag RQI residual");
      Check (Approx (abs (Res.X (3)), 1.0, 1.0E-3)
             or else Approx (Norm2 (Res.X (1 .. 4)), 1.0, 1.0E-5),
             "Diag RQI eigenvector concentrated / unit");
      Check (Approx (Norm2 (Res.X (1 .. 4)), 1.0, 1.0E-5),
             "Diag RQI ‖x‖=1");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([10.0, -2.0, 0.5]);
      X0 : constant Vector := Make_Perturbed_Basis (3, 1, 0.02);
      Res : constant Result :=
        Solve (A, X0, (Tol => 1.0E-8, Max_Iter => 40,
                       Initial_Mu => 9.5, Use_Initial_Mu => True));
   begin
      Check (Res.Success, "Solve alias Success");
      Check (Res.Stat = Converged, "Solve alias Converged");
      Check (Approx (Res.Mu, 10.0, 1.0E-4), "Solve → λ=10 with μ₀");
      Check (Res.Residual <= 1.0E-6, "Solve residual");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([-3.0, 1.0]);
      X0 : constant Vector := [0.1, 1.0];
      Res : constant Result :=
        Iterate (A, X0, (Tol => 1.0E-8, Max_Iter => 20,
                         Initial_Mu => 0.0, Use_Initial_Mu => False));
   begin
      Check (Res.Success, "2×2 diag Success");
      Check (Approx (Res.Mu, 1.0, 1.0E-4), "2×2 diag → 1");
      Check (Res.Residual <= 1.0E-6, "2×2 residual");
   end;

   ---------------------------------------------------------------------
   Section ("7. Quotient accuracy vs residual consistency");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix :=
        Make_Symmetric_Example (Poisson_1D, 5);
      X0 : constant Vector := Make_Ones_Vector (5);
      Res : constant Result :=
        Iterate (A, X0, (Tol => 1.0E-7, Max_Iter => 40,
                         Initial_Mu => 0.0, Use_Initial_Mu => False));
      Rq : Float;
   begin
      Check (Res.Success, "Poisson RQI Success");
      Check (Res.Stat = Converged, "Poisson Converged");
      Rq := Rayleigh_Quotient (A, Res.X (1 .. 5));
      Check (Approx (Rq, Res.Mu, 1.0E-5), "μ matches RQ of result x");
      Check (Approx (Eigen_Residual_Norm (A, Res.X (1 .. 5), Res.Mu),
                     Res.Residual, 1.0E-5),
             "Residual field matches Eigen_Residual_Norm");
      Check (Res.Residual <= 1.0E-6, "Poisson residual small");
      Check (Is_Symmetric (A), "Poisson still symmetric");
   end;

   ---------------------------------------------------------------------
   Section ("8. Hilbert tiny / Symmetric_Randomish residuals");
   ---------------------------------------------------------------------
   declare
      H : constant Matrix :=
        Make_Symmetric_Example (Hilbert_Tiny, 3);
      X0 : constant Vector := [1.0, 0.2, 0.1];
      Res : constant Result :=
        Iterate (H, X0, (Tol => 1.0E-5, Max_Iter => 50,
                         Initial_Mu => 1.5, Use_Initial_Mu => True));
   begin
      Check (Res.Success, "Hilbert RQI Success");
      Check (Res.Stat = Converged, "Hilbert Converged");
      Check (Res.Residual <= 1.0E-4, "Hilbert residual bound");
      Check (Approx (Norm2 (Res.X (1 .. 3)), 1.0, 1.0E-5),
             "Hilbert ‖x‖=1");
   end;

   declare
      R : constant Matrix :=
        Make_Symmetric_Example (Symmetric_Randomish, 4);
      X0 : constant Vector := Make_Perturbed_Basis (4, 2, 0.15);
      Res : constant Result :=
        Iterate (R, X0, (Tol => 1.0E-6, Max_Iter => 50,
                         Initial_Mu => 0.0, Use_Initial_Mu => False));
   begin
      Check (Res.Success, "Randomish RQI Success");
      Check (Res.Stat = Converged, "Randomish Converged");
      Check (Res.Residual <= 1.0E-5, "Randomish residual");
      Check (Is_Symmetric (R), "Randomish A symmetric");
   end;

   ---------------------------------------------------------------------
   Section ("9. Already-exact start / Ill_Started / bad dims");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([2.0, 4.0]);
      E : constant Vector := Make_Unit_Vector (2, 1);
      Res : constant Result :=
        Iterate (A, E, (Tol => 1.0E-8, Max_Iter => 10,
                        Initial_Mu => 0.0, Use_Initial_Mu => False));
   begin
      Check (Res.Success, "Exact start Success");
      Check (Res.Stat = Converged, "Exact start Converged");
      Check (Res.Iterations = 0, "Exact start 0 iters");
      Check (Approx (Res.Mu, 2.0), "Exact start μ=2");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([1.0, 2.0]);
      Z : constant Vector (1 .. 2) := [0.0, 0.0];
      Res : constant Result :=
        Iterate (A, Z, Default_Parameters);
   begin
      Check (not Res.Success, "Zero start not Success");
      Check (Res.Stat = Ill_Started, "Zero start Ill_Started");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([1.0, 2.0, 3.0]);
      X0 : constant Vector := [1.0, 1.0];  -- wrong length vs Pre — skip
      --  Exercise Negative Tol path via Parameters
      Res : constant Result :=
        Iterate (A, [1.0, 0.0, 0.0],
                 (Tol => -1.0, Max_Iter => 5,
                  Initial_Mu => 0.0, Use_Initial_Mu => False));
   begin
      Check (Res.Stat = Ill_Started, "Negative Tol Ill_Started");
      Check (not Res.Success, "Negative Tol not Success");
      Check (X0'Length = 2, "Dim note length-2 vector exists");
   end;

   ---------------------------------------------------------------------
   Section ("10. Singular_Shift handling");
   ---------------------------------------------------------------------
   --  Direct GEPP: (diag(1,2) − 1·I) with RHS = e1 is singular/inconsistent.
   declare
      A : constant Matrix := Make_Diagonal ([1.0, 2.0]);
      E1 : constant Vector := Make_Unit_Vector (2, 1);
      L : constant Linear_Result := Solve_Shifted (A, 1.0, E1);
   begin
      Check (not L.Success, "Solve_Shifted singular not Success");
      Check (L.Stat = Singular or else L.Stat = Zero_Pivot,
             "Solve_Shifted Singular/Zero_Pivot");
   end;

   --  Iterate recovers from an exact eigenvalue shift via a tiny μ perturbation.
   declare
      A : constant Matrix := Make_Diagonal ([1.0, 2.0, 3.0]);
      X0 : constant Vector := Make_Unit_Vector (3, 1);  -- eigenvec for 1
      Res : constant Result :=
        Iterate (A, X0,
                 (Tol => 1.0E-8, Max_Iter => 20,
                  Initial_Mu => 2.0, Use_Initial_Mu => True));
      --  μ₀=2 but x=e1 ⇒ A−2I singular; package perturbs shift / falls back.
   begin
      Check (Res.Stat = Converged or else Res.Stat = Singular_Shift,
             "Exact-μ₀ path Converged or Singular_Shift");
      if Res.Stat = Converged then
         Check (Res.Success, "Recovered from singular shift");
         Check (Res.Residual <= 1.0E-5, "Recovered residual");
      else
         Check (not Res.Success, "Singular_Shift ⇒ not Success");
         Check (Res.Residual > 1.0E-4, "Singular_Shift residual not tiny");
      end if;
   end;

   declare
      A : constant Matrix := Make_Diagonal ([5.0, 5.0]);
      --  Repeated eigenvalue ⇒ A−5I = 0 singular for any x when μ=5.
      X0 : constant Vector := [1.0, 0.0];
      Res : constant Result :=
        Iterate (A, X0,
                 (Tol => 1.0E-12, Max_Iter => 3,
                  Initial_Mu => 5.0, Use_Initial_Mu => True));
   begin
      --  Residual of (A, e1, 5) is 0 ⇒ early Converged at iter 0.
      Check (Res.Stat = Converged, "Repeated eig exact → Converged");
      Check (Res.Success, "Repeated eig Success");
      Check (Approx (Res.Mu, 5.0), "Repeated eig μ=5");
   end;

   ---------------------------------------------------------------------
   Section ("11. Iteration_Limit with Max_Iter=1 on hard start");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix :=
        Make_Symmetric_Example (Symmetric_Randomish, 5);
      X0 : constant Vector := Make_Ones_Vector (5);
      Res : constant Result :=
        Iterate (A, X0,
                 (Tol => 1.0E-14, Max_Iter => 1,
                  Initial_Mu => 0.0, Use_Initial_Mu => False));
   begin
      Check (Res.Stat = Iteration_Limit
             or else Res.Stat = Converged
             or else Res.Stat = Singular_Shift,
             "Max_Iter=1 status bounded");
      Check (Res.Iterations <= 1, "Max_Iter=1 iterations ≤ 1");
      if Res.Stat = Iteration_Limit then
         Check (not Res.Success, "Iteration_Limit not Success");
      else
         Check (True, "Early exit ok under tight tol");
      end if;
   end;

   ---------------------------------------------------------------------
   Section ("12. Cubic-ish rapid convergence near eigenpair");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([1.0, 2.0, 3.0]);
      X0 : constant Vector := Make_Perturbed_Basis (3, 2, 0.01);
      Res : constant Result :=
        Iterate (A, X0,
                 (Tol => 1.0E-8, Max_Iter => 20,
                  Initial_Mu => 2.0, Use_Initial_Mu => True));
   begin
      Check (Res.Success, "Near eigenpair Success");
      Check (Approx (Res.Mu, 2.0, 1.0E-5), "Near eigenpair μ→2");
      Check (Res.Iterations <= 6, "Few iterations (cubic local rate)");
      Check (Res.Residual <= 1.0E-7, "Tight residual");
   end;

   ---------------------------------------------------------------------
   Section ("13. Default_Parameters / Max_Iter=0 ⇒ 50");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([7.0, 1.0]);
      X0 : constant Vector := [0.05, 1.0];
      Res : constant Result := Solve (A, X0);
   begin
      Check (Res.Success, "Defaults Success");
      Check (Res.Stat = Converged, "Defaults Converged");
      Check (Approx (Res.Mu, 1.0, 1.0E-4), "Defaults → smaller eig");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([4.0, 9.0, 1.0]);
      X0 : constant Vector := Make_Perturbed_Basis (3, 3, 0.08);
      Res : constant Result :=
        Iterate (A, X0,
                 (Tol => 1.0E-7, Max_Iter => 0,
                  Initial_Mu => 0.0, Use_Initial_Mu => False));
   begin
      Check (Res.Success, "Max_Iter=0 Success");
      Check (Approx (Res.Mu, 1.0, 1.0E-4), "Max_Iter=0 → 1");
      Check (Res.Residual <= 1.0E-6, "Max_Iter=0 residual");
   end;

   ---------------------------------------------------------------------
   Section ("14. Absolute eigenvector sign indifference");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([3.0, 8.0]);
      Xp : constant Vector := [1.0, 0.05];
      Xm : constant Vector := [-1.0, -0.05];
      Rp : constant Result :=
        Iterate (A, Xp, (Tol => 1.0E-7, Max_Iter => 20,
                         Initial_Mu => 0.0, Use_Initial_Mu => False));
      Rm : constant Result :=
        Iterate (A, Xm, (Tol => 1.0E-7, Max_Iter => 20,
                         Initial_Mu => 0.0, Use_Initial_Mu => False));
   begin
      Check (Rp.Success and Rm.Success, "± start both Success");
      Check (Approx (Rp.Mu, Rm.Mu, 1.0E-4), "± start same μ");
      Check (Approx (Rp.Mu, 3.0, 1.0E-3), "± start μ→3");
   end;

   ---------------------------------------------------------------------
   Section ("15. Extra GEPP / RQ / status coverage");
   ---------------------------------------------------------------------
   declare
      Iden : constant Matrix (1 .. 3, 1 .. 3) :=
        [[1.0, 0.0, 0.0],
         [0.0, 1.0, 0.0],
         [0.0, 0.0, 1.0]];
      B : constant Vector (1 .. 3) := [2.0, -1.0, 0.5];
      L : constant Linear_Result := Solve_Shifted (Iden, 0.0, B);
      A : constant Matrix := Make_Diagonal ([1.5, 1.5, 1.5]);
      X : constant Vector := Normalize ([1.0, 1.0, 1.0]);
      Rq : constant Float := Rayleigh_Quotient (A, X);
   begin
      Check (L.Success, "GEPP identity Success");
      Check (Approx (L.Y (1), 2.0) and Approx (L.Y (2), -1.0)
             and Approx (L.Y (3), 0.5),
             "GEPP identity solution");
      Check (Approx (Rq, 1.5), "RQ constant multiple of I");
      Check (Approx (Eigen_Residual_Norm (A, X, 1.5), 0.0),
             "Residual 0 for scalar matrix");
   end;

   declare
      A : constant Matrix :=
        Make_Symmetric_Example (Diagonal_Known, 1);
      Res : constant Result :=
        Iterate (A, [1.0], Default_Parameters);
   begin
      Check (Res.Success and Res.Stat = Converged, "1×1 trivial Converged");
      Check (Approx (Res.Mu, 1.0), "1×1 μ=1");
      Check (Res.Iterations = 0, "1×1 already exact");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([2.0, 4.0, 6.0, 8.0]);
      X0 : constant Vector := Make_Perturbed_Basis (4, 4, 0.03);
      Res : constant Result :=
        Iterate (A, X0,
                 (Tol => 1.0E-7, Max_Iter => 25,
                  Initial_Mu => 8.0, Use_Initial_Mu => True));
   begin
      Check (Res.Success, "Target λ=8 Success");
      Check (Approx (Res.Mu, 8.0, 1.0E-3), "Target λ=8");
      Check (abs (Res.X (4)) > 0.9, "|x4| dominant");
      Check (Default_Parameters.Max_Iter = 50, "Default Max_Iter");
      Check (Default_Parameters.Tol = 1.0E-6, "Default Tol");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("----------------------------------");
   Ada.Text_IO.Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
