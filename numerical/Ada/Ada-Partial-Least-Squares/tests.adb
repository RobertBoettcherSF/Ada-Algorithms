--  Standalone test suite for Partial_Least_Squares (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Partial_Least_Squares; use Partial_Least_Squares;

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
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Put_Line ("Partial_Least_Squares test suite");
   Put_Line ("================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Dot / Norm2 / Scale / Axpy");
   ---------------------------------------------------------------------
   declare
      A : Vector := [1.0, 2.0, 3.0];
      B : constant Vector := [4.0, 5.0, 6.0];
      C : constant Vector := [1.0, 0.0, 0.0];
   begin
      Check (Near (1.0, 1.0 + 1.0E-9), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Approx (Dot (A, B), 32.0), "Dot [1,2,3]·[4,5,6]=32");
      Check (Approx (Norm2 (C), 1.0), "Norm2 e1 = 1");
      Check (Approx (Norm2 (A), 3.74165738677, 1.0E-5),
             "Norm2 [1,2,3] ≈ √14");
      Scale (A, 2.0);
      Check (Approx (A (1), 2.0) and then Approx (A (2), 4.0)
               and then Approx (A (3), 6.0),
             "Scale *2");
      Axpy (A, 1.0, B);
      Check (Approx (A (1), 6.0) and then Approx (A (2), 9.0)
               and then Approx (A (3), 12.0),
             "Axpy A:=A+B");
   end;

   ---------------------------------------------------------------------
   Section ("2. Mat_Vec / Mat_T_Vec / Outer_Add");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 3) :=
        [[1.0, 2.0, 3.0],
         [4.0, 5.0, 6.0]];
      X : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      Y : Vector (1 .. 2);
      Z : Vector (1 .. 3);
      U : constant Vector (1 .. 2) := [1.0, 2.0];
      V : constant Vector (1 .. 3) := [1.0, 0.0, -1.0];
      M : Matrix (1 .. 2, 1 .. 3) := [others => [others => 0.0]];
      Ones : constant Vector (1 .. 2) := [1.0, 1.0];
   begin
      Mat_Vec (A, X, Y);
      Check (Approx (Y (1), 6.0) and then Approx (Y (2), 15.0),
             "Mat_Vec row sums");
      Mat_T_Vec (A, Ones, Z);
      Check (Approx (Z (1), 5.0) and then Approx (Z (2), 7.0)
               and then Approx (Z (3), 9.0),
             "Mat_T_Vec column sums");
      Outer_Add (M, 1.0, U, V);
      Check (Approx (M (1, 1), 1.0) and then Approx (M (1, 3), -1.0)
               and then Approx (M (2, 1), 2.0) and then Approx (M (2, 3), -2.0)
               and then Approx (M (1, 2), 0.0),
             "Outer_Add u v^T");
   end;

   ---------------------------------------------------------------------
   Section ("3. Column means / centering / standardize");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 10.0],
         [3.0, 20.0],
         [5.0, 30.0]];
      Means : Vector (1 .. 2);
      Stds  : Vector (1 .. 2);
      B     : Matrix (1 .. 3, 1 .. 2);
      S     : Real;
   begin
      Column_Means (A, Means);
      Check (Approx (Means (1), 3.0) and then Approx (Means (2), 20.0),
             "Column_Means");
      B := A;
      Mean_Center_Columns (B, Means);
      Check (Approx (B (1, 1), -2.0) and then Approx (B (2, 1), 0.0)
               and then Approx (B (3, 1), 2.0),
             "Mean_Center col1");
      Check (Approx (B (1, 2), -10.0) and then Approx (B (3, 2), 10.0),
             "Mean_Center col2");
      B := A;
      Standardize_Columns (B, Means, Stds);
      Check (Approx (Stds (1), 1.63299316186, 1.0E-5),
             "Std col1 ≈ √(8/3)");
      S := 0.0;
      for I in 1 .. 3 loop
         S := S + B (I, 1);
      end loop;
      Check (Approx (S, 0.0, 1.0E-8), "Standardized col1 mean ~0");
   end;

   ---------------------------------------------------------------------
   Section ("4. OLS_1D / R_Squared / RMSE");
   ---------------------------------------------------------------------
   declare
      X : constant Vector := [1.0, 2.0, 3.0, 4.0, 5.0];
      Y : constant Vector := [2.0, 4.0, 6.0, 8.0, 10.0];
      Slope : Real;
      Raised : Boolean := False;
      Yc, Hc : Vector (1 .. 5);
      My : Real := 0.0;
   begin
      Slope := Ordinary_Least_Squares_1D (X, Y);
      Check (Approx (Slope, 2.0), "OLS_1D slope = 2");
      for I in 1 .. 5 loop
         My := My + Y (I);
      end loop;
      My := My / 5.0;
      for I in 1 .. 5 loop
         Yc (I) := Y (I) - My;
         Hc (I) := Slope * (X (I) - 3.0);
      end loop;
      Check (Approx (R_Squared (Yc, Hc), 1.0, 1.0E-8),
             "R² demeaned OLS = 1");
      Check (Approx (RMSE (Yc, Hc), 0.0, 1.0E-8),
             "RMSE demeaned OLS = 0");
      begin
         declare
            U : Real;
            Zx : constant Vector := [1.0, 1.0, 1.0];
            Zy : constant Vector := [1.0, 2.0, 3.0];
         begin
            U := Ordinary_Least_Squares_1D (Zx, Zy);
            pragma Unreferenced (U);
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "OLS_1D zero-var raises Degenerate_Geometry");
      Check (Approx (R_Squared (Y, Y), 1.0), "R² identical = 1");
      Check (Approx (RMSE (Y, Y), 0.0), "RMSE identical = 0");
   end;

   ---------------------------------------------------------------------
   Section ("5. PLS1 recovers y = a·x + b (1 component)");
   ---------------------------------------------------------------------
   declare
      X : Matrix (1 .. 8, 1 .. 1);
      Y : Vector (1 .. 8);
      M : PLS1_Model;
      Hat : Vector (1 .. 8);
      A : constant Real := 3.5;
      B0 : constant Real := -1.25;
   begin
      for I in 1 .. 8 loop
         X (I, 1) := Real (I);
         Y (I) := A * Real (I) + B0;
      end loop;
      M := PLS1_Fit (X, Y, 1, Center => True);
      Check (M.N_Components = 1, "PLS1 1-comp used 1 component");
      Check (Approx (M.B (1), A, 1.0E-6), "PLS1 slope ≈ 3.5");
      Check (Approx (M.B0, B0, 1.0E-6), "PLS1 intercept ≈ -1.25");
      Hat := PLS1_Predict (M, X);
      Check (Approx (R_Squared (Y, Hat), 1.0, 1.0E-8),
             "PLS1 noiseless R² ≈ 1");
      Check (Approx (RMSE (Y, Hat), 0.0, 1.0E-7),
             "PLS1 noiseless RMSE ≈ 0");
      for I in 1 .. 8 loop
         Check (Approx (Hat (I), Y (I), 1.0E-6),
                "PLS1 predict matches train @" & Integer'Image (I));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("6. PLS1 ≈ OLS for single predictor");
   ---------------------------------------------------------------------
   declare
      Xv : constant Vector :=
        [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0];
      Yv : Vector (1 .. 8);
      Xm : Matrix (1 .. 8, 1 .. 1);
      Slope : Real;
      M : PLS1_Model;
   begin
      for I in 1 .. 8 loop
         Yv (I) := -2.0 * Xv (I) + 7.0;
         Xm (I, 1) := Xv (I);
      end loop;
      Slope := Ordinary_Least_Squares_1D (Xv, Yv);
      M := PLS1_Fit (Xm, Yv, 1, Center => True);
      Check (Approx (Slope, -2.0), "OLS slope -2");
      Check (Approx (M.B (1), Slope, 1.0E-6),
             "1-var PLS ≈ OLS slope");
      Check (Approx (M.B0, 7.0, 1.0E-6), "1-var PLS intercept");
   end;

   ---------------------------------------------------------------------
   Section ("7. Multicollinear X: duplicate columns");
   ---------------------------------------------------------------------
   declare
      X : Matrix (1 .. 10, 1 .. 2);
      Y : Vector (1 .. 10);
      M : PLS1_Model;
      Hat : Vector (1 .. 10);
   begin
      for I in 1 .. 10 loop
         X (I, 1) := Real (I) - 5.5;
         X (I, 2) := X (I, 1);
         Y (I) := 2.0 * X (I, 1) + 1.0;
      end loop;
      M := PLS1_Fit (X, Y, 1, Center => True);
      Hat := PLS1_Predict (M, X);
      Check (M.N_Components >= 1, "multicollinear: got ≥1 component");
      Check (Approx (R_Squared (Y, Hat), 1.0, 1.0E-6),
             "multicollinear PLS R² ≈ 1");
      Check (Approx (RMSE (Y, Hat), 0.0, 1.0E-5),
             "multicollinear PLS RMSE ≈ 0");
      Check (Approx (M.B (1) + M.B (2), 2.0, 1.0E-5),
             "B1+B2 ≈ 2 under duplicate cols");
   end;

   ---------------------------------------------------------------------
   Section ("8. Wide X: more variables than samples");
   ---------------------------------------------------------------------
   declare
      N : constant := 6;
      Mcols : constant := 12;
      X : Matrix (1 .. N, 1 .. Mcols);
      Y : Vector (1 .. N);
      True_B : Vector (1 .. Mcols) := [others => 0.0];
      Model : PLS1_Model;
      Hat : Vector (1 .. N);
      Seed : Real;
      R2 : Real;
   begin
      True_B (1) := 1.5;
      True_B (2) := -0.8;
      True_B (3) := 0.4;
      for I in 1 .. N loop
         Seed := Real (I);
         for J in 1 .. Mcols loop
            X (I, J) := Seed * Real (J) * 0.1
              + Real ((I * 7 + J * 3) rem 11) * 0.05;
         end loop;
         Y (I) := 2.0;
         for J in 1 .. Mcols loop
            Y (I) := Y (I) + True_B (J) * X (I, J);
         end loop;
      end loop;
      Model := PLS1_Fit (X, Y, 3, Center => True);
      Hat := PLS1_Predict (Model, X);
      R2 := R_Squared (Y, Hat);
      Check (Model.N_Components >= 1, "wide: components extracted");
      Check (R2 > 0.98, "wide X in-sample R² high");
      Check (RMSE (Y, Hat) < 0.05, "wide X in-sample RMSE low");
   end;

   ---------------------------------------------------------------------
   Section ("9. Multi-predictor linear recovery (2 comps)");
   ---------------------------------------------------------------------
   declare
      X : Matrix (1 .. 12, 1 .. 3);
      Y : Vector (1 .. 12);
      M : PLS1_Model;
      Hat : Vector (1 .. 12);
   begin
      for I in 1 .. 12 loop
         X (I, 1) := Real (I);
         X (I, 2) := Real (I) ** 2 * 0.05;
         X (I, 3) := Real ((I * 3) rem 7);
         Y (I) := 1.0 * X (I, 1) - 2.0 * X (I, 2) + 0.5 * X (I, 3) + 4.0;
      end loop;
      M := PLS1_Fit (X, Y, 3, Center => True);
      Hat := PLS1_Predict (M, X);
      Check (M.N_Components = 3, "3-col full rank → 3 comps");
      Check (Approx (R_Squared (Y, Hat), 1.0, 1.0E-6),
             "3-var linear R² ≈ 1");
      Check (Approx (M.B (1), 1.0, 1.0E-4), "B1 ≈ 1");
      Check (Approx (M.B (2), -2.0, 1.0E-4), "B2 ≈ -2");
      Check (Approx (M.B (3), 0.5, 1.0E-4), "B3 ≈ 0.5");
      Check (Approx (M.B0, 4.0, 1.0E-4), "B0 ≈ 4");
   end;

   ---------------------------------------------------------------------
   Section ("10. Component limits / early stop");
   ---------------------------------------------------------------------
   declare
      X : Matrix (1 .. 5, 1 .. 2);
      Y : Vector (1 .. 5);
      M1, M2, M3 : PLS1_Model;
   begin
      for I in 1 .. 5 loop
         X (I, 1) := Real (I);
         X (I, 2) := Real (I) * 2.0;
         Y (I) := 3.0 * Real (I) + 1.0;
      end loop;
      M1 := PLS1_Fit (X, Y, 1, Center => True);
      M2 := PLS1_Fit (X, Y, 2, Center => True);
      M3 := PLS1_Fit (X, Y, 10, Center => True);
      Check (M1.N_Components = 1, "request 1 → 1 component");
      Check (M2.N_Components <= 2, "request 2 → ≤2 components");
      Check (M3.N_Components <= 2, "request 10 early-stops ≤ rank");
      Check (Approx (R_Squared (Y, PLS1_Predict (M1, X)), 1.0, 1.0E-6),
             "1-comp enough for rank-1 signal");
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid dimensions raise");
   ---------------------------------------------------------------------
   declare
      X : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]];
      Y : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      M : PLS1_Model;
      Raised : Boolean;
   begin
      M := PLS1_Fit (X, Y, 1, Center => True);
      Raised := False;
      begin
         declare
            Bad : constant Matrix (1 .. 2, 1 .. 3) :=
              [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]];
            Unused : Vector (1 .. 2);
         begin
            Unused := PLS1_Predict (M, Bad);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Predict col mismatch raises");

      Raised := False;
      declare
         Zx : constant Matrix (1 .. 4, 1 .. 2) :=
           [others => [others => 0.0]];
         Zy : constant Vector (1 .. 4) := [1.0, 2.0, 3.0, 4.0];
         Mz : PLS1_Model;
      begin
         Mz := PLS1_Fit (Zx, Zy, 2, Center => True);
         Check (Mz.N_Components = 0, "all-zero X → 0 components");
         Raised := True;
      exception
         when Degenerate_Geometry =>
            Raised := True;
            Check (True, "all-zero X raised Degenerate_Geometry");
         when others =>
            Raised := False;
      end;
      Check (Raised, "zero-X handled (0 comps or raise)");
   end;

   ---------------------------------------------------------------------
   Section ("12. Predict matches training reconstruction");
   ---------------------------------------------------------------------
   declare
      X : Matrix (1 .. 9, 1 .. 2);
      Y : Vector (1 .. 9);
      M : PLS1_Model;
      Hat : Vector (1 .. 9);
      Max_Err : Real := 0.0;
   begin
      for I in 1 .. 9 loop
         X (I, 1) := Real (I) * 0.3;
         X (I, 2) := Real (10 - I) * 0.7;
         Y (I) := 0.5 * X (I, 1) + 1.5 * X (I, 2) - 3.0;
      end loop;
      M := PLS1_Fit (X, Y, 2, Center => True);
      Hat := PLS1_Predict (M, X);
      for I in 1 .. 9 loop
         Max_Err := Real'Max (Max_Err, abs (Hat (I) - Y (I)));
      end loop;
      Check (Max_Err < 1.0E-6, "max |ŷ−y| < 1e-6 on train");
      Check (M.Centered, "model reports Centered");
      Check (M.N_Rows = 9 and then M.N_Cols = 2, "model dims stored");
   end;

   ---------------------------------------------------------------------
   Section ("13. Uncentered PLS1 still fits through origin shift");
   ---------------------------------------------------------------------
   declare
      X : Matrix (1 .. 6, 1 .. 1);
      Y : Vector (1 .. 6);
      M : PLS1_Model;
      Hat : Vector (1 .. 6);
   begin
      for I in 1 .. 6 loop
         X (I, 1) := Real (I);
         Y (I) := 2.0 * Real (I);
      end loop;
      M := PLS1_Fit (X, Y, 1, Center => False);
      Hat := PLS1_Predict (M, X);
      Check (not M.Centered, "Center=False stored");
      Check (Approx (M.B0, 0.0), "uncentered B0 = 0");
      Check (R_Squared (Y, Hat) > 0.999, "uncentered fit still excellent");
   end;

   ---------------------------------------------------------------------
   Section ("14. PLS2: two responses sharing latent structure");
   ---------------------------------------------------------------------
   declare
      X : Matrix (1 .. 10, 1 .. 3);
      Y : Y_Matrix (1 .. 10, 1 .. 2);
      M : PLS2_Model;
      Hat : Y_Matrix (1 .. 10, 1 .. 2);
      Latent : Real;
      Err1, Err2 : Real := 0.0;
      Y1, H1, Y2, H2 : Vector (1 .. 10);
   begin
      for I in 1 .. 10 loop
         Latent := Real (I) - 5.5;
         X (I, 1) := Latent + 0.1 * Real (I rem 3);
         X (I, 2) := 0.5 * Latent;
         X (I, 3) := -0.2 * Latent + 0.05 * Real (I);
         Y (I, 1) := 2.0 * Latent + 1.0;
         Y (I, 2) := -1.0 * Latent + 0.5;
      end loop;
      M := PLS2_Fit (X, Y, 2, Center => True);
      Hat := PLS2_Predict (M, X);
      Check (M.N_Responses = 2, "PLS2 N_Responses=2");
      Check (M.N_Components >= 1, "PLS2 extracted ≥1 component");
      for I in 1 .. 10 loop
         Err1 := Err1 + (Hat (I, 1) - Y (I, 1)) ** 2;
         Err2 := Err2 + (Hat (I, 2) - Y (I, 2)) ** 2;
         Y1 (I) := Y (I, 1);
         H1 (I) := Hat (I, 1);
         Y2 (I) := Y (I, 2);
         H2 (I) := Hat (I, 2);
      end loop;
      Check (Err1 < 1.0E-4, "PLS2 Y1 reconstruction SSE low");
      Check (Err2 < 1.0E-4, "PLS2 Y2 reconstruction SSE low");
      Check (R_Squared (Y1, H1) > 0.999, "PLS2 Y1 R² > 0.999");
      Check (R_Squared (Y2, H2) > 0.999, "PLS2 Y2 R² > 0.999");
   end;

   ---------------------------------------------------------------------
   Section ("15. Solve_Dense identity / small system");
   ---------------------------------------------------------------------
   declare
      A : Square (1 .. 2, 1 .. 2) := [[2.0, 0.0], [0.0, 3.0]];
      Q : constant Vector (1 .. 2) := [4.0, 9.0];
      Z : Vector (1 .. 2);
      Raised : Boolean := False;
   begin
      Solve_Dense (A, Q, Z);
      Check (Approx (Z (1), 2.0) and then Approx (Z (2), 3.0),
             "Solve_Dense diag system");
      begin
         declare
            S : Square (1 .. 2, 1 .. 2) := [[0.0, 0.0], [0.0, 0.0]];
            R : constant Vector (1 .. 2) := [1.0, 1.0];
            W : Vector (1 .. 2);
         begin
            Solve_Dense (S, R, W);
            pragma Unreferenced (W);
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Solve_Dense singular raises");
   end;

   ---------------------------------------------------------------------
   Section ("16. W unit-norm / T orthogonality smoke");
   ---------------------------------------------------------------------
   declare
      X : Matrix (1 .. 8, 1 .. 3);
      Y : Vector (1 .. 8);
      M : PLS1_Model;
      Nw : Real;
      Dot_T : Real;
   begin
      for I in 1 .. 8 loop
         X (I, 1) := Real (I);
         X (I, 2) := Real (I) ** 2 * 0.1;
         X (I, 3) := Real (9 - I);
         Y (I) := X (I, 1) + 0.5 * X (I, 2) - X (I, 3);
      end loop;
      M := PLS1_Fit (X, Y, 2, Center => True);
      Check (M.N_Components = 2, "got 2 components for ortho check");
      Nw := 0.0;
      for J in 1 .. 3 loop
         Nw := Nw + M.W (J, 1) ** 2;
      end loop;
      Check (Approx (Nw, 1.0, 1.0E-8), "||w1|| = 1");
      Nw := 0.0;
      for J in 1 .. 3 loop
         Nw := Nw + M.W (J, 2) ** 2;
      end loop;
      Check (Approx (Nw, 1.0, 1.0E-8), "||w2|| = 1");
      Dot_T := 0.0;
      for I in 1 .. 8 loop
         Dot_T := Dot_T + M.T (I, 1) * M.T (I, 2);
      end loop;
      Check (Approx (Dot_T, 0.0, 1.0E-6), "t1 ⊥ t2");
   end;


   ---------------------------------------------------------------------
   Section ("17. Extra numeric / predict batch checks");
   ---------------------------------------------------------------------
   declare
      X : Matrix (1 .. 5, 1 .. 2);
      Y : Vector (1 .. 5);
      M : PLS1_Model;
      Hat : Vector (1 .. 5);
      V : constant Vector := [3.0, 4.0];
      Z : Vector := [0.0, 0.0, 0.0];
   begin
      Check (Approx (Norm2 (V), 5.0), "3-4-5 Norm2");
      Check (Approx (Dot (V, V), 25.0), "Dot V·V = 25");
      Check (Near (0.0, 0.0), "Near(0,0)");
      Check (not Near (0.0, 1.0, 0.5), "Near rejects 0 vs 1 tol 0.5");
      Scale (Z, 5.0);
      Check (Approx (Z (1), 0.0) and then Approx (Z (3), 0.0),
             "Scale zero stays zero");
      for I in 1 .. 5 loop
         X (I, 1) := Real (I) - 3.0;
         X (I, 2) := Real ((I * 2) rem 5);  -- not collinear with X1
         Y (I) := 4.0 * X (I, 1) - 1.0 * X (I, 2) + 2.0;
      end loop;
      M := PLS1_Fit (X, Y, 2, Center => True);
      Hat := PLS1_Predict (M, X);
      Check (Approx (M.B (1), 4.0, 1.0E-4), "batch B1 ≈ 4");
      Check (Approx (M.B (2), -1.0, 1.0E-4), "batch B2 ≈ -1");
      Check (Approx (M.B0, 2.0, 1.0E-4), "batch B0 ≈ 2");
      Check (Approx (R_Squared (Y, Hat), 1.0, 1.0E-8), "batch R²=1");
      Check (Approx (RMSE (Y, Hat), 0.0, 1.0E-7), "batch RMSE=0");
      Check (M.N_Components = 2, "batch comps = 2");
      for I in 1 .. 5 loop
         Check (Approx (Hat (I), Y (I), 1.0E-5),
                "batch ŷ=y @" & Integer'Image (I));
      end loop;
      declare
         Xn : constant Matrix (1 .. 2, 1 .. 2) :=
           [[1.0, 2.0], [-1.0, 0.0]];
         Yn : Vector (1 .. 2);
      begin
         Yn := PLS1_Predict (M, Xn);
         Check (Approx (Yn (1), 4.0 * 1.0 - 1.0 * 2.0 + 2.0, 1.0E-3),
                "holdout predict (1,2)");
         Check (Approx (Yn (2), 4.0 * (-1.0) - 1.0 * 0.0 + 2.0, 1.0E-3),
                "holdout predict (-1,0)");
      end;
      Check (Approx (Ordinary_Least_Squares_1D
               ([1.0, 2.0, 3.0], [2.0, 4.0, 6.0]), 2.0),
             "OLS batch slope 2");
      Check (R_Squared ([1.0, 2.0, 3.0], [1.1, 2.1, 2.9]) > 0.95,
             "noisy R² still high");
      Check (RMSE ([1.0, 2.0, 3.0], [1.0, 2.0, 4.0]) > 0.5,
             "RMSE detects error");
   end;

   ---------------------------------------------------------------------
   Section ("18. PLS2 single-response degenerates sensibly");
   ---------------------------------------------------------------------
   declare
      X : Matrix (1 .. 8, 1 .. 2);
      Y : Y_Matrix (1 .. 8, 1 .. 1);
      M2 : PLS2_Model;
      M1 : PLS1_Model;
      Hat2 : Y_Matrix (1 .. 8, 1 .. 1);
      Yv, H1 : Vector (1 .. 8);
   begin
      for I in 1 .. 8 loop
         X (I, 1) := Real (I);
         X (I, 2) := Real (9 - I);
         Y (I, 1) := 0.7 * X (I, 1) - 0.3 * X (I, 2) + 1.5;
         Yv (I) := Y (I, 1);
      end loop;
      M2 := PLS2_Fit (X, Y, 2, Center => True);
      M1 := PLS1_Fit (X, Yv, 2, Center => True);
      Hat2 := PLS2_Predict (M2, X);
      H1 := PLS1_Predict (M1, X);
      Check (M2.N_Components >= 1, "PLS2 p=1 got ≥1 comps");
      Check (Approx (M2.B (1, 1), M1.B (1), 1.0E-4),
             "PLS2≈PLS1 B1 when p=1");
      Check (Approx (M2.B (2, 1), M1.B (2), 1.0E-4),
             "PLS2≈PLS1 B2 when p=1");
      Check (Approx (M2.B0 (1), M1.B0, 1.0E-4),
             "PLS2≈PLS1 B0 when p=1");
      for I in 1 .. 8 loop
         Check (Approx (Hat2 (I, 1), H1 (I), 1.0E-4),
                "PLS2 vs PLS1 ŷ @" & Integer'Image (I));
      end loop;
   end;

   New_Line;
   Put_Line ("================================");
   Put_Line ("Passed:" & Natural'Image (Pass_Count));
   Put_Line ("Failed:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Put_Line ("All tests passed.");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;
   pragma Assert (Fail_Count = 0);
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
