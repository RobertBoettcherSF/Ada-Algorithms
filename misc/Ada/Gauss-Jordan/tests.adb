--  Standalone test suite for Gauss_Jordan (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Gauss_Jordan; use Gauss_Jordan;

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
   Ada.Text_IO.Put_Line ("Gauss_Jordan (RREF / inverse) test suite");
   Ada.Text_IO.Put_Line ("========================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Vec_Near / Mat_Near / Norm2 / Max_Abs / Dot");
   ---------------------------------------------------------------------
   declare
      U : constant Vector (1 .. 3) := [3.0, 4.0, 0.0];
      V : constant Vector (1 .. 3) := [3.0, 4.0, 0.0];
      W : constant Vector (1 .. 3) := [1.0, 0.0, 0.0];
      I2 : constant Matrix := Identity (2);
      Z2 : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 0.0], [0.0, 1.0]];
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny");
      Check (not Near (1.0, 2.0), "Near rejects");
      Check (Vec_Near (U, V), "Vec_Near equal");
      Check (not Vec_Near (U, W), "Vec_Near rejects");
      Check (Mat_Near (I2, Z2), "Mat_Near Identity");
      Check (Approx (Norm2 (U), 5.0), "Norm2 3-4-5");
      Check (Approx (Norm2 (W), 1.0), "Norm2 unit");
      Check (Approx (Max_Abs (U), 4.0), "Max_Abs U");
      Check (Approx (Max_Abs (W), 1.0), "Max_Abs W");
      Check (Near (-2.0, -2.0), "Near negatives");
      Check (Approx (Norm2 (Zero_Vector (2)), 0.0), "Norm2 zero");
      Check (Approx (Max_Abs (Ones_Vector (4, 2.5)), 2.5), "Max_Abs ones");
      Check (Approx (Dot (U, W), 3.0), "Dot U·W");
   end;

   ---------------------------------------------------------------------
   Section ("2. Identity / Mat_Vec / Mat_Mul / Is_Square / DD");
   ---------------------------------------------------------------------
   declare
      I3 : constant Matrix := Identity (3);
      X  : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      Y  : constant Vector := Mat_Vec (I3, X);
      A  : constant Matrix := Make_Diagonally_Dominant (4);
      W  : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 2.0], [3.0, 0.0]];
      Prod : constant Matrix := Mat_Mul (I3, I3);
   begin
      Check (Is_Square (I3), "Identity square");
      Check (Approx (I3 (1, 1), 1.0) and Approx (I3 (2, 3), 0.0),
             "Identity entries");
      Check (Vec_Near (Y, X), "Mat_Vec Identity");
      Check (Mat_Near (Prod, I3), "Mat_Mul I*I");
      Check (Is_Diagonally_Dominant (A), "DD builder is DD");
      Check (Is_Strictly_Diagonally_Dominant (A), "DD builder strictly DD");
      Check (not Is_Diagonally_Dominant (W), "weak row rejects DD");
      Check (Is_Square (W), "2x2 square");
   end;

   ---------------------------------------------------------------------
   Section ("3. Builders: Hilbert / Poisson / examples / RHS");
   ---------------------------------------------------------------------
   declare
      H  : constant Matrix := Make_Hilbert (3);
      P  : constant Matrix := Make_Poisson_1D (4);
      E2 : constant Matrix := Make_Example (Example_2x2);
      E3 : constant Matrix := Make_Example (Example_3x3);
      NP : constant Matrix := Make_Example (Needs_Pivot);
      Sg : constant Matrix := Make_Example (Singular_2x2);
      Z  : constant Vector := Zero_Vector (3);
      O  : constant Vector := Make_RHS_Ones (3, 7.0);
   begin
      Check (Approx (H (1, 1), 1.0), "Hilbert H11");
      Check (Approx (H (1, 2), 0.5), "Hilbert H12");
      Check (Approx (H (2, 2), 1.0 / 3.0, 1.0E-6), "Hilbert H22");
      Check (Approx (P (1, 1), 2.0) and Approx (P (2, 1), -1.0),
             "Poisson stencil");
      Check (Approx (P (4, 4), 2.0) and Approx (P (3, 4), -1.0),
             "Poisson ends");
      Check (Approx (E2 (1, 1), 2.0) and Approx (E2 (2, 1), 1.0),
             "Example_2x2");
      Check (Approx (E3 (2, 2), 4.0), "Example_3x3 mid");
      Check (Approx (NP (1, 1), 0.0) and Approx (NP (1, 2), 1.0),
             "Needs_Pivot shape");
      Check (Approx (Sg (1, 1), 1.0) and Approx (Sg (2, 2), 4.0),
             "Singular_2x2 shape");
      Check (Approx (Z (2), 0.0), "Zero_Vector");
      Check (Approx (O (1), 7.0) and Approx (O (3), 7.0), "RHS ones");
   end;

   ---------------------------------------------------------------------
   Section ("4. Identity systems (Solve)");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Identity (1);
      B : constant Vector (1 .. 1) := [5.0];
      R : constant Result := Solve (A, B);
   begin
      Check (R.Success and R.Stat = Ok, "1x1 Identity Success");
      Check (R.N = 1, "1x1 N");
      Check (Approx (R.X (1), 5.0), "1x1 x=5");
   end;
   declare
      A : constant Matrix := Identity (4);
      Xtrue : constant Vector (1 .. 4) := [1.0, -2.0, 3.0, 0.5];
      B : constant Vector := Make_RHS_From_Solution (A, Xtrue);
      R : constant Result := Solve (A, B);
   begin
      Check (R.Success, "4x4 Identity Success");
      Check (Vec_Near (R.X (1 .. 4), Xtrue, 1.0E-5), "4x4 Identity x");
      Check (Residual_Norm (A, R.X (1 .. 4), B) < 1.0E-5,
             "4x4 Identity residual");
      Check (R.Swap_Count = 0, "Identity no swaps");
   end;

   ---------------------------------------------------------------------
   Section ("5. Known 2x2 Exact");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Example_2x2);
      B : constant Vector (1 .. 2) := [3.0, 3.0];
      R : constant Result := Solve (A, B);
   begin
      Check (R.Success and R.Stat = Ok, "2x2 Success/Ok");
      Check (Approx (R.X (1), 1.0) and Approx (R.X (2), 1.0), "2x2 x=1,1");
      Check (Residual_Norm (A, R.X (1 .. 2), B) < 1.0E-5, "2x2 residual");
      Check (Approx (Determinant (A), 3.0), "2x2 det=3");
      Check (Rank (A) = 2, "2x2 rank=2");
   end;

   ---------------------------------------------------------------------
   Section ("6. Known 3x3 Exact");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Example_3x3);
      Xtrue : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      B : constant Vector := Make_RHS_From_Solution (A, Xtrue);
      R : constant Result := Solve (A, B);
   begin
      Check (R.Success, "3x3 Success");
      Check (Vec_Near (R.X (1 .. 3), Xtrue, 1.0E-5), "3x3 solution");
      Check (Residual_Max_Abs (A, R.X (1 .. 3), B) < 1.0E-5,
             "3x3 max|r|");
      Check (Approx (Determinant (A), 12.0), "3x3 det=12");
   end;

   ---------------------------------------------------------------------
   Section ("7. Invert: Identity and known matrices");
   ---------------------------------------------------------------------
   declare
      I : constant Matrix := Identity (3);
      InvR : constant Invert_Result := Invert (I);
   begin
      Check (InvR.Success and InvR.Stat = Ok, "Invert I Success");
      Check (Mat_Near (Leading_Square (InvR.Inv, 3), I, 1.0E-5),
             "Invert I = I");
      Check (Inverse_Residual_Max_Abs (I, Leading_Square (InvR.Inv, 3))
               < 1.0E-5,
             "I*Iinv residual");
   end;
   declare
      A : constant Matrix := Make_Example (Example_2x2);
      --  [2 1; 1 2]^{-1} = (1/3)[2 -1; -1 2]
      InvR : constant Invert_Result := Invert (A);
      Expected : constant Matrix (1 .. 2, 1 .. 2) :=
        [[2.0 / 3.0, -1.0 / 3.0],
         [-1.0 / 3.0, 2.0 / 3.0]];
   begin
      Check (InvR.Success, "Invert 2x2 Success");
      Check (Mat_Near (Leading_Square (InvR.Inv, 2), Expected, 1.0E-5),
             "Invert 2x2 entries");
      Check (Inverse_Residual_Max_Abs (A, Leading_Square (InvR.Inv, 2))
               < 1.0E-5,
             "2x2 A*Ainv≈I");
   end;
   declare
      A : constant Matrix := Make_Example (Example_3x3);
      InvR : constant Invert_Result := Invert (A);
   begin
      Check (InvR.Success, "Invert 3x3 Success");
      Check (Inverse_Residual_Max_Abs (A, Leading_Square (InvR.Inv, 3))
               < 1.0E-4,
             "3x3 A*Ainv≈I");
   end;

   ---------------------------------------------------------------------
   Section ("8. Partial pivoting required");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Needs_Pivot);
      B : constant Vector (1 .. 2) := [2.0, 3.0];
      R : constant Result := Solve (A, B);
      InvR : constant Invert_Result := Invert (A);
   begin
      Check (R.Success, "pivot case Success");
      Check (Approx (R.X (1), 3.0) and Approx (R.X (2), 2.0),
             "pivot case x=(3,2)");
      Check (R.Swap_Count >= 1, "at least one swap");
      Check (Approx (Determinant (A), -1.0), "Needs_Pivot det=-1");
      Check (Residual_Norm (A, R.X (1 .. 2), B) < 1.0E-5,
             "pivot residual");
      Check (InvR.Success, "Invert Needs_Pivot Success");
      Check (InvR.Swap_Count >= 1, "Invert Needs_Pivot swapped");
      Check (Inverse_Residual_Max_Abs (A, Leading_Square (InvR.Inv, 2))
               < 1.0E-5,
             "Needs_Pivot A*Ainv≈I");
   end;
   declare
      A : constant Matrix (1 .. 3, 1 .. 3) :=
        [[1.0E-14, 1.0, 0.0],
         [1.0,     2.0, 1.0],
         [0.0,     1.0, 2.0]];
      Xtrue : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      B : constant Vector := Make_RHS_From_Solution (A, Xtrue);
      R : constant Result := Solve (A, B);
   begin
      Check (R.Success, "tiny (1,1) Success");
      Check (R.Swap_Count >= 1, "tiny (1,1) swapped");
      Check (Residual_Norm (A, R.X (1 .. 3), B) < 1.0E-3,
             "tiny (1,1) residual");
   end;

   ---------------------------------------------------------------------
   Section ("9. Singular / zero pivot detection");
   ---------------------------------------------------------------------
   declare
      S : constant Matrix := Make_Example (Singular_2x2);
      B : constant Vector (1 .. 2) := [1.0, 2.0];
      R : constant Result := Solve (S, B);
      InvR : constant Invert_Result := Invert (S);
      Z : constant Matrix (1 .. 2, 1 .. 2) :=
        [[0.0, 0.0], [0.0, 0.0]];
      Rz : constant Result := Solve (Z, B);
   begin
      Check (not R.Success, "singular not Success");
      Check (R.Stat = Singular or R.Stat = Zero_Pivot, "singular status");
      Check (not InvR.Success, "singular Invert fails");
      Check (Rank (S) = 1, "singular rank=1");
      Check (Approx (Determinant (S), 0.0), "singular det=0");
      Check (not Rz.Success, "zero matrix fails");
      Check (Rank (Z) = 0, "zero matrix rank=0");
   end;
   declare
      A : constant Matrix (1 .. 3, 1 .. 3) :=
        [[1.0, 2.0, 3.0],
         [2.0, 4.0, 6.0],
         [1.0, 1.0, 1.0]];
      B : constant Vector (1 .. 3) := [1.0, 2.0, 0.0];
      R : constant Result := Solve (A, B);
      RR : constant RREF_Result := Reduce_To_RREF (A);
   begin
      Check (not R.Success, "rank-deficient 3x3 fails");
      Check (Rank (A) = 2, "rank-deficient rank=2");
      Check (RR.Success, "RREF completes on singular");
      Check (RR.Rank_Value = 2, "RREF Rank_Value=2");
      Check (RR.Stat = Singular, "RREF Stat=Singular");
   end;

   ---------------------------------------------------------------------
   Section ("10. Reduce_To_RREF full rank → Identity");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Example_3x3);
      RR : constant RREF_Result := Reduce_To_RREF (A);
      I : constant Matrix := Identity (3);
   begin
      Check (RR.Success and RR.Stat = Ok, "RREF full-rank Ok");
      Check (RR.Rank_Value = 3, "RREF rank=3");
      Check (Mat_Near (Leading_Square (RR.R, 3), I, 1.0E-5),
             "RREF of nonsingular = I");
   end;
   declare
      A : constant Matrix := Identity (5);
      RR : constant RREF_Result := Reduce_To_RREF (A);
   begin
      Check (RR.Rank_Value = 5 and RR.Stat = Ok, "RREF(I5)");
      Check (Mat_Near (Leading_Square (RR.R, 5), A, 1.0E-10),
             "RREF(I)=I");
   end;

   ---------------------------------------------------------------------
   Section ("11. Determinant sanity");
   ---------------------------------------------------------------------
   declare
      I : constant Matrix := Identity (5);
      A : constant Matrix (1 .. 2, 1 .. 2) := [[3.0, 0.0], [0.0, 4.0]];
      B : constant Matrix (1 .. 3, 1 .. 3) :=
        [[1.0, 2.0, 0.0],
         [0.0, 1.0, 0.0],
         [0.0, 0.0, 5.0]];
      Det : Float;
      Stat : Status;
   begin
      Check (Approx (Determinant (I), 1.0), "det(I)=1");
      Check (Approx (Determinant (A), 12.0), "diag det=12");
      Check (Approx (Determinant (B), 5.0), "triangular det=5");
      Determinant (A, Det, Stat);
      Check (Stat = Ok and Approx (Det, 12.0), "proc Determinant");
      Check (Rank (I) = 5, "rank(I)=5");
   end;
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) := [[0.0, 2.0], [3.0, 1.0]];
      Det : constant Float := Determinant (A);
   begin
      Check (Approx (Det, -6.0), "swap det=-6");
      Check (Solve (A, [1.0, 1.0]).Success, "swap 2x2 solves");
   end;

   ---------------------------------------------------------------------
   Section ("12. Diagonally dominant batch + Invert");
   ---------------------------------------------------------------------
   declare
      Count_Local : Natural := 0;
   begin
      for N in 2 .. 10 loop
         declare
            A : constant Matrix := Make_Diagonally_Dominant (N);
            Xtrue : Vector (1 .. N);
            B : Vector (1 .. N);
            R : Result;
            InvR : Invert_Result;
         begin
            for I in 1 .. N loop
               Xtrue (I) := Float (I);
            end loop;
            B := Make_RHS_From_Solution (A, Xtrue);
            R := Solve (A, B);
            InvR := Invert (A);
            if R.Success
              and then Residual_Norm (A, R.X (1 .. N), B) < 1.0E-3
              and then Vec_Near (R.X (1 .. N), Xtrue, 1.0E-3)
              and then InvR.Success
              and then Inverse_Residual_Max_Abs
                         (A, Leading_Square (InvR.Inv, N)) < 1.0E-3
            then
               Count_Local := Count_Local + 1;
            end if;
         end;
      end loop;
      Check (Count_Local = 9, "DD batch n=2..10 Solve+Invert");
   end;
   declare
      A : constant Matrix := Make_Diagonally_Dominant (8);
      B : constant Vector := Make_RHS_Ones (8);
      R : constant Result := Solve (A, B);
   begin
      Check (R.Success, "DD8 ones RHS Success");
      Check (Residual_Norm (A, R.X (1 .. 8), B) < 1.0E-4, "DD8 residual");
      Check (Is_Strictly_Diagonally_Dominant (A), "DD8 strictly DD");
      Check (Rank (A) = 8, "DD8 full rank");
   end;

   ---------------------------------------------------------------------
   Section ("13. Poisson 1D dense");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Poisson_1D (5);
      Xtrue : constant Vector (1 .. 5) := [1.0, 2.0, 3.0, 2.0, 1.0];
      B : constant Vector := Make_RHS_From_Solution (A, Xtrue);
      R : constant Result := Solve (A, B);
      InvR : constant Invert_Result := Invert (A);
   begin
      Check (R.Success, "Poisson5 Success");
      Check (Vec_Near (R.X (1 .. 5), Xtrue, 1.0E-4), "Poisson5 x");
      Check (Is_Diagonally_Dominant (A), "Poisson DD");
      Check (Residual_Norm (A, R.X (1 .. 5), B) < 1.0E-4,
             "Poisson5 residual");
      Check (InvR.Success, "Poisson5 Invert");
      Check (Inverse_Residual_Max_Abs (A, Leading_Square (InvR.Inv, 5))
               < 1.0E-4,
             "Poisson5 A*Ainv");
   end;
   declare
      A : constant Matrix := Make_Poisson_1D (16);
      B : constant Vector := Make_RHS_Ones (16);
      R : constant Result := Solve (A, B);
   begin
      Check (R.Success, "Poisson16 Success");
      Check (Residual_Norm (A, R.X (1 .. 16), B) < 1.0E-3,
             "Poisson16 residual");
      Check (R.X (1) > 0.0 and R.X (16) > 0.0, "Poisson16 positive ends");
      Check (Approx (R.X (1), R.X (16), 1.0E-3), "Poisson16 symmetry");
   end;

   ---------------------------------------------------------------------
   Section ("14. Hilbert tiny (ill-conditioned)");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Hilbert (3);
      Xtrue : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      B : constant Vector := Make_RHS_From_Solution (A, Xtrue);
      R : constant Result := Solve (A, B);
      InvR : constant Invert_Result := Invert (A);
   begin
      Check (R.Success, "Hilbert3 Success");
      Check (Residual_Norm (A, R.X (1 .. 3), B) < 1.0E-3,
             "Hilbert3 residual loose");
      Check (Rank (A) = 3, "Hilbert3 full rank");
      Check (InvR.Success, "Hilbert3 Invert Success");
      Check (Inverse_Residual_Max_Abs (A, Leading_Square (InvR.Inv, 3))
               < 1.0E-2,
             "Hilbert3 A*Ainv loose");
   end;
   declare
      A : constant Matrix := Make_Hilbert (4);
      B : constant Vector := Make_RHS_Ones (4);
      R : constant Result := Solve (A, B);
   begin
      Check (R.Success, "Hilbert4 Success");
      Check (Residual_Norm (A, R.X (1 .. 4), B) < 5.0E-2,
             "Hilbert4 residual very loose");
   end;

   ---------------------------------------------------------------------
   Section ("15. Residual helpers");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Identity (3);
      X : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      B : constant Vector (1 .. 3) := [1.0, 2.0, 4.0];
      R : constant Vector := Residual (A, X, B);
   begin
      Check (Approx (R (1), 0.0) and Approx (R (2), 0.0), "residual zeros");
      Check (Approx (R (3), 1.0), "residual last=1");
      Check (Approx (Residual_Norm (A, X, B), 1.0), "residual norm");
      Check (Approx (Residual_Max_Abs (A, X, B), 1.0), "residual max");
   end;

   ---------------------------------------------------------------------
   Section ("16. Larger DD / Invert round-trip / det");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonally_Dominant (12);
      B : constant Vector := Make_RHS_Ones (12, 2.0);
      R : constant Result := Solve (A, B);
      InvR : constant Invert_Result := Invert (A);
      Det : constant Float := Determinant (A);
   begin
      Check (R.Success, "DD12 Success");
      Check (Residual_Norm (A, R.X (1 .. 12), B) < 1.0E-3, "DD12 residual");
      Check (Rank (A) = 12, "DD12 rank");
      Check (abs (Det) > 0.0, "DD12 det nonzero");
      Check (InvR.Success, "DD12 Invert");
      Check (Inverse_Residual_Max_Abs (A, Leading_Square (InvR.Inv, 12))
               < 1.0E-3,
             "DD12 A*Ainv");
   end;

   ---------------------------------------------------------------------
   Section ("17. Make_Example aliases + upper/lower");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Identity, 3);
      P : constant Matrix := Make_Example (Poisson_1D, 3);
      D : constant Matrix := Make_Example (Diag_Dominant, 3);
      U : constant Matrix (1 .. 3, 1 .. 3) :=
        [[2.0, 1.0, 1.0],
         [0.0, 3.0, 1.0],
         [0.0, 0.0, 4.0]];
      Xtrue : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      Bu : constant Vector := Make_RHS_From_Solution (U, Xtrue);
      Ru : constant Result := Solve (U, Bu);
      L : constant Matrix (1 .. 3, 1 .. 3) :=
        [[3.0, 0.0, 0.0],
         [1.0, 2.0, 0.0],
         [1.0, 1.0, 1.0]];
      Bl : constant Vector := Make_RHS_From_Solution (L, Xtrue);
      Rl : constant Result := Solve (L, Bl);
   begin
      Check (Approx (A (2, 2), 1.0) and Approx (A (1, 2), 0.0),
             "Make_Example Identity");
      Check (Approx (P (2, 1), -1.0), "Make_Example Poisson");
      Check (Is_Diagonally_Dominant (D), "Make_Example DD");
      Check (Ru.Success and Vec_Near (Ru.X (1 .. 3), Xtrue, 1.0E-5),
             "upper Solve");
      Check (Rl.Success and Vec_Near (Rl.X (1 .. 3), Xtrue, 1.0E-5),
             "lower Solve");
      Check (Approx (Determinant (U), 24.0), "upper det=24");
      Check (Approx (Determinant (L), 6.0), "lower det=6");
   end;

   ---------------------------------------------------------------------
   Section ("18. Invert then Solve consistency");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonally_Dominant (5);
      Xtrue : constant Vector (1 .. 5) := [1.0, -1.0, 2.0, 0.5, -0.25];
      B : constant Vector := Make_RHS_From_Solution (A, Xtrue);
      R : constant Result := Solve (A, B);
      InvR : constant Invert_Result := Invert (A);
      Xvia : constant Vector :=
        Mat_Vec (Leading_Square (InvR.Inv, 5), B);
   begin
      Check (R.Success and InvR.Success, "Solve+Invert Success");
      Check (Vec_Near (R.X (1 .. 5), Xtrue, 1.0E-4), "Solve x");
      Check (Vec_Near (Xvia, Xtrue, 1.0E-4), "Ainv*b = x");
      Check (Vec_Near (R.X (1 .. 5), Xvia, 1.0E-4), "Solve ≡ Invert path");
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
