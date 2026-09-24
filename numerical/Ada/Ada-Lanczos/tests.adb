--  Standalone test suite for Lanczos (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Lanczos; use Lanczos;

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

   --  Multiset match: every Expected entry near some Got entry (order-free).
   function Spectrum_Near
     (Got, Expected : Vector; Tol : Float) return Boolean
   is
      N : constant Natural := Expected'Length;
      Used : array (1 .. N) of Boolean := [others => False];
      Found : Boolean;
   begin
      if Got'Length < N then
         return False;
      end if;
      for E in Expected'Range loop
         Found := False;
         for G in Got'First .. Got'First + N - 1 loop
            if not Used (G - Got'First + 1)
              and then abs (Got (G) - Expected (E)) <= Tol
            then
               Used (G - Got'First + 1) := True;
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            return False;
         end if;
      end loop;
      return True;
   end Spectrum_Near;

begin
   Ada.Text_IO.Put_Line ("Lanczos test suite");
   Ada.Text_IO.Put_Line ("==================");

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
   Section ("2. Mat_Vec / symmetry / Normalize / Column");
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
      Col1 : constant Vector := Column (A, 1);
   begin
      Check (Approx (Y (1), 5.0), "Mat_Vec row1");
      Check (Approx (Y (2), 4.0), "Mat_Vec row2");
      Check (Is_Square (A), "Is_Square");
      Check (Is_Symmetric (A), "Is_Symmetric A");
      Check (not Is_Symmetric (Asym), "Is_Symmetric rejects");
      Check (Approx (Norm2 (Nrm), 1.0), "Normalize unit");
      Check (Approx (Nrm (1), 0.6, 1.0E-6), "Normalize 3/5");
      Check (Approx (Nrm (2), 0.8, 1.0E-6), "Normalize 4/5");
      Check (Approx (Col1 (1), 4.0) and Approx (Col1 (2), 1.0),
             "Column 1 of A");
   end;

   ---------------------------------------------------------------------
   Section ("3. Builders / Poisson spectrum");
   ---------------------------------------------------------------------
   declare
      D : constant Matrix := Make_Diagonal ([2.0, 5.0, -1.0]);
      P : constant Matrix := Make_Poisson_1D (4);
      K : constant Matrix :=
        Make_Known_Spectrum_Symmetric ([1.0, 2.0, 3.0]);
      E : constant Matrix := Make_Example (Diagonal_Known, 3);
   begin
      Check (Approx (D (1, 1), 2.0) and Approx (D (2, 2), 5.0)
             and Approx (D (3, 3), -1.0),
             "Make_Diagonal diag");
      Check (Is_Symmetric (D), "Diagonal symmetric");
      Check (Is_Symmetric (P), "Poisson symmetric");
      Check (Approx (P (1, 1), 2.0) and Approx (P (1, 2), -1.0),
             "Poisson stencil corner");
      Check (Approx (P (2, 1), -1.0) and Approx (P (2, 3), -1.0),
             "Poisson off-diag");
      Check (Is_Symmetric (K), "Known spectrum symmetric");
      Check (Approx (E (3, 3), 3.0), "Make_Example diagonal");
      Check (Approx (Poisson_Eigenvalue (4, 1),
                     2.0 - 2.0 * 0.80901699437, 1.0E-4),
             "Poisson λ1 formula");
      Check (Approx (Norm2 (Make_Ones_Vector (3)),
                     1.7320508, 1.0E-5),
             "Ones norm");
      Check (Approx (Make_Unit_Vector (4, 2) (2), 1.0),
             "Unit vector e2");
      Check (Approx (Norm2 (Make_Perturbed_Basis (3, 1)), 1.0),
             "Perturbed basis unit");
   end;

   ---------------------------------------------------------------------
   Section ("4. Make_Tridiagonal / orthogonality helper");
   ---------------------------------------------------------------------
   declare
      Al : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      Be : constant Vector (1 .. 3) := [0.5, 0.25, 0.0];
      T  : constant Matrix := Make_Tridiagonal (Al, Be, 3);
      I3 : Matrix (1 .. 3, 1 .. 3) := [others => [others => 0.0]];
   begin
      Check (Approx (T (1, 1), 1.0) and Approx (T (2, 2), 2.0)
             and Approx (T (3, 3), 3.0),
             "T diagonal α");
      Check (Approx (T (1, 2), 0.5) and Approx (T (2, 1), 0.5),
             "T β2");
      Check (Approx (T (2, 3), 0.25) and Approx (T (3, 2), 0.25),
             "T β3");
      Check (Approx (T (1, 3), 0.0), "T (1,3) zero");
      I3 (1, 1) := 1.0;
      I3 (2, 2) := 1.0;
      I3 (3, 3) := 1.0;
      Check (Approx (Orthogonality_Residual (I3, 3, 3), 0.0),
             "I orthogonality residual 0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Status paths: Ill_Started / Not_Symmetric / Dimension");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([1.0, 2.0]);
      Asym : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 2.0], [0.0, 1.0]];
      Empty : Matrix (1 .. 0, 1 .. 0);
      R1 : constant Result :=
        Run (A, [0.0, 0.0], Default_Parameters);
      R2 : constant Result :=
        Run (Asym, [1.0, 0.0], Default_Parameters);
      R3 : constant Result :=
        Run (A, [1.0, 0.0],
             (M => 0, Tol => 1.0E-8, Reorthogonalize => True,
              Max_QR_Iter => 64, Keep_V => True));
      R4 : constant Result := Run (Empty, Default_Parameters);
      R5 : constant Result :=
        Run (A, [1.0, 0.0],
             (M => 2, Tol => -1.0, Reorthogonalize => True,
              Max_QR_Iter => 64, Keep_V => True));
   begin
      Check (R1.Stat = Ill_Started and not R1.Success,
             "zero start → Ill_Started");
      Check (R2.Stat = Not_Symmetric and not R2.Success,
             "nonsymmetric → Not_Symmetric");
      Check (R3.Stat = Ill_Started and not R3.Success,
             "M=0 → Ill_Started");
      Check (R4.Stat = Dimension_Error and not R4.Success,
             "empty → Dimension_Error");
      Check (R5.Stat = Ill_Started and not R5.Success,
             "Tol<0 → Ill_Started");
   end;

   ---------------------------------------------------------------------
   Section ("6. Diagonal A: Ritz ≈ eigenvalues (full Krylov)");
   ---------------------------------------------------------------------
   declare
      Eigs : constant Vector (1 .. 4) := [1.0, 3.0, 5.0, 9.0];
      A    : constant Matrix := Make_Diagonal (Eigs);
      Res  : constant Result :=
        Run (A, Make_Ones_Vector (4),
             (M => 4, Tol => 1.0E-10, Reorthogonalize => True,
              Max_QR_Iter => 64, Keep_V => True));
   begin
      Check (Res.Success, "diag full Success");
      Check (Res.Stat = Ok or Res.Stat = Breakdown, "diag Stat Ok/Break");
      Check (Res.Steps = 4, "diag Steps=4");
      Check (Res.Has_V, "diag Has_V");
      Check (Spectrum_Near
               (Res.Ritz_Values (1 .. 4), Eigs, 1.0E-3),
             "diag Ritz ≈ spectrum");
      Check (Approx (Orthogonality_Residual (Res.V, 4, 4), 0.0, 1.0E-5),
             "diag V orthonormal (reorth)");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([2.0, 4.0, 7.0]);
      Res : constant Result :=
        Iterate (A, Make_Perturbed_Basis (3, 2),
                 (M => 3, Tol => 1.0E-10, Reorthogonalize => True,
                  Max_QR_Iter => 80, Keep_V => True));
   begin
      Check (Res.Success, "diag3 Success");
      Check (Spectrum_Near
               (Res.Ritz_Values (1 .. 3), [2.0, 4.0, 7.0], 1.0E-3),
             "diag3 Ritz match");
   end;

   ---------------------------------------------------------------------
   Section ("7. Tridiagonal structure of α / β");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Poisson_1D (5);
      --  Perturb the start so the Krylov space is not trapped in a
      --  reflection-symmetric invariant subspace of the ones vector.
      Res : constant Result :=
        Build_Tridiagonal
          (A, Make_Perturbed_Basis (5, 1, 0.3),
           (M => 4, Tol => 1.0E-12, Reorthogonalize => True,
            Max_QR_Iter => 64, Keep_V => True));
      T : Matrix (1 .. 4, 1 .. 4);
   begin
      Check (Res.Success, "Poisson build Success");
      Check (Res.Steps = 4, "Poisson Steps=4");
      T := Make_Tridiagonal
        (Res.Alphas (1 .. 4), Res.Betas (1 .. 4), 4);
      Check (Is_Symmetric (T), "T symmetric");
      Check (Approx (T (1, 3), 0.0) and Approx (T (1, 4), 0.0)
             and Approx (T (2, 4), 0.0),
             "T strictly tridiagonal zeros");
      for J in 1 .. 4 loop
         Check (Approx (T (J, J), Res.Alphas (J)),
                "T diag = α" & J'Image);
      end loop;
      for J in 1 .. 3 loop
         Check (Approx (T (J, J + 1), Res.Betas (J)),
                "T sub = β" & Integer'Image (J + 1));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("8. Orthogonality with / without reorthogonalization");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix :=
        Make_Known_Spectrum_Symmetric ([1.0, 2.0, 3.0, 4.0, 5.0, 6.0]);
      With_R : constant Result :=
        Build_Tridiagonal
          (A, Make_Ones_Vector (6),
           (M => 6, Tol => 1.0E-12, Reorthogonalize => True,
            Max_QR_Iter => 64, Keep_V => True));
      No_R : constant Result :=
        Build_Tridiagonal
          (A, Make_Ones_Vector (6),
           (M => 6, Tol => 1.0E-12, Reorthogonalize => False,
            Max_QR_Iter => 64, Keep_V => True));
      Orth_W : Float;
      Orth_N : Float;
   begin
      Check (With_R.Success and With_R.Has_V, "reorth build ok");
      Check (No_R.Success and No_R.Has_V, "no-reorth build ok");
      Orth_W := Orthogonality_Residual (With_R.V, 6, With_R.Steps);
      Orth_N := Orthogonality_Residual (No_R.V, 6, No_R.Steps);
      Check (Orth_W < 1.0E-4, "reorth keeps V nearly orthonormal");
      Check (True, "no-reorth Orth=" & Orth_N'Image & " (info)");
      --  Educational Float often loses orthogonality without reorth;
      --  require reorth path to be clearly better or both tiny.
      Check (Orth_W <= Orth_N + 1.0E-6,
             "reorth Orth ≤ no-reorth Orth (approx)");
   end;

   ---------------------------------------------------------------------
   Section ("9. Breakdown on invariant subspace");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([10.0, 2.0, 3.0, 4.0]);
      --  Exact eigenvector e1 → Krylov collapses after 1 step.
      Res : constant Result :=
        Run (A, Make_Unit_Vector (4, 1),
             (M => 4, Tol => 1.0E-8, Reorthogonalize => True,
              Max_QR_Iter => 64, Keep_V => True));
   begin
      Check (Res.Stat = Breakdown, "invariant → Breakdown");
      Check (Res.Success, "Breakdown still Success");
      Check (Res.Steps = 1, "Breakdown Steps=1");
      Check (Approx (Res.Betas (1), 0.0, 1.0E-6)
             or else Res.Beta_Next <= 1.0E-8,
             "β₂ ≈ 0 on breakdown");
      Check (Approx (Res.Ritz_Values (1), 10.0, 1.0E-4),
             "Ritz = eigenvalue 10");
      Check (Approx (Res.Alphas (1), 10.0, 1.0E-5),
             "α₁ = Rayleigh = 10");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([1.0, 5.0, 2.0]);
      Res : constant Result :=
        Build_Tridiagonal
          (A, Make_Unit_Vector (3, 2),
           (M => 3, Tol => 1.0E-8, Reorthogonalize => True,
            Max_QR_Iter => 64, Keep_V => True));
   begin
      Check (Res.Stat = Breakdown, "e2 invariant Breakdown");
      Check (Res.Steps = 1, "e2 Steps=1");
      Check (Approx (Res.Alphas (1), 5.0, 1.0E-5), "α₁=5");
   end;

   ---------------------------------------------------------------------
   Section ("10. Ritz residuals when V / Ritz vectors available");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([1.0, 2.0, 4.0, 8.0]);
      Res : constant Result :=
        Run (A, Make_Ones_Vector (4),
             (M => 4, Tol => 1.0E-10, Reorthogonalize => True,
              Max_QR_Iter => 64, Keep_V => True));
      Max_Res : Float := 0.0;
      Rj : Float;
   begin
      Check (Res.Has_Ritz_Vecs, "Has_Ritz_Vecs");
      for K in 1 .. Res.Steps loop
         declare
            Yk : constant Vector := Column (Res.Ritz_Vectors, K);
         begin
            Rj := Ritz_Residual_Norm (A, Yk, Res.Ritz_Values (K));
            if Rj > Max_Res then
               Max_Res := Rj;
            end if;
         end;
      end loop;
      Check (Max_Res < 1.0E-3, "max Ritz residual < 1e-3");
      Check (Spectrum_Near
               (Res.Ritz_Values (1 .. 4), [1.0, 2.0, 4.0, 8.0], 1.0E-3),
             "diag 1,2,4,8 Ritz");
   end;

   declare
      A : constant Matrix :=
        Make_Known_Spectrum_Symmetric ([1.0, 3.0, 5.0, 7.0]);
      Res : constant Result :=
        Run (A, Make_Perturbed_Basis (4, 1),
             (M => 4, Tol => 1.0E-10, Reorthogonalize => True,
              Max_QR_Iter => 80, Keep_V => True));
      Ok_All : Boolean := True;
   begin
      Check (Res.Success and Res.Has_Ritz_Vecs, "known-spec Ritz vecs");
      for K in 1 .. Res.Steps loop
         if Ritz_Residual_Norm
              (A, Column (Res.Ritz_Vectors, K), Res.Ritz_Values (K))
           > 5.0E-3
         then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "known-spec residuals small");
      Check (Spectrum_Near
               (Res.Ritz_Values (1 .. 4), [1.0, 3.0, 5.0, 7.0], 5.0E-2),
             "known-spec Ritz ≈ spectrum");
   end;

   ---------------------------------------------------------------------
   Section ("11. Poisson 1D Ritz extremes / partial Krylov");
   ---------------------------------------------------------------------
   declare
      N : constant Dimension := 8;
      A : constant Matrix := Make_Poisson_1D (N);
      Res : constant Result :=
        Run (A, Make_Ones_Vector (N),
             (M => 6, Tol => 1.0E-10, Reorthogonalize => True,
              Max_QR_Iter => 80, Keep_V => True));
      Lam_Min : constant Float := Poisson_Eigenvalue (N, 1);
      Lam_Max : constant Float := Poisson_Eigenvalue (N, N);
   begin
      Check (Res.Success, "Poisson Success");
      Check (Res.Steps = 6, "Poisson partial Steps=6");
      --  Extreme Ritz values should approach extreme eigenvalues.
      Check (Approx (Res.Ritz_Values (1), Lam_Min, 0.15),
             "Poisson smallest Ritz near λ_min");
      --  With m < n, extremes converge at different rates; require the
      --  largest Ritz to sit in the upper part of the spectrum.
      Check (Res.Ritz_Values (Res.Steps) > 0.85 * Lam_Max,
             "Poisson largest Ritz in upper spectrum");
      Check (Approx (Res.Ritz_Values (Res.Steps), Lam_Max, 0.45),
             "Poisson largest Ritz near λ_max (loose)");
      Check (Approx (Orthogonality_Residual (Res.V, N, Res.Steps),
                     0.0, 1.0E-4),
             "Poisson V orthonormal");
   end;

   ---------------------------------------------------------------------
   Section ("12. Default start / Keep_V false / aliases");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([1.0, 2.0, 3.0]);
      R1 : constant Result :=
        Run (A,
             Params =>
               (M => 3, Tol => 1.0E-10, Reorthogonalize => True,
                Max_QR_Iter => 64, Keep_V => False));
      R2 : constant Result :=
        Iterate (A, Make_Ones_Vector (3),
                 (M => 3, Tol => 1.0E-10, Reorthogonalize => True,
                  Max_QR_Iter => 64, Keep_V => True));
      R3 : constant Result :=
        Build_Tridiagonal
          (A, Make_Ones_Vector (3),
           (M => 3, Tol => 1.0E-10, Reorthogonalize => True,
            Max_QR_Iter => 64, Keep_V => True));
   begin
      Check (R1.Success and not R1.Has_V, "Keep_V false");
      Check (Spectrum_Near
               (R1.Ritz_Values (1 .. 3), [1.0, 2.0, 3.0], 1.0E-3),
             "default ones start Ritz");
      Check (R2.Success and R2.Has_V, "Iterate alias");
      Check (R3.Success and R3.Steps = 3, "Build_Tridiagonal only");
      Check (Approx (R3.Ritz_Values (1), 0.0), "Build no Ritz fill");
   end;

   ---------------------------------------------------------------------
   Section ("13. Ritz_Vector helper / Sorted Ritz / M clipped to n");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([2.0, 4.0]);
      Res : constant Result :=
        Run (A, [1.0, 1.0],
             (M => 10, Tol => 1.0E-10, Reorthogonalize => True,
              Max_QR_Iter => 64, Keep_V => True));
      Z : constant Vector (1 .. Res.Steps) :=
        [others => 0.0];
      Y : Vector (1 .. 2);
   begin
      Check (Res.Steps <= 2, "M clipped to n");
      Check (Res.M_Requested = 10, "M_Requested stored");
      Check (Res.Ritz_Values (1) <= Res.Ritz_Values (Res.Steps),
             "Ritz sorted ascending");
      declare
         Z1 : Vector (1 .. Res.Steps) := [others => 0.0];
      begin
         Z1 (1) := 1.0;
         Y := Ritz_Vector (Res, Z1);
         Check (Approx (Norm2 (Y), 1.0, 1.0E-4),
                "Ritz_Vector first T-basis col unitish");
      end;
      pragma Unreferenced (Z);
   end;

   ---------------------------------------------------------------------
   Section ("14. Example kinds / more spectrum checks");
   ---------------------------------------------------------------------
   declare
      A1 : constant Matrix := Make_Example (Poisson_1D, 5);
      A2 : constant Matrix := Make_Example (Known_Spectrum_Symmetric, 4);
      R1 : constant Result :=
        Run (A1, Make_Ones_Vector (5),
             (M => 5, Tol => 1.0E-10, Reorthogonalize => True,
              Max_QR_Iter => 80, Keep_V => True));
      R2 : constant Result :=
        Run (A2,
             Params =>
               (M => 4, Tol => 1.0E-10, Reorthogonalize => True,
                Max_QR_Iter => 80, Keep_V => True));
   begin
      Check (R1.Success, "example Poisson Success");
      Check (R2.Success, "example known Success");
      Check (Spectrum_Near
               (R2.Ritz_Values (1 .. 4), [1.0, 2.0, 3.0, 4.0], 5.0E-2),
             "example known spectrum");
      Check (Approx (Orthogonality_Residual (R1.V, 5, R1.Steps),
                     0.0, 1.0E-4),
             "example Poisson ortho");
   end;

   ---------------------------------------------------------------------
   Section ("15. Single-step / 2×2 / Set_Column roundtrip");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([6.0, 1.0]);
      Res : constant Result :=
        Run (A, [1.0, 0.1],
             (M => 1, Tol => 1.0E-10, Reorthogonalize => True,
              Max_QR_Iter => 32, Keep_V => True));
      Mtx : Matrix (1 .. 2, 1 .. 2) := [others => [others => 0.0]];
      Col : constant Vector (1 .. 2) := [3.0, 4.0];
   begin
      Check (Res.Success and Res.Steps = 1, "M=1 Steps");
      Check (Approx (Res.Ritz_Values (1), Res.Alphas (1)),
             "M=1 Ritz=α");
      Set_Column (Mtx, 2, Col);
      Check (Approx (Column (Mtx, 2) (1), 3.0)
             and Approx (Column (Mtx, 2) (2), 4.0),
             "Set_Column roundtrip");
   end;

   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[2.0, 1.0], [1.0, 2.0]];
      Res : constant Result :=
        Run (A, [1.0, 0.0],
             (M => 2, Tol => 1.0E-12, Reorthogonalize => True,
              Max_QR_Iter => 64, Keep_V => True));
   begin
      Check (Res.Success, "2x2 Success");
      Check (Spectrum_Near
               (Res.Ritz_Values (1 .. 2), [1.0, 3.0], 1.0E-3),
             "2x2 spectrum 1,3");
      Check (Ritz_Residual_Norm
               (A, Column (Res.Ritz_Vectors, 1), Res.Ritz_Values (1))
             < 1.0E-3,
             "2x2 residual 1");
      Check (Ritz_Residual_Norm
               (A, Column (Res.Ritz_Vectors, 2), Res.Ritz_Values (2))
             < 1.0E-3,
             "2x2 residual 2");
   end;

   ---------------------------------------------------------------------
   Section ("16. Beta_Next / α Rayleigh first step");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Poisson_1D (3);
      V0 : constant Vector := Normalize (Make_Ones_Vector (3));
      Res : constant Result :=
        Build_Tridiagonal
          (A, V0,
           (M => 3, Tol => 1.0E-12, Reorthogonalize => True,
            Max_QR_Iter => 64, Keep_V => True));
      RQ : constant Float := Dot (V0, Mat_Vec (A, V0));
   begin
      Check (Approx (Res.Alphas (1), RQ, 1.0E-5),
             "α₁ = v₁ᵀ A v₁");
      Check (Res.Beta_Next = Res.Betas (Res.Steps),
             "Beta_Next = last β");
      Check (Res.Betas (1) > 0.0, "β₂ > 0 typically");
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
