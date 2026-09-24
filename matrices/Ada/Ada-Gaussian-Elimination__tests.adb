--  Standalone test suite for Gaussian_Elimination (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Gaussian_Elimination; use Gaussian_Elimination;

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
   Ada.Text_IO.Put_Line ("Gaussian_Elimination (GEPP) test suite");
   Ada.Text_IO.Put_Line ("======================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Vec_Near / Norm2 / Max_Abs / Dot");
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
   Section ("2. Identity / Mat_Vec / Is_Square / DD");
   ---------------------------------------------------------------------
   declare
      I3 : constant Matrix := Identity (3);
      X  : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      Y  : constant Vector := Mat_Vec (I3, X);
      A  : constant Matrix := Make_Diagonally_Dominant (4);
      W  : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 2.0], [3.0, 0.0]];
   begin
      Check (Is_Square (I3), "Identity square");
      Check (Approx (I3 (1, 1), 1.0) and Approx (I3 (2, 3), 0.0),
             "Identity entries");
      Check (Vec_Near (Y, X), "Mat_Vec Identity");
      Check (Is_Diagonally_Dominant (A), "DD builder is DD");
      Check (Is_Strictly_Diagonally_Dominant (A), "DD builder strictly DD");
      Check (not Is_Diagonally_Dominant (W), "weak row rejects DD");
      Check (Is_Square (W), "2x2 square");
   end;

   ---------------------------------------------------------------------
   Section ("3. Builders: Hilbert / Poisson / examples / RHS");
   ---------------------------------------------------------------------
   declare
      H : constant Matrix := Make_Hilbert (3);
      P : constant Matrix := Make_Poisson_1D (4);
      E2 : constant Matrix := Make_Example (Example_2x2);
      E3 : constant Matrix := Make_Example (Example_3x3);
      NP : constant Matrix := Make_Example (Needs_Pivot);
      Z : constant Vector := Zero_Vector (3);
      O : constant Vector := Make_RHS_Ones (3, 7.0);
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
      Check (Approx (Z (2), 0.0), "Zero_Vector");
      Check (Approx (O (1), 7.0) and Approx (O (3), 7.0), "RHS ones");
   end;

   ---------------------------------------------------------------------
   Section ("4. Identity systems");
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
   --  [2 1; 1 2] [x;y] = [3;3] => x=y=1
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
   --  [2 1 0; 1 4 1; 0 1 2] x = b with x=(1,2,3)
   declare
      A : constant Matrix := Make_Example (Example_3x3);
      Xtrue : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      B : constant Vector := Make_RHS_From_Solution (A, Xtrue);
      R : constant Result := Solve (A, B);
      F : constant Factor_Result := Factor (A, B);
      R2 : constant Result := Back_Substitute (F);
   begin
      Check (R.Success, "3x3 Success");
      Check (Vec_Near (R.X (1 .. 3), Xtrue, 1.0E-5), "3x3 solution");
      Check (Residual_Max_Abs (A, R.X (1 .. 3), B) < 1.0E-5,
             "3x3 max|r|");
      Check (F.Success, "Factor Success");
      Check (R2.Success and Vec_Near (R2.X (1 .. 3), Xtrue, 1.0E-5),
             "Back_Substitute matches");
      Check (Eliminate (A, B).Success, "Eliminate alias");
   end;

   ---------------------------------------------------------------------
   Section ("7. Upper / lower triangular");
   ---------------------------------------------------------------------
   declare
      U : constant Matrix (1 .. 3, 1 .. 3) :=
        [[2.0, 1.0, 1.0],
         [0.0, 3.0, 1.0],
         [0.0, 0.0, 4.0]];
      Xtrue : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      B : constant Vector := Make_RHS_From_Solution (U, Xtrue);
      R : constant Result := Solve (U, B);
      L : constant Matrix (1 .. 3, 1 .. 3) :=
        [[3.0, 0.0, 0.0],
         [1.0, 2.0, 0.0],
         [1.0, 1.0, 1.0]];
      Bl : constant Vector := Make_RHS_From_Solution (L, Xtrue);
      Rl : constant Result := Solve (L, Bl);
   begin
      Check (R.Success, "upper Success");
      Check (Vec_Near (R.X (1 .. 3), Xtrue, 1.0E-5), "upper x");
      Check (Rl.Success, "lower Success");
      Check (Vec_Near (Rl.X (1 .. 3), Xtrue, 1.0E-5), "lower x");
      Check (Approx (Determinant (U), 24.0), "upper det=24");
      Check (Approx (Determinant (L), 6.0), "lower det=6");
   end;

   ---------------------------------------------------------------------
   Section ("8. Partial pivoting required");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Needs_Pivot);
      B : constant Vector (1 .. 2) := [2.0, 3.0];
      --  [0 1; 1 0] [x;y] = [2;3] => x=3, y=2
      R : constant Result := Solve (A, B);
      F : constant Factor_Result := Factor (A, B);
   begin
      Check (R.Success, "pivot case Success");
      Check (Approx (R.X (1), 3.0) and Approx (R.X (2), 2.0),
             "pivot case x=(3,2)");
      Check (R.Swap_Count >= 1, "at least one swap");
      Check (F.Swap_Count >= 1, "Factor reports swap");
      Check (F.Det_Sign = -1, "one swap flips Det_Sign");
      Check (Approx (Determinant (A), -1.0), "Needs_Pivot det=-1");
      Check (Residual_Norm (A, R.X (1 .. 2), B) < 1.0E-5,
             "pivot residual");
   end;
   --  Another swap case: small (1,1) entry
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
      S : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 2.0], [2.0, 4.0]];  --  rank 1
      B : constant Vector (1 .. 2) := [1.0, 2.0];
      R : constant Result := Solve (S, B);
      Z : constant Matrix (1 .. 2, 1 .. 2) :=
        [[0.0, 0.0], [0.0, 0.0]];
      Rz : constant Result := Solve (Z, B);
   begin
      Check (not R.Success, "singular not Success");
      Check (R.Stat = Singular or R.Stat = Zero_Pivot, "singular status");
      Check (Rank (S) = 1, "singular rank=1");
      Check (Approx (Determinant (S), 0.0), "singular det=0");
      Check (not Rz.Success, "zero matrix fails");
      Check (Rank (Z) = 0, "zero matrix rank=0");
   end;
   declare
      A : constant Matrix (1 .. 3, 1 .. 3) :=
        [[1.0, 2.0, 3.0],
         [2.0, 4.0, 6.0],
         [1.0, 1.0, 1.0]];  --  rows 1,2 dependent
      B : constant Vector (1 .. 3) := [1.0, 2.0, 0.0];
      R : constant Result := Solve (A, B);
   begin
      Check (not R.Success, "rank-deficient 3x3 fails");
      Check (Rank (A) = 2, "rank-deficient rank=2");
   end;

   ---------------------------------------------------------------------
   Section ("10. Determinant sanity");
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

   ---------------------------------------------------------------------
   Section ("11. Diagonally dominant deterministic systems");
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
         begin
            for I in 1 .. N loop
               Xtrue (I) := Float (I);
            end loop;
            B := Make_RHS_From_Solution (A, Xtrue);
            R := Solve (A, B);
            if R.Success
              and then Residual_Norm (A, R.X (1 .. N), B) < 1.0E-3
              and then Vec_Near (R.X (1 .. N), Xtrue, 1.0E-3)
            then
               Count_Local := Count_Local + 1;
            end if;
         end;
      end loop;
      Check (Count_Local = 9, "DD batch n=2..10 all ok");
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
   Section ("12. Poisson 1D dense");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Poisson_1D (5);
      Xtrue : constant Vector (1 .. 5) := [1.0, 2.0, 3.0, 2.0, 1.0];
      B : constant Vector := Make_RHS_From_Solution (A, Xtrue);
      R : constant Result := Solve (A, B);
   begin
      Check (R.Success, "Poisson5 Success");
      Check (Vec_Near (R.X (1 .. 5), Xtrue, 1.0E-4), "Poisson5 x");
      Check (Is_Diagonally_Dominant (A), "Poisson DD");
      Check (Residual_Norm (A, R.X (1 .. 5), B) < 1.0E-4,
             "Poisson5 residual");
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
   Section ("13. Hilbert tiny (ill-conditioned)");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Hilbert (3);
      Xtrue : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      B : constant Vector := Make_RHS_From_Solution (A, Xtrue);
      R : constant Result := Solve (A, B);
   begin
      Check (R.Success, "Hilbert3 Success");
      --  Ill-conditioned: allow looser residual / solution tol
      Check (Residual_Norm (A, R.X (1 .. 3), B) < 1.0E-3,
             "Hilbert3 residual loose");
      Check (Rank (A) = 3, "Hilbert3 full rank");
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
   Section ("14. Factor then Back_Substitute round-trip");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonally_Dominant (6);
      Xtrue : constant Vector (1 .. 6) :=
        [0.5, -1.0, 2.0, 0.0, 3.0, -0.25];
      B : constant Vector := Make_RHS_From_Solution (A, Xtrue);
      F : constant Factor_Result := Factor (A, B);
      R : constant Result := Back_Substitute (F);
      E : constant Factor_Result := Eliminate (A, B);
   begin
      Check (F.Success and E.Success, "Factor/Eliminate Success");
      Check (R.Success, "Back_Sub Success");
      Check (Vec_Near (R.X (1 .. 6), Xtrue, 1.0E-4), "round-trip x");
      Check (F.N = 6 and R.N = 6, "N preserved");
   end;

   ---------------------------------------------------------------------
   Section ("15. Residual helpers");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Identity (3);
      X : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      B : constant Vector (1 .. 3) := [1.0, 2.0, 4.0];  --  mismatch last
      R : constant Vector := Residual (A, X, B);
   begin
      Check (Approx (R (1), 0.0) and Approx (R (2), 0.0), "residual zeros");
      Check (Approx (R (3), 1.0), "residual last=1");
      Check (Approx (Residual_Norm (A, X, B), 1.0), "residual norm");
      Check (Approx (Residual_Max_Abs (A, X, B), 1.0), "residual max");
   end;

   ---------------------------------------------------------------------
   Section ("16. Larger DD / det product");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Diagonally_Dominant (12);
      B : constant Vector := Make_RHS_Ones (12, 2.0);
      R : constant Result := Solve (A, B);
      Det : constant Float := Determinant (A);
   begin
      Check (R.Success, "DD12 Success");
      Check (Residual_Norm (A, R.X (1 .. 12), B) < 1.0E-3, "DD12 residual");
      Check (Rank (A) = 12, "DD12 rank");
      Check (abs (Det) > 0.0, "DD12 det nonzero");
   end;
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) := [[0.0, 2.0], [3.0, 1.0]];
      --  det = 0*1 - 2*3 = -6; with one swap: U diag product * (-1)
      Det : constant Float := Determinant (A);
   begin
      Check (Approx (Det, -6.0), "swap det=-6");
      Check (Solve (A, [1.0, 1.0]).Success, "swap 2x2 solves");
   end;

   ---------------------------------------------------------------------
   Section ("17. Make_Example Identity / Poisson aliases");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Identity, 3);
      P : constant Matrix := Make_Example (Poisson_1D, 3);
      D : constant Matrix := Make_Example (Diag_Dominant, 3);
   begin
      Check (Approx (A (2, 2), 1.0) and Approx (A (1, 2), 0.0),
             "Make_Example Identity");
      Check (Approx (P (2, 1), -1.0), "Make_Example Poisson");
      Check (Is_Diagonally_Dominant (D), "Make_Example DD");
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
