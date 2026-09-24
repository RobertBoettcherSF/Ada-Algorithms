--  Standalone test suite for Jacobi_Eigenvalue (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Jacobi_Eigenvalue; use Jacobi_Eigenvalue;

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

   function Sorted_Copy (V : Vector; N : Dimension) return Vector is
      R : Vector (1 .. N);
      Key : Float;
      J : Natural;
   begin
      for I in 1 .. N loop
         R (I) := V (V'First + (I - 1));
      end loop;
      for I in 2 .. N loop
         Key := R (I);
         J := I - 1;
         while J >= 1 and then R (J) > Key loop
            R (J + 1) := R (J);
            J := J - 1;
            exit when J < 1;
         end loop;
         R (J + 1) := Key;
      end loop;
      return R;
   end Sorted_Copy;

   function Spectra_Match
     (Got, Expect : Vector; N : Dimension; Tol : Float) return Boolean
   is
      G : constant Vector := Sorted_Copy (Got, N);
      E : constant Vector := Sorted_Copy (Expect, N);
   begin
      for I in 1 .. N loop
         if abs (G (I) - E (I)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Spectra_Match;

begin
   Ada.Text_IO.Put_Line ("Jacobi_Eigenvalue test suite");
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
   Section ("2. Mat_Vec / Mat_Mul / Transpose / Identity / Trace");
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
      Iden : constant Matrix := Identity (2);
      A_T : constant Matrix := Mat_Transpose (Asym);
      Prod : constant Matrix := Mat_Mul (A, Iden);
   begin
      Check (Approx (Y (1), 5.0), "Mat_Vec row1");
      Check (Approx (Y (2), 4.0), "Mat_Vec row2");
      Check (Is_Square (A), "Is_Square");
      Check (Is_Symmetric (A), "Is_Symmetric A");
      Check (not Is_Symmetric (Asym), "Is_Symmetric rejects");
      Check (Approx (Iden (1, 1), 1.0) and Approx (Iden (1, 2), 0.0),
             "Identity");
      Check (Approx (A_T (1, 2), 0.0) and Approx (A_T (2, 1), 2.0),
             "Mat_Transpose");
      Check (Approx (Prod (1, 1), 4.0) and Approx (Prod (2, 2), 3.0),
             "Mat_Mul A·I");
      Check (Approx (Trace (A), 7.0), "Trace A");
      Check (Approx (Frobenius_Norm (Iden) * Frobenius_Norm (Iden), 2.0),
             "Frobenius I_2 squared");
   end;

   ---------------------------------------------------------------------
   Section ("3. Off_Diag_Norm / Column / Set_Column / Orthogonality");
   ---------------------------------------------------------------------
   declare
      D : constant Matrix := Make_Diagonal ([1.0, 2.0, 3.0]);
      B : Matrix (1 .. 2, 1 .. 2) := [[1.0, 3.0], [4.0, 2.0]];
      Col1 : constant Vector := Column (B, 1);
      I3 : constant Matrix := Identity (3);
   begin
      Check (Approx (Off_Diag_Norm (D), 0.0), "Off_Diag diagonal=0");
      Check (Approx (Off_Diag_Norm (B), 5.0), "Off_Diag 3-4-5");
      Check (Approx (Col1 (1), 1.0) and Approx (Col1 (2), 4.0),
             "Column 1");
      Set_Column (B, 2, [9.0, 8.0]);
      Check (Approx (B (1, 2), 9.0) and Approx (B (2, 2), 8.0),
             "Set_Column");
      Check (Orthogonality_Residual (I3, 3) < 1.0E-12,
             "I_3 orthogonality");
   end;

   ---------------------------------------------------------------------
   Section ("4. Eigen_Residual / Mat_Eigen_Residual");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([2.0, 5.0, 3.0]);
      E2 : constant Vector (1 .. 3) := [0.0, 1.0, 0.0];
      Resv : constant Vector := Eigen_Residual (A, E2, 5.0);
      V : constant Matrix := Identity (3);
      Eigs : constant Vector (1 .. 3) := [2.0, 5.0, 3.0];
   begin
      Check (Approx (Norm2 (Resv), 0.0), "Eigen_Residual exact evec");
      Check (Approx (Eigen_Residual_Norm (A, E2, 5.0), 0.0),
             "Eigen_Residual_Norm zero");
      Check (Approx (Mat_Eigen_Residual (A, V, Eigs, 3), 0.0),
             "Mat_Eigen_Residual diagonal");
      Check (Approx (Eigen_Residual_Norm (A, E2, 4.0), 1.0),
             "Eigen_Residual wrong λ");
   end;

   ---------------------------------------------------------------------
   Section ("5. Builders: Diagonal / Poisson / Hilbert / Known / Randomish");
   ---------------------------------------------------------------------
   declare
      D : constant Matrix := Make_Diagonal ([1.0, 3.0, 7.0]);
      Dk : constant Matrix := Make_Example (Diagonal_Known, 4);
      P : constant Matrix := Make_Example (Poisson_1D, 4);
      H : constant Matrix := Make_Example (Hilbert_Tiny, 3);
      Sk : constant Matrix := Make_Example (Symmetric_Known, 3);
      R : constant Matrix := Make_Example (Symmetric_Randomish, 3);
      Lam1 : constant Float := Poisson_Eigenvalue (4, 1);
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
      Check (Is_Symmetric (Sk), "Symmetric_Known symmetric");
      Check (Is_Symmetric (R), "Randomish symmetric");
      Check (Approx (Trace (Sk), 6.0, 1.0E-4), "Known spectrum trace");
      Check (Lam1 > 0.0 and Lam1 < 2.0, "Poisson λ1 in (0,2)");
      Check (Approx (Poisson_Eigenvalue (1, 1), 2.0), "Poisson 1×1 λ=2");
   end;

   ---------------------------------------------------------------------
   Section ("6. Diagonal already done / 1×1 / repeated λ");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([2.0, 5.0, -1.0]);
      Res : constant Result :=
        Diagonalize (A, (Tol => 1.0E-8, Max_Sweeps => 10,
                         Mode => Cyclic, Sort_Eigs => True));
      Expect : constant Vector (1 .. 3) := [-1.0, 2.0, 5.0];
   begin
      Check (Res.Success and Res.Stat = Converged, "Diagonal Converged");
      Check (Res.Sweeps = 0 and Res.Rotations = 0, "Diagonal already done");
      Check (Spectra_Match (Res.Eigenvalues, Expect, 3, 1.0E-6),
             "Diagonal spectrum sorted");
      Check (Approx (Res.Off_Diag_Norm, 0.0), "Diagonal Off_Diag=0");
      Check (Orthogonality_Residual (Res.Eigenvectors, 3) < 1.0E-6,
             "Diagonal V = I (permuted)");
   end;

   declare
      A : constant Matrix := Make_Example (Diagonal_Known, 1);
      Res : constant Result := Eigenpairs (A);
   begin
      Check (Res.Success and Res.Stat = Converged, "1×1 Converged");
      Check (Approx (Res.Eigenvalues (1), 1.0), "1×1 λ=1");
      Check (Res.N = 1, "1×1 N");
      Check (Approx (Res.Eigenvectors (1, 1), 1.0), "1×1 V=1");
   end;

   declare
      A2 : constant Matrix := Make_Diagonal ([9.0, 9.0]);
      Res : constant Result := Diagonalize (A2);
   begin
      Check (Res.Success, "Repeated eigenvalue Success");
      Check (Approx (Res.Eigenvalues (1), 9.0)
             and Approx (Res.Eigenvalues (2), 9.0),
             "Repeated λ=9");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([4.0, 1.0, 9.0, 2.0]);
      Res : constant Result := Diagonalize (A);
      Expect : constant Vector (1 .. 4) := [1.0, 2.0, 4.0, 9.0];
   begin
      Check (Res.Success, "4×4 diagonal Success");
      Check (Spectra_Match (Res.Eigenvalues, Expect, 4, 1.0E-5),
             "4×4 diagonal spectrum");
   end;

   ---------------------------------------------------------------------
   Section ("7. Dense symmetric known spectrum");
   ---------------------------------------------------------------------
   declare
      Eigs : constant Vector (1 .. 3) := [1.0, 2.0, 4.0];
      A : constant Matrix := Make_Symmetric_Known (Eigs);
      Res : constant Result :=
        Diagonalize (A, (Tol => 1.0E-8, Max_Sweeps => 40,
                         Mode => Cyclic, Sort_Eigs => True));
   begin
      Check (Is_Symmetric (A), "Known A symmetric");
      Check (Res.Success and Res.Stat = Converged,
             "Known spectrum Converged");
      Check (Spectra_Match (Res.Eigenvalues, Eigs, 3, 1.0E-4),
             "Known spectrum match");
      Check (Approx (Trace (A), 7.0, 1.0E-4), "Known Trace");
      Check (Res.Sweeps >= 1, "Known needed sweeps");
   end;

   declare
      Eigs : constant Vector (1 .. 4) := [0.5, 1.5, 3.0, 6.0];
      A : constant Matrix := Make_Symmetric_Known (Eigs);
      Res : constant Result :=
        Diagonalize (A, (Tol => 1.0E-7, Max_Sweeps => 50,
                         Mode => Cyclic, Sort_Eigs => True));
   begin
      Check (Res.Success, "4×4 known Success");
      Check (Spectra_Match (Res.Eigenvalues, Eigs, 4, 1.0E-3),
             "4×4 known spectrum");
   end;

   declare
      A : constant Matrix := Make_Example (Symmetric_Known, 2);
      Res : constant Result := Diagonalize (A);
      Expect : constant Vector (1 .. 2) := [1.0, 2.0];
   begin
      Check (Res.Success, "2×2 known Success");
      Check (Spectra_Match (Res.Eigenvalues, Expect, 2, 1.0E-5),
             "2×2 known spectrum");
   end;

   ---------------------------------------------------------------------
   Section ("8. Poisson 1-D known λ");
   ---------------------------------------------------------------------
   declare
      N : constant Dimension := 4;
      A : constant Matrix := Make_Poisson_1D (N);
      Res : constant Result :=
        Diagonalize (A, (Tol => 1.0E-8, Max_Sweeps => 40,
                         Mode => Cyclic, Sort_Eigs => True));
      Expect : Vector (1 .. N);
   begin
      for K in 1 .. N loop
         Expect (K) := Poisson_Eigenvalue (N, K);
      end loop;
      Check (Res.Success and Res.Stat = Converged, "Poisson Converged");
      Check (Spectra_Match (Res.Eigenvalues, Expect, N, 1.0E-4),
             "Poisson spectrum");
      Check (Approx (Trace (A), 8.0), "Poisson Trace=2N");
   end;

   declare
      N : constant Dimension := 6;
      A : constant Matrix := Make_Poisson_1D (N);
      Res : constant Result :=
        Diagonalize (A, (Tol => 1.0E-7, Max_Sweeps => 50,
                         Mode => Cyclic, Sort_Eigs => True));
      Expect : Vector (1 .. N);
   begin
      for K in 1 .. N loop
         Expect (K) := Poisson_Eigenvalue (N, K);
      end loop;
      Check (Res.Success, "Poisson 6 Success");
      Check (Spectra_Match (Res.Eigenvalues, Expect, N, 1.0E-3),
             "Poisson 6 spectrum");
   end;

   ---------------------------------------------------------------------
   Section ("9. VᵀV ≈ I and A V ≈ V Λ");
   ---------------------------------------------------------------------
   declare
      Eigs : constant Vector (1 .. 3) := [1.0, 3.0, 5.0];
      A : constant Matrix := Make_Symmetric_Known (Eigs);
      Res : constant Result :=
        Diagonalize (A, (Tol => 1.0E-8, Max_Sweeps => 40,
                         Mode => Cyclic, Sort_Eigs => True));
      Orth : Float;
      MatRes : Float;
      A_Lead : Matrix (1 .. 3, 1 .. 3);
      V_Lead : Matrix (1 .. 3, 1 .. 3);
      E_Lead : Vector (1 .. 3);
   begin
      Check (Res.Success, "Orthonormal Success");
      Orth := Orthogonality_Residual (Res.Eigenvectors, 3);
      Check (Orth < 1.0E-5, "VᵀV ≈ I");
      for I in 1 .. 3 loop
         E_Lead (I) := Res.Eigenvalues (I);
         for J in 1 .. 3 loop
            A_Lead (I, J) := A (I, J);
            V_Lead (I, J) := Res.Eigenvectors (I, J);
         end loop;
      end loop;
      MatRes := Mat_Eigen_Residual (A_Lead, V_Lead, E_Lead, 3);
      Check (MatRes < 1.0E-4, "A V ≈ V Λ Frobenius");
      Check (Approx (Res.Off_Diag_Norm, 0.0, 1.0E-7)
             or else Res.Off_Diag_Norm <= 1.0E-8,
             "Final Off_Diag ≤ Tol");
   end;

   declare
      --  Per-column residual checks
      Eigs : constant Vector (1 .. 4) := [2.0, 4.0, 6.0, 8.0];
      A : constant Matrix := Make_Symmetric_Known (Eigs);
      Res : constant Result := Diagonalize (A);
      Col_Ok : Boolean := True;
      Qcol : Vector (1 .. 4);
      Lam : Float;
   begin
      Check (Res.Success, "Per-col residual Success");
      for J in 1 .. 4 loop
         for I in 1 .. 4 loop
            Qcol (I) := Res.Eigenvectors (I, J);
         end loop;
         Lam := Res.Eigenvalues (J);
         if Eigen_Residual_Norm (A, Qcol, Lam) > 5.0E-4 then
            Col_Ok := False;
         end if;
      end loop;
      Check (Col_Ok, "Each column A v ≈ λ v");
   end;

   ---------------------------------------------------------------------
   Section ("10. Nonsymmetric rejected");
   ---------------------------------------------------------------------
   declare
      Asym : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 2.0],
         [0.0, 1.0]];
      Res : constant Result := Diagonalize (Asym);
   begin
      Check (Res.Stat = Not_Symmetric, "Nonsym Status");
      Check (not Res.Success, "Nonsym not Success");
      Check (Res.N = 2, "Nonsym N=2");
   end;

   declare
      Asym3 : constant Matrix (1 .. 3, 1 .. 3) :=
        [[2.0, 1.0, 0.0],
         [0.0, 3.0, 1.0],
         [0.0, 0.0, 4.0]];
      Res : constant Result := Eigenpairs (Asym3);
   begin
      Check (Res.Stat = Not_Symmetric, "Nonsym 3×3 Status");
      Check (not Res.Success, "Nonsym 3×3 not Success");
   end;

   ---------------------------------------------------------------------
   Section ("11. Classical mode / Eigenpairs alias / Final_S");
   ---------------------------------------------------------------------
   declare
      Eigs : constant Vector (1 .. 3) := [2.0, 5.0, 8.0];
      A : constant Matrix := Make_Symmetric_Known (Eigs);
      Res_C : constant Result :=
        Diagonalize (A, (Tol => 1.0E-8, Max_Sweeps => 40,
                         Mode => Classical, Sort_Eigs => True));
      Res_Y : constant Result := Eigenpairs (A);
      Off : Float;
      FA : Matrix (1 .. 3, 1 .. 3);
   begin
      Check (Res_C.Success and Res_C.Stat = Converged,
             "Classical Converged");
      Check (Spectra_Match (Res_C.Eigenvalues, Eigs, 3, 1.0E-3),
             "Classical spectrum");
      Check (Res_C.Rotations >= 1, "Classical did rotations");
      Check (Res_Y.Success, "Eigenpairs alias Success");
      Check (Spectra_Match (Res_Y.Eigenvalues, Eigs, 3, 1.0E-3),
             "Eigenpairs spectrum");
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            FA (I, J) := Res_Y.Final_S (I, J);
         end loop;
      end loop;
      Off := Off_Diag_Norm (FA);
      Check (Off <= 1.0E-7, "Final_S nearly diagonal");
   end;

   ---------------------------------------------------------------------
   Section ("12. Iteration limit / defaults / Hilbert / Randomish");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Symmetric_Known ([1.0, 4.0, 9.0]);
      Res_Lim : constant Result :=
        Diagonalize (A, (Tol => 1.0E-14, Max_Sweeps => 1,
                         Mode => Cyclic, Sort_Eigs => True));
   begin
      Check (Default_Parameters.Max_Sweeps = 50, "Default Max_Sweeps");
      Check (Default_Parameters.Tol = 1.0E-8, "Default Tol");
      Check (Default_Parameters.Mode = Cyclic, "Default Cyclic");
      Check (Default_Parameters.Sort_Eigs, "Default Sort_Eigs");
      Check (Res_Lim.Stat = Iteration_Limit
             or else Res_Lim.Stat = Converged,
             "Tiny budget Status");
      Check (Res_Lim.N = 3, "Tiny budget N=3");
   end;

   declare
      A : constant Matrix := Make_Hilbert (2);
      Res : constant Result :=
        Diagonalize (A, (Tol => 1.0E-8, Max_Sweeps => 30,
                         Mode => Cyclic, Sort_Eigs => True));
   begin
      Check (Res.Success, "Hilbert 2×2 Success");
      --  Exact Hilbert 2×2 eigenvalues: (4 ± √13) / 6
      Check (Spectra_Match
               (Res.Eigenvalues,
                [(4.0 + 3.605551275) / 6.0,
                 (4.0 - 3.605551275) / 6.0],
                2, 1.0E-4),
             "Hilbert 2×2 spectrum");
   end;

   declare
      A : constant Matrix := Make_Symmetric_Randomish (4);
      Res : constant Result :=
        Diagonalize (A, (Tol => 1.0E-6, Max_Sweeps => 50,
                         Mode => Cyclic, Sort_Eigs => True));
      Sum_Eig : Float := 0.0;
   begin
      Check (Res.Success, "Randomish Converged");
      for I in 1 .. 4 loop
         Sum_Eig := Sum_Eig + Res.Eigenvalues (I);
      end loop;
      Check (Approx (Sum_Eig, Trace (A), 1.0E-3), "Sum λ = Trace");
      Check (Res.Off_Diag_Norm <= 1.0E-5, "Randomish Off_Diag small");
      Check (Orthogonality_Residual (Res.Eigenvectors, 4) < 1.0E-4,
             "Randomish VᵀV≈I");
   end;

   ---------------------------------------------------------------------
   Section ("13. Apply_Rotation / Frobenius preserved / unsorted");
   ---------------------------------------------------------------------
   declare
      S : Matrix (1 .. 2, 1 .. 2) :=
        [[2.0, 1.0],
         [1.0, 3.0]];
      V : Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 1.0]];
      F0 : constant Float := Frobenius_Norm (S);
      Did : Boolean;
      T0 : constant Float := Trace (S);
   begin
      Did := Apply_Rotation (S, V, 1, 2, 2);
      Check (Did, "Apply_Rotation did work");
      Check (Approx (S (1, 2), 0.0, 1.0E-6), "Pivot zeroed");
      Check (Approx (Trace (S), T0, 1.0E-5), "Rotation Trace preserved");
      Check (Approx (Frobenius_Norm (S), F0, 1.0E-4),
             "Rotation ‖·‖_F preserved");
      Check (Orthogonality_Residual (V, 2) < 1.0E-5,
             "Rotation V orthonormal");
   end;

   declare
      A : constant Matrix := Make_Symmetric_Known ([3.0, 1.0, 2.0]);
      Res : constant Result :=
        Diagonalize (A, (Tol => 1.0E-8, Max_Sweeps => 40,
                         Mode => Cyclic, Sort_Eigs => False));
   begin
      Check (Res.Success, "Unsorted Success");
      Check (Spectra_Match
               (Res.Eigenvalues, [1.0, 2.0, 3.0], 3, 1.0E-3),
             "Unsorted still correct spectrum");
   end;

   ---------------------------------------------------------------------
   Section ("14. Extra sizes / negative eigenvalues / 5×5");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Diagonal_Known, 6);
      Res : constant Result := Diagonalize (A);
      Expect : Vector (1 .. 6);
   begin
      for I in 1 .. 6 loop
         Expect (I) := Float (I);
      end loop;
      Check (Res.Success, "6×6 diagonal Success");
      Check (Spectra_Match (Res.Eigenvalues, Expect, 6, 1.0E-5),
             "6×6 diagonal spectrum");
      Check (Approx (Trace (A), 21.0), "6×6 Trace");
   end;

   declare
      Eigs : constant Vector (1 .. 3) := [-2.0, 0.5, 4.0];
      A : constant Matrix := Make_Symmetric_Known (Eigs);
      Res : constant Result := Diagonalize (A);
   begin
      Check (Res.Success, "Negative λ Success");
      Check (Spectra_Match (Res.Eigenvalues, Eigs, 3, 1.0E-3),
             "Negative λ spectrum");
   end;

   declare
      A : constant Matrix := Make_Symmetric_Known
        ([1.0, 2.0, 3.0, 4.0, 5.0]);
      Res : constant Result :=
        Diagonalize (A, (Tol => 1.0E-6, Max_Sweeps => 60,
                         Mode => Cyclic, Sort_Eigs => True));
   begin
      Check (Res.Success, "5×5 Success");
      Check (Spectra_Match
               (Res.Eigenvalues, [1.0, 2.0, 3.0, 4.0, 5.0], 5, 5.0E-3),
             "5×5 spectrum");
      Check (Orthogonality_Residual (Res.Eigenvectors, 5) < 1.0E-4,
             "5×5 VᵀV≈I");
   end;

   declare
      A : constant Matrix := Make_Poisson_1D (3);
      Res_Cyc : constant Result :=
        Diagonalize (A, (Tol => 1.0E-8, Max_Sweeps => 30,
                         Mode => Cyclic, Sort_Eigs => True));
      Res_Cla : constant Result :=
        Diagonalize (A, (Tol => 1.0E-8, Max_Sweeps => 30,
                         Mode => Classical, Sort_Eigs => True));
      Expect : Vector (1 .. 3);
   begin
      for K in 1 .. 3 loop
         Expect (K) := Poisson_Eigenvalue (3, K);
      end loop;
      Check (Res_Cyc.Success and Res_Cla.Success,
             "Cyclic+Classical Poisson Success");
      Check (Spectra_Match (Res_Cyc.Eigenvalues, Expect, 3, 1.0E-4),
             "Cyclic Poisson spectrum");
      Check (Spectra_Match (Res_Cla.Eigenvalues, Expect, 3, 1.0E-4),
             "Classical Poisson spectrum");
   end;

   declare
      --  Soft checks via Result fields rather than constant folding.
      A : constant Matrix := Make_Diagonal ([7.0]);
      Res : constant Result := Diagonalize (A);
      Params : constant Parameters := Default_Parameters;
   begin
      Check (Res.Success and Res.N = 1, "API 1×1 soft Max_N path");
      Check (Params.Mode = Cyclic and Params.Sort_Eigs,
             "Default Parameters Cyclic+Sort");
      Check (Res.Stat = Converged, "Status Converged used");
      Check (Res.Rotations = 0 and Res.Sweeps = 0,
             "1×1 zero rotations/sweeps");
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
