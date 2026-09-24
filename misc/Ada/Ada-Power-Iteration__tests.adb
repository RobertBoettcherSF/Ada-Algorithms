--  Standalone test suite for Power_Iteration (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics.Elementary_Functions;
with Ada.Text_IO;
with Power_Iteration; use Power_Iteration;

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

   --  Eigenvectors are defined up to sign: accept ± expected.
   function Vec_Near_Up_To_Sign
     (Got, Expected : Vector; Tol : Float := 1.0E-3) return Boolean
   is
   begin
      return Vec_Near (Got, Expected, Tol)
        or else Vec_Near (Got, Scale (Expected, -1.0), Tol);
   end Vec_Near_Up_To_Sign;

begin
   Ada.Text_IO.Put_Line ("Power_Iteration test suite");
   Ada.Text_IO.Put_Line ("==========================");

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
   Section ("4. Builders: Diagonal / Scaled_I / Poisson / Known");
   ---------------------------------------------------------------------
   declare
      D : constant Matrix := Make_Diagonal ([1.0, 3.0, 7.0]);
      Id : constant Matrix := Make_Scaled_Identity (3, 2.5);
      P : constant Matrix := Make_Poisson_1D (4);
      Ks : constant Matrix :=
        Make_Known_Spectrum_Symmetric ([1.0, 2.0, 10.0]);
      Dd : constant Matrix := Make_Example (Diagonal_Dominant, 4);
      Ones : constant Vector := Make_Ones_Vector (3);
      U : constant Vector := Make_Unit_Vector (3, 2);
      Pert : constant Vector := Make_Perturbed_Basis (3, 1, 0.1);
   begin
      Check (Approx (D (1, 1), 1.0) and Approx (D (2, 2), 3.0)
             and Approx (D (3, 3), 7.0),
             "Make_Diagonal diags");
      Check (Approx (D (1, 2), 0.0), "Make_Diagonal off-diag 0");
      Check (Approx (Id (1, 1), 2.5) and Approx (Id (2, 2), 2.5)
             and Approx (Id (1, 2), 0.0),
             "Make_Scaled_Identity");
      Check (Approx (P (1, 1), 2.0) and Approx (P (1, 2), -1.0),
             "Poisson stencil");
      Check (Is_Symmetric (P), "Poisson symmetric");
      Check (Is_Symmetric (Ks), "Known spectrum symmetric");
      Check (Approx (Dd (4, 4), 4.0), "Diagonal_Dominant last");
      Check (Is_Symmetric (Dd), "Diagonal_Dominant symmetric");
      Check (Approx (Ones (2), 1.0), "Make_Ones_Vector");
      Check (Approx (U (2), 1.0) and Approx (U (1), 0.0),
             "Make_Unit_Vector");
      Check (Approx (Norm2 (Pert), 1.0, 1.0E-5), "Perturbed unit");
      Check (Pert (1) > Pert (2), "Perturbed near e1");
      Check (Is_Square (Make_Example (Scaled_Identity, 2)),
             "Example Scaled_Identity square");
      Check (Is_Symmetric (Make_Example (Known_Spectrum_Symmetric, 3)),
             "Example Known_Spectrum symmetric");
   end;

   ---------------------------------------------------------------------
   Section ("5. Clear dominant |λ| on diagonal");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix :=
        Make_Diagonal ([1.0, 2.0, 10.0]);
      X0 : constant Vector := Make_Ones_Vector (3);
      Res : constant Result :=
        Iterate (A, X0, (Tol => 1.0E-7, Max_Iter => 100));
   begin
      Check (Res.Success, "Diag dominant Success");
      Check (Res.Stat = Converged, "Diag dominant Converged");
      Check (Res.N = 3, "Diag dominant N");
      Check (Approx (Res.Eigenvalue, 10.0, 1.0E-4),
             "Diag dominant λ → 10");
      Check (Res.Residual <= 1.0E-5, "Diag dominant residual");
      Check (Approx (Norm2 (Res.Eigenvector (1 .. 3)), 1.0, 1.0E-5),
             "Diag dominant ‖x‖=1");
      Check (abs (Res.Eigenvector (3)) > 0.99,
             "Diag dominant |x3|≈1");
   end;

   declare
      A : constant Matrix :=
        Make_Diagonal ([-8.0, 1.0, 2.0]);
      --  Dominant by magnitude is −8.
      X0 : constant Vector := [1.0, 1.0, 1.0];
      Res : constant Result :=
        Dominant_Eigenpair (A, X0, (Tol => 1.0E-7, Max_Iter => 80));
   begin
      Check (Res.Success, "Neg dominant Success");
      Check (Res.Stat = Converged, "Neg dominant Converged");
      Check (Approx (Res.Eigenvalue, -8.0, 1.0E-3),
             "Neg dominant λ → −8");
      Check (Res.Residual <= 1.0E-4, "Neg dominant residual");
      Check (abs (Res.Eigenvector (1)) > 0.99,
             "Neg dominant |x1|≈1");
   end;

   ---------------------------------------------------------------------
   Section ("6. Sign ambiguity of eigenvector");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([1.0, 5.0]);
      X_Pos : constant Vector := [0.1, 1.0];
      X_Neg : constant Vector := [0.1, -1.0];
      Rp : constant Result :=
        Iterate (A, X_Pos, (Tol => 1.0E-8, Max_Iter => 50));
      Rn : constant Result :=
        Iterate (A, X_Neg, (Tol => 1.0E-8, Max_Iter => 50));
      E2 : constant Vector := Make_Unit_Vector (2, 2);
   begin
      Check (Rp.Success and Rn.Success, "± starts both Success");
      Check (Approx (Rp.Eigenvalue, 5.0, 1.0E-4)
             and Approx (Rn.Eigenvalue, 5.0, 1.0E-4),
             "± starts same λ");
      Check (Vec_Near_Up_To_Sign (Rp.Eigenvector (1 .. 2), E2, 1.0E-2),
             "+ start matches ±e2");
      Check (Vec_Near_Up_To_Sign (Rn.Eigenvector (1 .. 2), E2, 1.0E-2),
             "− start matches ±e2");
      --  The two runs may produce opposite signs relative to each other.
      Check (Approx (abs (Rp.Eigenvector (2)), 1.0, 1.0E-2)
             and Approx (abs (Rn.Eigenvector (2)), 1.0, 1.0E-2),
             "|x2|≈1 either sign");
      Check (Approx (Rp.Eigenvector (2), Rn.Eigenvector (2), 1.0E-2)
             or else Approx (Rp.Eigenvector (2), -Rn.Eigenvector (2),
                             1.0E-2),
             "results agree up to global sign");
   end;

   ---------------------------------------------------------------------
   Section ("7. Residual consistency / RQ match");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Diagonal_Dominant, 5);
      Res : constant Result :=
        Dominant_Eigenpair (A, Params => (Tol => 1.0E-7, Max_Iter => 120));
      Rq : Float;
   begin
      Check (Res.Success, "Default-X0 Success");
      Check (Res.Stat = Converged, "Default-X0 Converged");
      Check (Approx (Res.Eigenvalue, 5.0, 1.0E-3), "Default-X0 λ=5");
      Rq := Rayleigh_Quotient (A, Res.Eigenvector (1 .. 5));
      Check (Approx (Rq, Res.Eigenvalue, 1.0E-5),
             "λ matches RQ of result x");
      Check (Approx (Eigen_Residual_Norm
                       (A, Res.Eigenvector (1 .. 5), Res.Eigenvalue),
                     Res.Residual, 1.0E-5),
             "Residual field matches Eigen_Residual_Norm");
      Check (Res.Residual <= 1.0E-5, "Default-X0 residual small");
   end;

   ---------------------------------------------------------------------
   Section ("8. Scaled identity / Poisson / known spectrum");
   ---------------------------------------------------------------------
   declare
      Id : constant Matrix := Make_Scaled_Identity (4, 3.0);
      X0 : constant Vector := Normalize ([1.0, 2.0, 3.0, 4.0]);
      Res : constant Result :=
        Iterate (Id, X0, (Tol => 1.0E-8, Max_Iter => 10));
   begin
      Check (Res.Success, "Scaled I Success");
      Check (Res.Stat = Converged, "Scaled I Converged");
      Check (Approx (Res.Eigenvalue, 3.0, 1.0E-5), "Scaled I λ=3");
      Check (Res.Residual <= 1.0E-6, "Scaled I residual");
      --  Already an eigenpair after normalize → 0 or 1 iterations.
      Check (Res.Iterations <= 1, "Scaled I ≤1 iter");
   end;

   declare
      P : constant Matrix := Make_Poisson_1D (6);
      --  Ones is orthogonal to the dominant (odd) mode; use alternating start.
      X0 : constant Vector := [1.0, -1.0, 1.0, -1.0, 1.0, -1.0];
      Res : constant Result :=
        Dominant_Eigenpair (P, X0,
                            (Tol => 1.0E-6, Max_Iter => 200));
      --  Exact dominant λ = 2 - 2 cos(6π/7) for N=6.
      Pi : constant Float := 3.14159265;
      Cos_Arg : constant Float :=
        Ada.Numerics.Elementary_Functions.Cos
          (6.0 * Pi / 7.0);
      Lam_Exact : constant Float := 2.0 - 2.0 * Cos_Arg;
   begin
      Check (Res.Success, "Poisson Success");
      Check (Res.Stat = Converged, "Poisson Converged");
      Check (Approx (Res.Eigenvalue, Lam_Exact, 1.0E-3),
             "Poisson λ ≈ exact dominant");
      Check (Res.Residual <= 1.0E-4, "Poisson residual");
      Check (Is_Symmetric (P), "Poisson still symmetric");
   end;

   declare
      Eigs : constant Vector := [0.5, 1.0, 4.0];
      A : constant Matrix := Make_Known_Spectrum_Symmetric (Eigs);
      Res : constant Result :=
        Iterate (A, Make_Ones_Vector (3),
                 (Tol => 1.0E-6, Max_Iter => 150));
   begin
      Check (Res.Success, "Known spectrum Success");
      Check (Res.Stat = Converged, "Known spectrum Converged");
      Check (Approx (Res.Eigenvalue, 4.0, 5.0E-3),
             "Known spectrum λ → 4");
      Check (Res.Residual <= 1.0E-3, "Known spectrum residual");
      Check (Is_Symmetric (A), "Known spectrum matrix symmetric");
   end;

   ---------------------------------------------------------------------
   Section ("9. Ill_Started / Dimension_Error / exact start");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([2.0, 4.0]);
      E : constant Vector := Make_Unit_Vector (2, 2);
      Res : constant Result :=
        Iterate (A, E, (Tol => 1.0E-8, Max_Iter => 10));
   begin
      Check (Res.Success, "Exact start Success");
      Check (Res.Stat = Converged, "Exact start Converged");
      Check (Res.Iterations = 0, "Exact start 0 iters");
      Check (Approx (Res.Eigenvalue, 4.0), "Exact start λ=4");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([1.0, 2.0]);
      Z : constant Vector (1 .. 2) := [0.0, 0.0];
      Res : constant Result := Iterate (A, Z, Default_Parameters);
   begin
      Check (not Res.Success, "Zero start not Success");
      Check (Res.Stat = Ill_Started, "Zero start Ill_Started");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([1.0, 2.0, 3.0]);
      Res : constant Result :=
        Iterate (A, [1.0, 0.0, 0.0],
                 (Tol => -1.0, Max_Iter => 5));
   begin
      Check (Res.Stat = Ill_Started, "Negative Tol Ill_Started");
      Check (not Res.Success, "Negative Tol not Success");
   end;

   declare
      --  Non-square → Dimension_Error via Dominant_Eigenpair (A, Params).
      Bad : constant Matrix (1 .. 2, 1 .. 3) :=
        [[1.0, 0.0, 0.0],
         [0.0, 1.0, 0.0]];
      Res : constant Result := Dominant_Eigenpair (Bad);
   begin
      Check (Res.Stat = Dimension_Error, "Non-square Dimension_Error");
      Check (not Res.Success, "Non-square not Success");
   end;

   declare
      Empty : Matrix (1 .. 0, 1 .. 0);
      Res : constant Result := Dominant_Eigenpair (Empty);
   begin
      Check (Res.Stat = Dimension_Error, "Empty Dimension_Error");
      Check (not Res.Success, "Empty not Success");
   end;

   ---------------------------------------------------------------------
   Section ("10. Iteration_Limit: tight budget / close |λ|");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix :=
        Make_Diagonal ([1.0, 2.0, 3.0, 4.0, 5.0]);
      X0 : constant Vector := Make_Ones_Vector (5);
      Res : constant Result :=
        Iterate (A, X0, (Tol => 1.0E-14, Max_Iter => 1));
   begin
      Check (Res.Stat = Iteration_Limit
             or else Res.Stat = Converged,
             "Max_Iter=1 status bounded");
      Check (Res.Iterations <= 1, "Max_Iter=1 iterations ≤ 1");
      if Res.Stat = Iteration_Limit then
         Check (not Res.Success, "Iteration_Limit not Success");
      else
         Check (True, "Early Converged ok under Max_Iter=1");
      end if;
   end;

   declare
      --  Spectral gap tiny: |λ2/λ1| ≈ 0.99 → slow convergence.
      A : constant Matrix :=
        Make_Diagonal ([1.0, 9.9, 10.0]);
      X0 : constant Vector := [1.0, 1.0, 1.0];
      Res : constant Result :=
        Iterate (A, X0, (Tol => 1.0E-10, Max_Iter => 5));
   begin
      Check (Res.Stat = Iteration_Limit
             or else Res.Stat = Converged,
             "Close |λ| Max_Iter=5 status");
      if Res.Stat = Iteration_Limit then
         Check (not Res.Success, "Close |λ| Iteration_Limit");
         Check (Res.Iterations = 5, "Close |λ| used full budget");
      else
         Check (Res.Success, "Close |λ| lucky Converged");
      end if;
   end;

   declare
      A : constant Matrix :=
        Make_Known_Spectrum_Symmetric ([1.0, 1.05, 1.1]);
      Res : constant Result :=
        Dominant_Eigenpair
          (A, Make_Ones_Vector (3),
           (Tol => 1.0E-12, Max_Iter => 3));
   begin
      Check (Res.Stat = Iteration_Limit
             or else Res.Stat = Converged,
             "Tiny gap Max_Iter=3 status");
      Check (Res.Iterations <= 3, "Tiny gap iters ≤ 3");
      if Res.Stat = Iteration_Limit then
         Check (not Res.Success, "Tiny gap not Success");
      else
         Check (True, "Tiny gap early exit");
      end if;
   end;

   ---------------------------------------------------------------------
   Section ("11. Alias Dominant_Eigenpair / defaults / 1×1");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([7.0, 1.0]);
      X0 : constant Vector := [1.0, 0.5];
      R1 : constant Result := Iterate (A, X0, Default_Parameters);
      R2 : constant Result :=
        Dominant_Eigenpair (A, X0, Default_Parameters);
   begin
      Check (R1.Success and R2.Success, "Alias both Success");
      Check (Approx (R1.Eigenvalue, R2.Eigenvalue, 1.0E-6),
             "Alias same λ");
      Check (Approx (R1.Eigenvalue, 7.0, 1.0E-3), "Alias λ=7");
      Check (Default_Parameters.Max_Iter = 200, "Default Max_Iter");
      Check (Default_Parameters.Tol = 1.0E-6, "Default Tol");
      Check (Dimension'Last = Max_N, "Dimension'Last = Max_N");
   end;

   declare
      A : constant Matrix := Make_Example (Diagonal_Dominant, 1);
      Res : constant Result :=
        Iterate (A, [1.0], Default_Parameters);
   begin
      Check (Res.Success and Res.Stat = Converged, "1×1 Converged");
      Check (Approx (Res.Eigenvalue, 1.0), "1×1 λ=1");
      Check (Res.Iterations = 0, "1×1 already exact");
   end;

   ---------------------------------------------------------------------
   Section ("12. Larger diagonal gap / component checks");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix :=
        Make_Diagonal ([0.1, 0.2, 0.3, 0.4, 0.5, 8.0]);
      Res : constant Result :=
        Dominant_Eigenpair (A, Params => (Tol => 1.0E-7, Max_Iter => 80));
   begin
      Check (Res.Success, "6×6 gap Success");
      Check (Approx (Res.Eigenvalue, 8.0, 1.0E-3), "6×6 λ=8");
      Check (abs (Res.Eigenvector (6)) > 0.99, "6×6 |x6|≈1");
      Check (Res.Residual <= 1.0E-5, "6×6 residual");
      Check (Res.Iterations <= 80,
             "6×6 iterations within budget");
   end;

   declare
      A : constant Matrix := Make_Example (Poisson_1D, 8);
      Res : constant Result :=
        Iterate (A, Make_Perturbed_Basis (8, 1, 0.2),
                 (Tol => 1.0E-5, Max_Iter => 250));
   begin
      Check (Res.Success, "Poisson8 Success");
      Check (Res.Stat = Converged, "Poisson8 Converged");
      Check (Res.Eigenvalue > 3.5 and Res.Eigenvalue < 4.0,
             "Poisson8 λ in (3.5, 4)");
      Check (Res.Residual <= 1.0E-4, "Poisson8 residual");
   end;

   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[2.0, 1.0],
         [1.0, 2.0]];
      --  Eigenvalues 3 and 1; dominant 3 with eigenvector (1,1)/√2.
      Res : constant Result :=
        Iterate (A, [1.0, 0.0], (Tol => 1.0E-7, Max_Iter => 60));
      Expected : constant Vector :=
        Normalize ([1.0, 1.0]);
   begin
      Check (Res.Success, "2×2 SPD Success");
      Check (Approx (Res.Eigenvalue, 3.0, 1.0E-4), "2×2 λ=3");
      Check (Vec_Near_Up_To_Sign
               (Res.Eigenvector (1 .. 2), Expected, 1.0E-3),
             "2×2 eigenvector ±(1,1)/√2");
      Check (Res.Residual <= 1.0E-5, "2×2 residual");
   end;

   ---------------------------------------------------------------------
   Section ("13. Extra helpers / Example_Kind coverage");
   ---------------------------------------------------------------------
   declare
      Si : constant Matrix := Make_Example (Scaled_Identity, 5);
      Dd : constant Matrix := Make_Example (Diagonal_Dominant, 3);
      Ks : constant Matrix :=
        Make_Example (Known_Spectrum_Symmetric, 4);
      P  : constant Matrix := Make_Example (Poisson_1D, 3);
   begin
      Check (Approx (Si (3, 3), 1.0), "Example Scaled_I diag");
      Check (Approx (Dd (2, 2), 2.0), "Example Diag_Dom mid");
      Check (Is_Symmetric (Ks), "Example KS symmetric");
      Check (Approx (P (2, 1), -1.0) and Approx (P (2, 3), -1.0),
             "Example Poisson off-diags");
      Check (Approx (Norm2 (Make_Unit_Vector (4, 3)), 1.0),
             "Unit vector norm");
      Check (Approx (Dot (Make_Ones_Vector (2), Make_Ones_Vector (2)),
                     2.0),
             "Ones Dot");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([9.0, -0.5, 0.25]);
      Res : constant Result :=
        Dominant_Eigenpair (A, Make_Perturbed_Basis (3, 1, 0.05),
                            (Tol => 1.0E-8, Max_Iter => 40));
   begin
      Check (Res.Success, "Mixed-sign spectrum Success");
      Check (Approx (Res.Eigenvalue, 9.0, 1.0E-3),
             "Mixed-sign dominant 9");
      Check (abs (Res.Eigenvector (1)) > 0.98,
             "Mixed-sign |x1|");
   end;

   declare
      A : constant Matrix := Make_Scaled_Identity (2, -4.0);
      Res : constant Result :=
        Iterate (A, [0.0, 1.0], Default_Parameters);
   begin
      Check (Res.Success, "Neg scaled I Success");
      Check (Approx (Res.Eigenvalue, -4.0, 1.0E-5),
             "Neg scaled I λ=-4");
      Check (Res.Residual <= 1.0E-6, "Neg scaled I residual");
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
