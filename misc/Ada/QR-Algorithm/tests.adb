--  Standalone test suite for QR_Algorithm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with QR_Algorithm; use QR_Algorithm;

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

   --  Sort a leading N-vector ascending (simple insertion sort).
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
   Ada.Text_IO.Put_Line ("QR_Algorithm test suite");
   Ada.Text_IO.Put_Line ("=======================");

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
   Section ("2. Mat_Vec / Mat_Mul / Transpose / Identity");
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
   Section ("3. Off_Diag_Norm / Column / Set_Column");
   ---------------------------------------------------------------------
   declare
      D : constant Matrix := Make_Diagonal ([1.0, 2.0, 3.0]);
      B : Matrix (1 .. 2, 1 .. 2) := [[1.0, 3.0], [4.0, 2.0]];
      Col1 : constant Vector := Column (B, 1);
   begin
      Check (Approx (Off_Diag_Norm (D), 0.0), "Off_Diag diagonal=0");
      Check (Approx (Off_Diag_Norm (B), 5.0), "Off_Diag 3-4-5");
      Check (Approx (Col1 (1), 1.0) and Approx (Col1 (2), 4.0),
             "Column 1");
      Set_Column (B, 2, [9.0, 8.0]);
      Check (Approx (B (1, 2), 9.0) and Approx (B (2, 2), 8.0),
             "Set_Column");
   end;

   ---------------------------------------------------------------------
   Section ("4. Builders: Diagonal / Poisson / Hilbert / Known / Randomish");
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
   Section ("5. QR_Factor: orthogonality QᵀQ≈I and QR≈A");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 3, 1 .. 3) :=
        [[2.0, 1.0, 0.0],
         [1.0, 3.0, 1.0],
         [0.0, 1.0, 4.0]];
      Fac : constant QR_Result := QR_Factor (A);
      QtQ_Res : Float;
      Recon : Matrix (1 .. 3, 1 .. 3);
      Err : Float := 0.0;
   begin
      Check (Fac.Success and Fac.Stat = Ok, "QR_Factor Success");
      Check (Fac.N = 3, "QR_Factor N=3");
      QtQ_Res := Orthogonality_Residual (Fac.Q, 3);
      Check (QtQ_Res < 1.0E-5, "QᵀQ≈I residual");
      declare
         Q_Lead : Matrix (1 .. 3, 1 .. 3);
         R_Lead : Matrix (1 .. 3, 1 .. 3);
      begin
         for I in 1 .. 3 loop
            for J in 1 .. 3 loop
               Q_Lead (I, J) := Fac.Q (I, J);
               R_Lead (I, J) := Fac.R (I, J);
            end loop;
         end loop;
         Recon := Mat_Mul (Q_Lead, R_Lead);
      end;
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            Err := Err + abs (Recon (I, J) - A (I, J));
         end loop;
      end loop;
      Check (Err < 1.0E-4, "QR≈A reconstruction");
      --  R upper triangular
      Check (Approx (Fac.R (2, 1), 0.0, 1.0E-5)
             and Approx (Fac.R (3, 1), 0.0, 1.0E-5)
             and Approx (Fac.R (3, 2), 0.0, 1.0E-5),
             "R upper triangular");
   end;

   declare
      Iden : constant Matrix := Identity (4);
      Fac : constant QR_Result := QR_Factor (Iden);
   begin
      Check (Fac.Success, "QR Identity Success");
      Check (Orthogonality_Residual (Fac.Q, 4) < 1.0E-6,
             "QR Identity Q orthonormal");
      Check (Approx (Fac.R (1, 1), 1.0) and Approx (Fac.R (4, 4), 1.0),
             "QR Identity R=I");
   end;

   declare
      A : constant Matrix := Make_Example (Symmetric_Randomish, 5);
      Fac : constant QR_Result := QR_Factor (A);
      Recon : Matrix (1 .. 5, 1 .. 5);
      Diff : Float := 0.0;
      Q5, R5 : Matrix (1 .. 5, 1 .. 5);
   begin
      Check (Fac.Success, "QR 5×5 Success");
      Check (Orthogonality_Residual (Fac.Q, 5) < 1.0E-4,
             "QR 5×5 QᵀQ≈I");
      for I in 1 .. 5 loop
         for J in 1 .. 5 loop
            Q5 (I, J) := Fac.Q (I, J);
            R5 (I, J) := Fac.R (I, J);
         end loop;
      end loop;
      Recon := Mat_Mul (Q5, R5);
      for I in 1 .. 5 loop
         for J in 1 .. 5 loop
            Diff := Diff + abs (Recon (I, J) - A (I, J));
         end loop;
      end loop;
      Check (Diff < 1.0E-3, "QR 5×5 reconstruction");
   end;

   ---------------------------------------------------------------------
   Section ("6. QR_Step preserves similarity (trace / Frobenius)");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[2.0, 1.0],
         [1.0, 3.0]];
      S : constant Step_Result := QR_Step (A, 0.0);
      Next_Lead : Matrix (1 .. 2, 1 .. 2);
   begin
      Check (S.Success, "QR_Step Success");
      for I in 1 .. 2 loop
         for J in 1 .. 2 loop
            Next_Lead (I, J) := S.Next (I, J);
         end loop;
      end loop;
      Check (Approx (Trace (Next_Lead), Trace (A), 1.0E-4),
             "QR_Step preserves Trace");
      Check (Is_Symmetric (Next_Lead, 1.0E-4),
             "QR_Step keeps symmetry");
   end;

   ---------------------------------------------------------------------
   Section ("7. Eigenvalues: diagonal matrices");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([2.0, 5.0, -1.0]);
      Res : constant Result :=
        Iterate (A, (Tol => 1.0E-8, Max_Iter => 10,
                     Use_Shift => False, Accumulate_Q => False));
      Expect : constant Vector (1 .. 3) := [2.0, 5.0, -1.0];
   begin
      Check (Res.Success and Res.Stat = Converged, "Diagonal Converged");
      Check (Res.Iterations = 0, "Diagonal already done");
      Check (Spectra_Match (Res.Eigenvalues, Expect, 3, 1.0E-6),
             "Diagonal spectrum");
      Check (Approx (Res.Off_Diag, 0.0), "Diagonal Off_Diag=0");
   end;

   declare
      A : constant Matrix := Make_Example (Diagonal_Known, 1);
      Res : constant Result := Eigenvalues (A);
   begin
      Check (Res.Success and Res.Stat = Converged, "1×1 Converged");
      Check (Approx (Res.Eigenvalues (1), 1.0), "1×1 λ=1");
      Check (Res.N = 1, "1×1 N");
   end;

   declare
      A : constant Matrix := Make_Diagonal ([4.0, 1.0, 9.0, 2.0]);
      Res : constant Result := Iterate (A);
      Expect : constant Vector (1 .. 4) := [4.0, 1.0, 9.0, 2.0];
   begin
      Check (Res.Success, "4×4 diagonal Success");
      Check (Spectra_Match (Res.Eigenvalues, Expect, 4, 1.0E-5),
             "4×4 diagonal spectrum");
   end;

   ---------------------------------------------------------------------
   Section ("8. Eigenvalues: dense symmetric known spectrum");
   ---------------------------------------------------------------------
   declare
      Eigs : constant Vector (1 .. 3) := [1.0, 2.0, 4.0];
      A : constant Matrix := Make_Symmetric_Known (Eigs);
      Res : constant Result :=
        Iterate (A, (Tol => 1.0E-6, Max_Iter => 200,
                     Use_Shift => False, Accumulate_Q => False));
   begin
      Check (Is_Symmetric (A), "Known A symmetric");
      Check (Res.Success and Res.Stat = Converged,
             "Known spectrum Converged");
      Check (Spectra_Match (Res.Eigenvalues, Eigs, 3, 1.0E-3),
             "Known spectrum match");
      Check (Approx (Trace (A), 7.0, 1.0E-4), "Known Trace");
   end;

   declare
      Eigs : constant Vector (1 .. 4) := [0.5, 1.5, 3.0, 6.0];
      A : constant Matrix := Make_Symmetric_Known (Eigs);
      Res : constant Result :=
        Iterate (A, (Tol => 1.0E-5, Max_Iter => 400,
                     Use_Shift => False, Accumulate_Q => False));
   begin
      Check (Res.Success, "4×4 known Success");
      Check (Spectra_Match (Res.Eigenvalues, Eigs, 4, 5.0E-3),
             "4×4 known spectrum");
   end;

   declare
      A : constant Matrix := Make_Example (Symmetric_Known, 2);
      Res : constant Result :=
        Iterate (A, (Tol => 1.0E-7, Max_Iter => 100,
                     Use_Shift => False, Accumulate_Q => False));
      Expect : constant Vector (1 .. 2) := [1.0, 2.0];
   begin
      Check (Res.Success, "2×2 known Success");
      Check (Spectra_Match (Res.Eigenvalues, Expect, 2, 1.0E-4),
             "2×2 known spectrum");
   end;

   ---------------------------------------------------------------------
   Section ("9. Eigenvalues: Poisson 1-D known λ");
   ---------------------------------------------------------------------
   declare
      N : constant Dimension := 4;
      A : constant Matrix := Make_Poisson_1D (N);
      Res : constant Result :=
        Iterate (A, (Tol => 1.0E-6, Max_Iter => 300,
                     Use_Shift => False, Accumulate_Q => False));
      Expect : Vector (1 .. N);
   begin
      for K in 1 .. N loop
         Expect (K) := Poisson_Eigenvalue (N, K);
      end loop;
      Check (Res.Success and Res.Stat = Converged, "Poisson Converged");
      Check (Spectra_Match (Res.Eigenvalues, Expect, N, 1.0E-3),
             "Poisson spectrum");
      Check (Approx (Trace (A), 8.0), "Poisson Trace=2N");
   end;

   declare
      N : constant Dimension := 5;
      A : constant Matrix := Make_Poisson_1D (N);
      Res : constant Result :=
        Iterate (A, (Tol => 1.0E-5, Max_Iter => 500,
                     Use_Shift => False, Accumulate_Q => False));
      Expect : Vector (1 .. N);
   begin
      for K in 1 .. N loop
         Expect (K) := Poisson_Eigenvalue (N, K);
      end loop;
      Check (Res.Success, "Poisson 5 Success");
      Check (Spectra_Match (Res.Eigenvalues, Expect, N, 5.0E-3),
             "Poisson 5 spectrum");
   end;

   ---------------------------------------------------------------------
   Section ("10. Residuals: Final_A nearly diagonal; Eigenvalues alias");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Symmetric_Known ([2.0, 5.0, 8.0]);
      Res : constant Result :=
        Eigenvalues (A, (Tol => 1.0E-5, Max_Iter => 500,
                         Use_Shift => False, Accumulate_Q => False));
      Off : Float;
   begin
      Check (Res.Success, "Eigenvalues alias Success");
      declare
         FA : Matrix (1 .. Res.N, 1 .. Res.N);
      begin
         for I in 1 .. Res.N loop
            for J in 1 .. Res.N loop
               FA (I, J) := Res.Final_A (I, J);
            end loop;
         end loop;
         Off := Off_Diag_Norm (FA);
      end;
      Check (Off <= 1.0E-5, "Final_A Off_Diag ≤ Tol");
      Check (Approx (Res.Off_Diag, Off, 1.0E-8), "Off_Diag field");
      Check (Spectra_Match
               (Res.Eigenvalues, [2.0, 5.0, 8.0], 3, 1.0E-2),
             "Alias spectrum");
   end;

   ---------------------------------------------------------------------
   Section ("11. Accumulate_Q eigenvector sketch");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonal ([3.0, 1.0, 7.0]);
      Res : constant Result :=
        Iterate (A, (Tol => 1.0E-8, Max_Iter => 5,
                     Use_Shift => False, Accumulate_Q => True));
   begin
      Check (Res.Success and Res.Has_V, "Accumulate Has_V");
      Check (Orthogonality_Residual (Res.V, 3) < 1.0E-5,
             "Accumulated V orthonormal (diagonal case)");
   end;

   declare
      Eigs : constant Vector (1 .. 3) := [1.0, 3.0, 5.0];
      A : constant Matrix := Make_Symmetric_Known (Eigs);
      Res : constant Result :=
        Iterate (A, (Tol => 1.0E-5, Max_Iter => 300,
                     Use_Shift => False, Accumulate_Q => True));
      --  Check A V ≈ V D for first column
      AV, VD : Vector (1 .. 3);
      Col_Ok : Boolean := True;
      Qcol : Vector (1 .. 3);
      Lam : Float;
   begin
      Check (Res.Success and Res.Has_V, "Dense Accumulate Success");
      for J in 1 .. 3 loop
         for I in 1 .. 3 loop
            Qcol (I) := Res.V (I, J);
         end loop;
         Lam := Res.Eigenvalues (J);
         AV := Mat_Vec (A, Qcol);
         VD := Scale (Qcol, Lam);
         for I in 1 .. 3 loop
            if abs (AV (I) - VD (I)) > 5.0E-2 then
               Col_Ok := False;
            end if;
         end loop;
      end loop;
      Check (Col_Ok, "A V ≈ V Λ residual sketch");
   end;

   ---------------------------------------------------------------------
   Section ("12. Wilkinson shift sketch");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 4.0]];
      Mu : constant Float := Wilkinson_Shift (A);
   begin
      Check (Approx (Mu, 4.0), "Wilkinson closer to a22=4");
   end;

   declare
      A : constant Matrix (1 .. 3, 1 .. 3) :=
        [[2.0, 0.1, 0.0],
         [0.1, 3.0, 0.2],
         [0.0, 0.2, 5.0]];
      Mu : constant Float := Wilkinson_Shift (A);
   begin
      Check (Mu > 2.0 and Mu < 6.0, "Wilkinson 3×3 in range");
   end;

   declare
      Eigs : constant Vector (1 .. 3) := [1.0, 2.0, 10.0];
      A : constant Matrix := Make_Symmetric_Known (Eigs);
      Res_U : constant Result :=
        Iterate (A, (Tol => 1.0E-5, Max_Iter => 400,
                     Use_Shift => False, Accumulate_Q => False));
      Res_S : constant Result :=
        Iterate (A, (Tol => 1.0E-5, Max_Iter => 400,
                     Use_Shift => True, Accumulate_Q => False));
   begin
      Check (Res_U.Success, "Unshifted known Success");
      Check (Res_S.Success, "Shifted known Success");
      Check (Spectra_Match (Res_S.Eigenvalues, Eigs, 3, 1.0E-2),
             "Shifted spectrum match");
      --  Shifted should not be slower in a broken way
      --  Adaptive shift falls back to unshifted when it does not help,
      --  so iteration count should stay in the same ballpark.
      Check (Res_S.Iterations <= Res_U.Iterations + 100,
             "Shifted iterations reasonable");
   end;

   ---------------------------------------------------------------------
   Section ("13. Parameters / Status / defaults");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Symmetric_Known ([1.0, 4.0]);
      Res_Lim : constant Result :=
        Iterate (A, (Tol => 1.0E-14, Max_Iter => 1,
                     Use_Shift => False, Accumulate_Q => False));
   begin
      Check (Default_Parameters.Max_Iter = 200, "Default Max_Iter");
      Check (Default_Parameters.Tol = 1.0E-6, "Default Tol");
      Check (not Default_Parameters.Use_Shift, "Default no shift");
      Check (not Default_Parameters.Accumulate_Q, "Default no AccQ");
      Check (Res_Lim.Stat = Iteration_Limit
             or else Res_Lim.Stat = Converged,
             "Tiny budget Status");
      Check (Res_Lim.N = 2, "Tiny budget matrix N=2");
   end;

   ---------------------------------------------------------------------
   Section ("14. Extra QR / similarity / Hilbert tiny");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Hilbert (2);
      Fac : constant QR_Result := QR_Factor (A);
      Res : constant Result :=
        Iterate (A, (Tol => 1.0E-5, Max_Iter => 200,
                     Use_Shift => False, Accumulate_Q => False));
   begin
      Check (Fac.Success, "Hilbert QR Success");
      Check (Orthogonality_Residual (Fac.Q, 2) < 1.0E-4,
             "Hilbert Q orthonormal");
      Check (Res.Success, "Hilbert eigenvalues Success");
      --  Hilbert 2×2 eigenvalues known: (3±√5)/2 ≈ 2.618, 0.382
      --  Exact Hilbert 2×2 eigenvalues: (4 ± √13) / 6
      Check (Spectra_Match
               (Res.Eigenvalues,
                [(4.0 + 3.605551275) / 6.0,
                 (4.0 - 3.605551275) / 6.0],
                2, 1.0E-3),
             "Hilbert 2×2 spectrum");
   end;

   declare
      A : constant Matrix :=
        Make_Symmetric_Randomish (3);
      Res : constant Result :=
        Iterate (A, (Tol => 1.0E-3, Max_Iter => 2000,
                     Use_Shift => False, Accumulate_Q => False));
      Sum_Eig : Float := 0.0;
   begin
      Check (Res.Success, "Randomish Converged");
      for I in 1 .. 3 loop
         Sum_Eig := Sum_Eig + Res.Eigenvalues (I);
      end loop;
      Check (Approx (Sum_Eig, Trace (A), 1.0E-2),
             "Sum λ = Trace");
      Check (Res.Off_Diag <= 1.0E-2, "Randomish Off_Diag small");
   end;

   declare
      --  Similarity: one more QR step on a 3×3 Poisson
      A : constant Matrix := Make_Poisson_1D (3);
      S1 : constant Step_Result := QR_Step (A);
      Next3 : Matrix (1 .. 3, 1 .. 3);
   begin
      Check (S1.Success, "Poisson QR_Step");
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            Next3 (I, J) := S1.Next (I, J);
         end loop;
      end loop;
      Check (Approx (Trace (Next3), Trace (A), 1.0E-4),
             "Poisson step Trace");
      Check (Approx (Frobenius_Norm (Next3), Frobenius_Norm (A),
                     1.0E-3),
             "Poisson step ‖·‖_F (orthogonal sim)");
   end;

   --  Fill remaining coverage with helper edge cases
   declare
      Z : constant Matrix (1 .. 2, 1 .. 2) :=
        [[0.0, 0.0], [0.0, 0.0]];
      Fac : constant QR_Result := QR_Factor (Z);
      A2 : constant Matrix := Make_Diagonal ([9.0, 9.0]);
      Res : constant Result := Iterate (A2);
   begin
      Check (Fac.Stat = Rank_Deficient, "Zero matrix Rank_Deficient");
      Check (not Fac.Success, "Zero matrix not Success");
      Check (Res.Success, "Repeated eigenvalue Success");
      Check (Approx (Res.Eigenvalues (1), 9.0)
             and Approx (Res.Eigenvalues (2), 9.0),
             "Repeated λ=9");
   end;

   declare
      A : constant Matrix := Make_Example (Diagonal_Known, 6);
      Res : constant Result := Iterate (A);
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
      A : constant Matrix := Make_Symmetric_Known
        ([1.0, 2.0, 3.0, 4.0, 5.0]);
      Res : constant Result :=
        Iterate (A, (Tol => 1.0E-4, Max_Iter => 1500,
                     Use_Shift => True, Accumulate_Q => False));
   begin
      Check (Res.Success, "5×5 shifted Success");
      Check (Spectra_Match
               (Res.Eigenvalues, [1.0, 2.0, 3.0, 4.0, 5.0], 5, 2.0E-2),
             "5×5 shifted spectrum");
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
