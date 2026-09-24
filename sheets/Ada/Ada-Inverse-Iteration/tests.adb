--  Standalone test suite for Inverse_Iteration (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Inverse_Iteration; use Inverse_Iteration;

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
   Ada.Text_IO.Put_Line ("Inverse_Iteration test suite");
   Ada.Text_IO.Put_Line ("============================");

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
   Section ("4. Builders: Diagonal / Poisson / Known spectrum");
   ---------------------------------------------------------------------
   declare
      D : constant Matrix := Make_Diagonal ([1.0, 3.0, 7.0]);
      Dk : constant Matrix := Make_Example (Diagonal_Known, 4);
      P : constant Matrix := Make_Poisson_1D (4);
      Ks : constant Matrix :=
        Make_Known_Spectrum_Symmetric ([2.0, 5.0, 9.0]);
      Ex : constant Matrix := Make_Example (Known_Spectrum_Symmetric, 3);
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
      Check (Is_Symmetric (Ks), "Known_Spectrum symmetric");
      Check (Is_Symmetric (Ex), "Example Known_Spectrum symmetric");
      Check (Approx (Ones (2), 1.0), "Make_Ones_Vector");
      Check (Approx (U (2), 1.0) and Approx (U (1), 0.0),
             "Make_Unit_Vector");
      Check (Approx (Norm2 (Pert), 1.0, 1.0E-5), "Perturbed unit");
      Check (Pert (1) > Pert (2), "Perturbed near e1");
      Check (Is_Symmetric (Make_Example (Poisson_1D, 5)),
             "Example Poisson symmetric");
   end;

   ---------------------------------------------------------------------
   Section ("5. Solve_Shifted GEPP on well-conditioned system");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[4.0, 1.0],
         [1.0, 3.0]];
      B : constant Vector (1 .. 2) := [5.0, 4.0];
      L : constant Linear_Result := Solve_Shifted (A, 0.0, B);
   begin
      Check (L.Success, "Solve_Shifted Success");
      Check (L.Stat = Ok, "Solve_Shifted Ok");
      Check (Approx (L.Y (1), 1.0, 1.0E-5), "Solve_Shifted y1");
      Check (Approx (L.Y (2), 1.0, 1.0E-5), "Solve_Shifted y2");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([2.0, 4.0, 6.0]);
      X : constant Vector := [1.0, 1.0, 1.0];
      --  (A − 1·I) y = x ⇒ y = [1, 1/3, 1/5]
      L : constant Linear_Result := Solve_Shifted (A, 1.0, X);
   begin
      Check (L.Success, "Diag shift Success");
      Check (Approx (L.Y (1), 1.0, 1.0E-5), "Diag shift y1");
      Check (Approx (L.Y (2), 1.0 / 3.0, 1.0E-5), "Diag shift y2");
      Check (Approx (L.Y (3), 1.0 / 5.0, 1.0E-5), "Diag shift y3");
   end;

   ---------------------------------------------------------------------
   Section ("6. Shift near known λ on diagonal");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix :=
        Make_Diagonal ([1.0, 2.0, 3.0, 4.0]);
      X0 : constant Vector := Make_Ones_Vector (4);
      Res : constant Result :=
        Eigenpair_Near
          (A, 2.1, X0,
           (Tol => 1.0E-7, Max_Iter => 40, Mu => 0.0));
   begin
      Check (Res.Success, "Near λ=2 Success");
      Check (Res.Stat = Converged, "Near λ=2 Converged");
      Check (Res.N = 4, "Near λ=2 N");
      Check (Approx (Res.Eigenvalue, 2.0, 1.0E-4), "Near λ=2 eigenvalue");
      Check (Approx (Res.Mu, 2.1), "Near λ=2 Mu echoed");
      Check (Res.Residual <= 1.0E-5, "Near λ=2 residual");
      Check (abs (Res.Eigenvector (2)) > 0.9, "|x2| dominant");
      Check (Approx (Norm2 (Res.Eigenvector (1 .. 4)), 1.0, 1.0E-5),
             "Near λ=2 ‖x‖=1");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([10.0, -2.0, 0.5]);
      X0 : constant Vector := Make_Ones_Vector (3);
      Res : constant Result :=
        Iterate (A, X0,
                 (Tol => 1.0E-8, Max_Iter => 50, Mu => 9.7));
   begin
      Check (Res.Success, "Iterate μ=9.7 Success");
      Check (Res.Stat = Converged, "Iterate μ=9.7 Converged");
      Check (Approx (Res.Eigenvalue, 10.0, 1.0E-3), "Iterate → 10");
      Check (Res.Residual <= 1.0E-6, "Iterate residual");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([-3.0, 1.0]);
      X0 : constant Vector := [1.0, 1.0];
      Res : constant Result :=
        Eigenpair_Near
          (A, -2.8, X0,
           (Tol => 1.0E-8, Max_Iter => 30, Mu => 0.0));
   begin
      Check (Res.Success, "2×2 neg Success");
      Check (Approx (Res.Eigenvalue, -3.0, 1.0E-4), "2×2 → -3");
      Check (Res.Residual <= 1.0E-5, "2×2 residual");
   end;

   ---------------------------------------------------------------------
   Section ("7. Interior / smallest eigenvalue vs power contrast");
   ---------------------------------------------------------------------
   --  On diag(1,2,10), power finds 10; inverse with μ≈1 finds 1.
   declare
      A : constant Matrix := Make_Diagonal ([1.0, 2.0, 10.0]);
      X0 : constant Vector := Make_Ones_Vector (3);
      Inv : constant Result :=
        Eigenpair_Near
          (A, 1.05, X0,
           (Tol => 1.0E-7, Max_Iter => 40, Mu => 0.0));
      --  Simulated power: largest |λ| is 10; inverse near 1 should not.
   begin
      Check (Inv.Success, "Interior Success");
      Check (Approx (Inv.Eigenvalue, 1.0, 1.0E-3), "Interior → 1 (not 10)");
      Check (abs (Inv.Eigenvalue - 10.0) > 5.0,
             "Interior far from dominant 10");
      Check (abs (Inv.Eigenvector (1)) > 0.9, "Interior evec ~ e1");
      Check (Inv.Residual <= 1.0E-5, "Interior residual");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([0.5, 3.0, 8.0, 12.0]);
      X0 : constant Vector := Make_Ones_Vector (4);
      Small : constant Result :=
        Eigenpair_Near
          (A, 0.4, X0,
           (Tol => 1.0E-7, Max_Iter => 50, Mu => 0.0));
      Dom : constant Result :=
        Eigenpair_Near
          (A, 11.5, X0,
           (Tol => 1.0E-7, Max_Iter => 50, Mu => 0.0));
   begin
      Check (Small.Success and Dom.Success, "Small+Dom Success");
      Check (Approx (Small.Eigenvalue, 0.5, 1.0E-3), "μ≈0.4 → 0.5");
      Check (Approx (Dom.Eigenvalue, 12.0, 1.0E-3), "μ≈11.5 → 12");
      Check (abs (Small.Eigenvalue - Dom.Eigenvalue) > 5.0,
             "Different targets (vs power contrast)");
   end;

   ---------------------------------------------------------------------
   Section ("8. Poisson / Known_Spectrum residuals");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Poisson_1D (5);
      --  λ_k = 2-2cos(kπ/6); smallest ≈ 2-2cos(π/6) ≈ 0.2679
      X0 : constant Vector := Make_Ones_Vector (5);
      Res : constant Result :=
        Eigenpair_Near
          (A, 0.3, X0,
           (Tol => 1.0E-6, Max_Iter => 60, Mu => 0.0));
      Rq : Float;
   begin
      Check (Res.Success, "Poisson Success");
      Check (Res.Stat = Converged, "Poisson Converged");
      Rq := Rayleigh_Quotient (A, Res.Eigenvector (1 .. 5));
      Check (Approx (Rq, Res.Eigenvalue, 1.0E-4),
             "λ matches RQ of result x");
      Check (Approx (Eigen_Residual_Norm
                       (A, Res.Eigenvector (1 .. 5), Res.Eigenvalue),
                     Res.Residual, 1.0E-5),
             "Residual field matches Eigen_Residual_Norm");
      Check (Res.Residual <= 1.0E-5, "Poisson residual small");
      Check (Res.Eigenvalue > 0.0 and Res.Eigenvalue < 1.0,
             "Poisson near smallest λ");
   end;

   declare
      A : constant Matrix :=
        Make_Known_Spectrum_Symmetric ([1.0, 4.0, 7.0]);
      X0 : constant Vector := Make_Ones_Vector (3);
      Res : constant Result :=
        Eigenpair_Near
          (A, 4.1, X0,
           (Tol => 1.0E-6, Max_Iter => 50, Mu => 0.0));
   begin
      Check (Res.Success, "Known spectrum Success");
      Check (Approx (Res.Eigenvalue, 4.0, 5.0E-3), "Known spectrum → 4");
      Check (Res.Residual <= 1.0E-4, "Known spectrum residual");
      Check (Is_Symmetric (A), "Known spectrum A symmetric");
   end;

   ---------------------------------------------------------------------
   Section ("9. Singular μ≈λ / Ill_Started / bad dims");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([1.0, 2.0]);
      E1 : constant Vector := Make_Unit_Vector (2, 1);
      L : constant Linear_Result := Solve_Shifted (A, 1.0, E1);
   begin
      Check (not L.Success, "Solve_Shifted singular not Success");
      Check (L.Stat = Singular or else L.Stat = Zero_Pivot,
             "Solve_Shifted Singular/Zero_Pivot");
   end;

   --  Exact eigenpair start: residual 0 → Converged at iter 0
   declare
      A : constant Matrix := Make_Diagonal ([2.0, 4.0]);
      E : constant Vector := Make_Unit_Vector (2, 1);
      Res : constant Result :=
        Iterate (A, E, (Tol => 1.0E-8, Max_Iter => 10, Mu => 2.0));
   begin
      Check (Res.Success, "Exact start Success");
      Check (Res.Stat = Converged, "Exact start Converged");
      Check (Res.Iterations = 0, "Exact start 0 iters");
      Check (Approx (Res.Eigenvalue, 2.0), "Exact start λ=2");
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
      Res : constant Result :=
        Iterate (A, [1.0, 0.0, 0.0],
                 (Tol => -1.0, Max_Iter => 5, Mu => 1.0));
   begin
      Check (Res.Stat = Ill_Started, "Negative Tol Ill_Started");
      Check (not Res.Success, "Negative Tol not Success");
   end;

   --  Non-square via Eigenpair_Near without X0
   declare
      Bad : constant Matrix (1 .. 2, 1 .. 3) :=
        [[1.0, 0.0, 0.0],
         [0.0, 1.0, 0.0]];
      Res : constant Result :=
        Eigenpair_Near (Bad, 1.0, Default_Parameters);
   begin
      Check (Res.Stat = Dimension_Error, "Non-square Dimension_Error");
      Check (not Res.Success, "Non-square not Success");
   end;

   declare
      Empty : constant Matrix (1 .. 0, 1 .. 0) :=
        [1 .. 0 => [1 .. 0 => 0.0]];
      Res : constant Result :=
        Eigenpair_Near (Empty, Default_Parameters);
   begin
      Check (Res.Stat = Dimension_Error, "Empty Dimension_Error");
      Check (not Res.Success, "Empty not Success");
   end;

   --  Exact μ = λ with non-eigenvector start: may Converged (perturb)
   --  or Singular_Shift
   declare
      A : constant Matrix := Make_Diagonal ([1.0, 2.0, 3.0]);
      X0 : constant Vector := Make_Ones_Vector (3);
      Res : constant Result :=
        Iterate (A, X0,
                 (Tol => 1.0E-8, Max_Iter => 30, Mu => 2.0));
   begin
      Check (Res.Stat = Converged or else Res.Stat = Singular_Shift,
             "Exact-μ path Converged or Singular_Shift");
      if Res.Stat = Converged then
         Check (Res.Success, "Recovered from singular shift");
         Check (Approx (Res.Eigenvalue, 2.0, 1.0E-2),
                "Recovered λ≈2");
      else
         Check (not Res.Success, "Singular_Shift ⇒ not Success");
      end if;
   end;

   ---------------------------------------------------------------------
   Section ("10. Iteration_Limit / Defaults / Max_Iter=0");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([1.0, 1.01, 1.02, 1.03]);
      X0 : constant Vector := Make_Ones_Vector (4);
      Res : constant Result :=
        Iterate (A, X0,
                 (Tol => 1.0E-14, Max_Iter => 1, Mu => 1.0));
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

   declare
      A : constant Matrix := Make_Diagonal ([7.0, 1.0]);
      X0 : constant Vector := [1.0, 1.0];
      Res : constant Result :=
        Iterate (A, X0, (Tol => 1.0E-6, Max_Iter => 100, Mu => 1.1));
   begin
      Check (Res.Success, "Near-1 Defaults-style Success");
      Check (Approx (Res.Eigenvalue, 1.0, 1.0E-3), "Near-1 → 1");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([4.0, 9.0, 1.0]);
      X0 : constant Vector := Make_Ones_Vector (3);
      Res : constant Result :=
        Iterate (A, X0,
                 (Tol => 1.0E-7, Max_Iter => 0, Mu => 1.05));
   begin
      Check (Res.Success, "Max_Iter=0 Success");
      Check (Approx (Res.Eigenvalue, 1.0, 1.0E-3), "Max_Iter=0 → 1");
      Check (Res.Residual <= 1.0E-5, "Max_Iter=0 residual");
   end;

   ---------------------------------------------------------------------
   Section ("11. Eigenpair_Near overloads / sign indifference");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([3.0, 8.0]);
      Rp : constant Result :=
        Eigenpair_Near
          (A, 3.1, [1.0, 0.05],
           (Tol => 1.0E-7, Max_Iter => 30, Mu => 0.0));
      Rm : constant Result :=
        Eigenpair_Near
          (A, 3.1, [-1.0, -0.05],
           (Tol => 1.0E-7, Max_Iter => 30, Mu => 0.0));
      Rd : constant Result :=
        Eigenpair_Near
          (A      => A,
           Mu     => 7.9,
           Params => (Tol => 1.0E-7, Max_Iter => 40, Mu => 0.0));
      Rp2 : constant Result :=
        Eigenpair_Near
          (A      => A,
           Params => (Tol => 1.0E-7, Max_Iter => 40, Mu => 3.05));
   begin
      Check (Rp.Success and Rm.Success, "± start both Success");
      Check (Approx (Rp.Eigenvalue, Rm.Eigenvalue, 1.0E-4),
             "± start same λ");
      Check (Approx (Rp.Eigenvalue, 3.0, 1.0E-3), "± start λ→3");
      Check (Rd.Success, "Default ones → near 8 Success");
      Check (Approx (Rd.Eigenvalue, 8.0, 1.0E-3), "Default ones → 8");
      Check (Rp2.Success, "Params.Mu overload Success");
      Check (Approx (Rp2.Eigenvalue, 3.0, 1.0E-3), "Params.Mu → 3");
      Check (Approx (Rp2.Mu, 3.05), "Params.Mu echoed");
   end;

   ---------------------------------------------------------------------
   Section ("12. Extra GEPP / RQ / 1×1 / defaults");
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
      A : constant Matrix := Make_Example (Diagonal_Known, 1);
      Res : constant Result :=
        Eigenpair_Near (A, 1.0, [1.0], Default_Parameters);
   begin
      Check (Res.Success and Res.Stat = Converged, "1×1 trivial Converged");
      Check (Approx (Res.Eigenvalue, 1.0), "1×1 λ=1");
      Check (Res.Iterations = 0, "1×1 already exact");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([2.0, 4.0, 6.0, 8.0]);
      X0 : constant Vector := Make_Perturbed_Basis (4, 4, 0.05);
      Res : constant Result :=
        Eigenpair_Near
          (A, 7.9, X0,
           (Tol => 1.0E-7, Max_Iter => 40, Mu => 0.0));
   begin
      Check (Res.Success, "Target λ=8 Success");
      Check (Approx (Res.Eigenvalue, 8.0, 1.0E-3), "Target λ=8");
      Check (abs (Res.Eigenvector (4)) > 0.9, "|x4| dominant");
      Check (Default_Parameters.Max_Iter = 100, "Default Max_Iter");
      Check (Default_Parameters.Tol = 1.0E-6, "Default Tol");
      Check (Default_Parameters.Mu = 0.0, "Default Mu");
      Check (Res.Mu = 7.9, "Result Mu echoed from call");
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
