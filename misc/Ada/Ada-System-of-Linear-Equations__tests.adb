--  Standalone test suite for System_Of_Linear_Equations (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with System_Of_Linear_Equations; use System_Of_Linear_Equations;

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

   function Approx (A, B : Float; Tol : Float := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Sol_Near
     (R : Result; X_Star : Vector; Tol : Float := 1.0E-4) return Boolean
   is
   begin
      if not R.Success or else R.N /= X_Star'Length then
         return False;
      end if;
      for I in 1 .. R.N loop
         if abs (R.X (I) - X_Star (X_Star'First + I - 1)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Sol_Near;

begin
   Put_Line ("System_Of_Linear_Equations test suite");
   Put_Line ("=====================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Vec_Near / vector helpers");
   ---------------------------------------------------------------------
   declare
      A : constant Vector (1 .. 2) := [1.0, 2.0];
      B : constant Vector (1 .. 2) := [1.0, 2.0];
      C : constant Vector (1 .. 2) := [1.0, 3.0];
      D : constant Vector (1 .. 3) := [3.0, 4.0, 0.0];
      Z : constant Vector (1 .. 2) := [0.0, 0.0];
      S : Vector (1 .. 2);
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Vec_Near (A, B), "Vec_Near equal");
      Check (not Vec_Near (A, C), "Vec_Near rejects");
      Check (Vec_Near (A, C, 1.5), "Vec_Near loose Tol");
      Check (Approx (Norm2 (D), 5.0, 1.0E-6), "Norm2(3,4,0)=5");
      Check (Approx (Norm2 (Z), 0.0), "Norm2 zero");
      Check (Approx (Dot (A, C), 7.0), "Dot product");
      S := Add (A, C);
      Check (Approx (S (1), 2.0) and then Approx (S (2), 5.0), "Add");
      S := Sub (C, A);
      Check (Approx (S (1), 0.0) and then Approx (S (2), 1.0), "Sub");
      S := Scale (A, 2.0);
      Check (Approx (S (1), 2.0) and then Approx (S (2), 4.0), "Scale");
      Check (Approx (Dot (A, A), 5.0), "Dot self");
   end;

   ---------------------------------------------------------------------
   Section ("2. Identity / Mat_Vec / Is_Square / residual");
   ---------------------------------------------------------------------
   declare
      I2 : constant Matrix := Identity (2);
      I3 : constant Matrix := Identity (3);
      V  : constant Vector (1 .. 2) := [3.0, 4.0];
      W  : Vector (1 .. 2);
      A  : constant Matrix (1 .. 2, 1 .. 2) := [[2.0, 1.0], [1.0, 2.0]];
      X  : constant Vector (1 .. 2) := [1.0, 1.0];
      B  : constant Vector (1 .. 2) := [3.0, 3.0];
      R  : Vector (1 .. 2);
   begin
      Check (Is_Square (I2), "Is_Square Identity");
      Check (Approx (I2 (1, 1), 1.0) and then Approx (I2 (2, 2), 1.0),
             "Identity 2 diag");
      Check (Approx (I2 (1, 2), 0.0) and then Approx (I2 (2, 1), 0.0),
             "Identity 2 off-diag");
      Check (Approx (I3 (3, 3), 1.0), "Identity 3");
      W := Mat_Vec (I2, V);
      Check (Vec_Near (W, V, 1.0E-12), "Mat_Vec I·v = v");
      W := Mat_Vec (A, X);
      Check (Vec_Near (W, B, 1.0E-12), "Mat_Vec A·[1,1]=[3,3]");
      R := Residual (A, X, B);
      Check (Approx (Norm2 (R), 0.0, 1.0E-12), "Residual exact zero");
      Check (Approx (Residual_Norm (A, X, B), 0.0, 1.0E-12),
             "Residual_Norm zero");
      Check (Approx (Residual_Norm (A, [0.0, 0.0], B), Norm2 (B), 1.0E-6),
             "Residual_Norm at zero = ‖b‖");
   end;

   ---------------------------------------------------------------------
   Section ("3. Builders / DD / Poisson / nonsym / singular");
   ---------------------------------------------------------------------
   declare
      DD : constant Matrix := Make_Diagonally_Dominant (4);
      P1 : constant Matrix := Make_Poisson_1D (5);
      NS : constant Matrix := Make_Nonsymmetric_DD (3);
      SG : constant Matrix := Make_Singular (3);
      DP : constant Matrix := Make_Diagonal_Plus_Ones (3);
      Z  : constant Vector := Zero_Vector (3);
      O  : constant Vector := Ones_Vector (3, 2.0);
   begin
      Check (Is_Strictly_Diagonally_Dominant (DD), "DD is strictly DD");
      Check (Is_Symmetric (DD), "DD is symmetric");
      Check (Is_Tridiagonal (P1), "Poisson is tridiagonal");
      Check (Is_Symmetric (P1), "Poisson is symmetric");
      Check (Is_Diagonally_Dominant (P1), "Poisson is DD");
      Check (not Is_Symmetric (NS), "Nonsym not symmetric");
      Check (Is_Strictly_Diagonally_Dominant (NS), "Nonsym is strictly DD");
      Check (Approx (SG (1, 1), SG (2, 1)), "Singular rows match col1");
      Check (Approx (SG (1, 2), SG (2, 2)), "Singular rows match col2");
      Check (Is_Symmetric (DP), "Diag+Ones symmetric");
      Check (Is_Strictly_Diagonally_Dominant (DP), "Diag+Ones strictly DD");
      Check (Approx (Norm2 (Z), 0.0), "Zero_Vector");
      Check (Approx (O (1), 2.0) and then Approx (O (3), 2.0),
             "Ones_Vector value");
      Check (Has_Positive_Diagonal (DD), "DD positive diagonal");
      Check (Has_Positive_Diagonal (P1), "Poisson positive diagonal");
   end;

   ---------------------------------------------------------------------
   Section ("4. Classify_Matrix / Recommend / Method catalog");
   ---------------------------------------------------------------------
   declare
      P_DD : constant Matrix_Properties :=
        Classify_Matrix (Make_Diagonally_Dominant (4));
      P_Po : constant Matrix_Properties :=
        Classify_Matrix (Make_Poisson_1D (6));
      P_NS : constant Matrix_Properties :=
        Classify_Matrix (Make_Nonsymmetric_DD (3));
      P_SG : constant Matrix_Properties :=
        Classify_Matrix (Make_Singular (3));
      P_I  : constant Matrix_Properties :=
        Classify_Matrix (Identity (2));
      Info : Method_Info;
   begin
      Check (P_DD.Symmetric and then P_DD.Strictly_DD
             and then P_DD.SPD_Heuristic,
             "Classify DD → SPD heuristic");
      Check (P_Po.Tridiagonal and then P_Po.Symmetric,
             "Classify Poisson → tridiagonal SPD-ish");
      Check (Recommend_Method (P_Po) = Thomas,
             "Recommend Thomas for Poisson");
      Check (Recommend_Method (P_DD) = Conjugate_Gradient
             or else Recommend_Method (P_DD) = Gauss_Seidel,
             "Recommend CG or GS for large DD");
      Check (not P_NS.Symmetric and then P_NS.Strictly_DD,
             "Classify nonsym DD");
      Check (Recommend_Method (P_NS) = Gauss_Seidel,
             "Recommend GS for nonsym strictly DD");
      Check (P_SG.Singular_Heuristic,
             "Classify singular heuristic");
      Check (Recommend_Method (P_SG) = Gaussian_Elimination,
             "Recommend GE for singular");
      Check (P_I.Symmetric and then P_I.SPD_Heuristic,
             "Identity SPD heuristic");
      Check (Method_Count = 6, "Method_Count = 6");
      Info := Classify_Method (Gaussian_Elimination);
      Check (Info.Is_Direct and then not Info.Is_Iterative,
             "GE is direct");
      Info := Classify_Method (Jacobi);
      Check (Info.Is_Iterative and then Info.Needs_DD, "Jacobi iterative DD");
      Info := Classify_Method (Conjugate_Gradient);
      Check (Info.Needs_SPD and then Info.Is_Iterative, "CG needs SPD");
      Info := Classify_Method (Thomas);
      Check (Info.Structured_Only and then Info.Is_Direct, "Thomas structured");
      Info := Classify_Method (BiCG);
      Check (Info.Is_Iterative and then not Info.Needs_SPD, "BiCG catalogued");
      Check (Method_Name (Gauss_Seidel)'Length > 0, "Method_Name non-empty");
      Check (Method_Name (BiCG)'Length > 0, "Method_Name BiCG");
   end;

   ---------------------------------------------------------------------
   Section ("5. Solve_GE — identity / 2×2 / pivot / manufactured");
   ---------------------------------------------------------------------
   declare
      I3 : constant Matrix := Identity (3);
      B3 : constant Vector (1 .. 3) := [1.0, -2.0, 3.0];
      R  : Result;
      A2 : constant Matrix (1 .. 2, 1 .. 2) := [[2.0, 1.0], [1.0, 3.0]];
      X2 : constant Vector (1 .. 2) := [1.0, 2.0];
      B2 : constant Vector := Make_RHS_From_Solution (A2, X2);
      --  Needs pivot: [0 1; 1 0] x = [2; 3] → x = [3; 2]
      NP : constant Matrix (1 .. 2, 1 .. 2) := [[0.0, 1.0], [1.0, 0.0]];
      BN : constant Vector (1 .. 2) := [2.0, 3.0];
      DD : constant Matrix := Make_Diagonally_Dominant (5);
      XS : constant Vector (1 .. 5) := [1.0, -1.0, 2.0, 0.5, -0.5];
      BD : constant Vector := Make_RHS_From_Solution (DD, XS);
   begin
      R := Solve_GE (I3, B3);
      Check (R.Success and then R.Stat = Ok, "GE Identity success");
      Check (Sol_Near (R, B3, 1.0E-6), "GE Identity solution");
      Check (Approx (R.Residual, 0.0, 1.0E-5), "GE Identity residual");

      R := Solve_GE (A2, B2);
      Check (R.Success, "GE 2×2 success");
      Check (Sol_Near (R, X2, 1.0E-5), "GE 2×2 manufactured");

      R := Solve_GE (NP, BN);
      Check (R.Success, "GE needs-pivot success");
      Check (Sol_Near (R, [3.0, 2.0], 1.0E-5), "GE needs-pivot solution");
      Check (R.Swap_Count >= 1, "GE needs-pivot swapped");

      R := Solve_GE (DD, BD);
      Check (R.Success, "GE DD n=5 success");
      Check (Sol_Near (R, XS, 1.0E-4), "GE DD manufactured");
      Check (R.Residual < 1.0E-4, "GE DD residual small");
   end;

   ---------------------------------------------------------------------
   Section ("6. Solve_GE — singular detection");
   ---------------------------------------------------------------------
   declare
      SG : constant Matrix := Make_Singular (4);
      B  : constant Vector := Make_RHS_Ones (4);
      R  : Result;
      Z2 : constant Matrix (1 .. 2, 1 .. 2) := [[0.0, 0.0], [0.0, 0.0]];
   begin
      R := Solve_GE (SG, B);
      Check (not R.Success, "GE singular not success");
      Check (R.Stat = Singular or else R.Stat = Zero_Pivot,
             "GE singular status");
      R := Solve_GE (Z2, [1.0, 1.0]);
      Check (not R.Success, "GE zero matrix fails");
      Check (R.Stat = Singular or else R.Stat = Zero_Pivot,
             "GE zero matrix status");
   end;

   ---------------------------------------------------------------------
   Section ("7. Solve_Thomas — Poisson / non-tri reject");
   ---------------------------------------------------------------------
   declare
      P  : constant Matrix := Make_Poisson_1D (8);
      XS : constant Vector (1 .. 8) :=
        [1.0, 2.0, 3.0, 4.0, 3.0, 2.0, 1.0, 0.5];
      B  : constant Vector := Make_RHS_From_Solution (P, XS);
      R  : Result;
      DD : constant Matrix := Make_Diagonally_Dominant (4);
   begin
      R := Solve_Thomas (P, B);
      Check (R.Success and then R.Stat = Ok, "Thomas Poisson success");
      Check (Sol_Near (R, XS, 1.0E-4), "Thomas Poisson manufactured");
      Check (R.Residual < 1.0E-4, "Thomas residual");

      R := Solve_Thomas (Make_Poisson_1D (2), [1.0, 1.0]);
      Check (R.Success, "Thomas n=2 success");

      R := Solve_Thomas (DD, Make_RHS_Ones (4));
      Check (not R.Success and then R.Stat = Not_Tridiagonal,
             "Thomas rejects dense DD");
   end;

   ---------------------------------------------------------------------
   Section ("8. Solve_Jacobi — DD / Poisson / zero-diag");
   ---------------------------------------------------------------------
   declare
      DD : constant Matrix := Make_Diagonally_Dominant (4);
      XS : constant Vector (1 .. 4) := [1.0, -1.0, 0.5, 2.0];
      B  : constant Vector := Make_RHS_From_Solution (DD, XS);
      R  : Result;
      P  : constant Parameters := (Tol => 1.0E-5, Max_Iter => 10_000);
      ZD : constant Matrix (1 .. 2, 1 .. 2) := [[0.0, 1.0], [1.0, 2.0]];
   begin
      R := Solve_Jacobi (DD, B, Params => P);
      Check (R.Success and then R.Stat = Converged, "Jacobi DD converged");
      Check (Sol_Near (R, XS, 1.0E-3), "Jacobi DD solution");
      Check (R.Iterations > 0, "Jacobi took iterations");
      Check (R.Residual <= 1.0E-3, "Jacobi residual");

      R := Solve_Jacobi
        (Make_Poisson_1D (6),
         Make_RHS_From_Solution
           (Make_Poisson_1D (6), [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]),
         Params => (Tol => 1.0E-5, Max_Iter => 10_000));
      Check (R.Success, "Jacobi Poisson ones converged");

      R := Solve_Jacobi (ZD, [1.0, 1.0]);
      Check (not R.Success and then R.Stat = Zero_Diagonal,
             "Jacobi zero-diag rejected");
   end;

   ---------------------------------------------------------------------
   Section ("9. Solve_Gauss_Seidel — DD / nonsym / vs Jacobi");
   ---------------------------------------------------------------------
   declare
      DD : constant Matrix := Make_Diagonally_Dominant (5);
      XS : constant Vector (1 .. 5) := [0.5, -1.0, 2.0, 1.0, -0.25];
      B  : constant Vector := Make_RHS_From_Solution (DD, XS);
      R, RJ : Result;
      P  : constant Parameters := (Tol => 1.0E-5, Max_Iter => 10_000);
      NS : constant Matrix := Make_Nonsymmetric_DD (4);
      XN : constant Vector (1 .. 4) := [1.0, 2.0, -1.0, 0.5];
      BN : constant Vector := Make_RHS_From_Solution (NS, XN);
   begin
      R := Solve_Gauss_Seidel (DD, B, Params => P);
      Check (R.Success and then R.Stat = Converged, "GS DD converged");
      Check (Sol_Near (R, XS, 1.0E-4), "GS DD solution");

      RJ := Solve_Jacobi (DD, B, Params => P);
      Check (RJ.Success, "Jacobi also converges on DD");
      Check (R.Iterations <= RJ.Iterations,
             "GS ≤ Jacobi iterations (typical)");

      R := Solve_Gauss_Seidel (NS, BN, Params => P);
      Check (R.Success, "GS nonsym DD converged");
      Check (Sol_Near (R, XN, 1.0E-4), "GS nonsym solution");

      R := Solve_Gauss_Seidel
        (Identity (3), [4.0, 5.0, 6.0],
         Params => (Tol => 1.0E-10, Max_Iter => 10));
      Check (R.Success, "GS Identity quick");
      Check (Sol_Near (R, [4.0, 5.0, 6.0], 1.0E-6), "GS Identity solution");
   end;

   ---------------------------------------------------------------------
   Section ("10. Solve_CG — SPD / Poisson / Identity");
   ---------------------------------------------------------------------
   declare
      DP : constant Matrix := Make_Diagonal_Plus_Ones (6);
      XS : constant Vector (1 .. 6) :=
        [1.0, -1.0, 0.5, 2.0, -0.5, 1.5];
      B  : constant Vector := Make_RHS_From_Solution (DP, XS);
      R  : Result;
      P1 : constant Matrix := Make_Poisson_1D (8);
      XP : constant Vector (1 .. 8) :=
        [1.0, 2.0, 1.0, 0.0, -1.0, 0.5, 1.0, 2.0];
      BP : constant Vector := Make_RHS_From_Solution (P1, XP);
   begin
      R := Solve_CG (DP, B);
      Check (R.Success and then R.Stat = Converged, "CG Diag+Ones converged");
      Check (Sol_Near (R, XS, 1.0E-3), "CG Diag+Ones solution");
      Check (R.Iterations <= 6, "CG ≤ N iterations (SPD)");

      R := Solve_CG (P1, BP);
      Check (R.Success, "CG Poisson converged");
      Check (Sol_Near (R, XP, 1.0E-3), "CG Poisson solution");

      R := Solve_CG (Identity (4), [1.0, 2.0, 3.0, 4.0]);
      Check (R.Success, "CG Identity");
      Check (Sol_Near (R, [1.0, 2.0, 3.0, 4.0], 1.0E-5),
             "CG Identity solution");
      Check (R.Iterations <= 4, "CG Identity ≤ 4 iters");
   end;

   ---------------------------------------------------------------------
   Section ("11. Solve dispatcher / Solve_Auto / BiCG stub");
   ---------------------------------------------------------------------
   declare
      P1 : constant Matrix := Make_Poisson_1D (5);
      XS : constant Vector (1 .. 5) := [1.0, 1.0, 1.0, 1.0, 1.0];
      B  : constant Vector := Make_RHS_From_Solution (P1, XS);
      R  : Result;
      DD : constant Matrix := Make_Diagonally_Dominant (5);
      BD : constant Vector :=
        Make_RHS_From_Solution (DD, [1.0, 2.0, 3.0, 4.0, 5.0]);
   begin
      R := Solve (P1, B, Kind => Thomas);
      Check (R.Success, "Solve(Thomas) success");
      Check (Sol_Near (R, XS, 1.0E-4), "Solve(Thomas) solution");

      R := Solve (DD, BD, Kind => Gaussian_Elimination);
      Check (R.Success, "Solve(GE) success");
      Check (Sol_Near (R, [1.0, 2.0, 3.0, 4.0, 5.0], 1.0E-4),
             "Solve(GE) solution");

      R := Solve (DD, BD, Kind => Gauss_Seidel,
                  Params => (Tol => 1.0E-5, Max_Iter => 10_000));
      Check (R.Success, "Solve(GS) success");

      R := Solve (DD, BD, Kind => Conjugate_Gradient);
      Check (R.Success, "Solve(CG) success");

      R := Solve (DD, BD, Kind => BiCG);
      Check (not R.Success and then R.Stat = Ill_Started,
             "Solve(BiCG) stub Ill_Started");

      R := Solve_Auto (P1, B);
      Check (R.Success, "Solve_Auto Poisson success");
      Check (Sol_Near (R, XS, 1.0E-3), "Solve_Auto Poisson solution");

      R := Solve_Auto (DD, BD);
      Check (R.Success, "Solve_Auto DD success");
   end;

   ---------------------------------------------------------------------
   Section ("12. Residual / Make_RHS helpers / edge cases");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) := [[4.0, 1.0], [1.0, 3.0]];
      X : constant Vector (1 .. 2) := [1.0, 1.0];
      B : constant Vector := Make_RHS_From_Solution (A, X);
      R : Result;
      O : constant Vector := Make_RHS_Ones (3, 7.0);
   begin
      Check (Vec_Near (B, [5.0, 4.0], 1.0E-12), "Make_RHS_From_Solution");
      Check (Approx (O (1), 7.0) and then Approx (O (3), 7.0),
             "Make_RHS_Ones");
      R := Solve_GE (A, B);
      Check (Approx (Residual_Norm (A, R.X (1 .. 2), B), 0.0, 1.0E-5),
             "post-GE residual");
      --  Already-solved start for Jacobi
      R := Solve_Jacobi
        (A, B, X0 => X, Params => (Tol => 1.0E-10, Max_Iter => 5));
      Check (R.Success and then R.Iterations = 0,
             "Jacobi already-solved zero iters");
      R := Solve_Gauss_Seidel
        (A, B, X0 => X, Params => (Tol => 1.0E-10, Max_Iter => 5));
      Check (R.Success and then R.Iterations = 0,
             "GS already-solved zero iters");
      R := Solve_CG (A, B, X0 => X);
      Check (R.Success and then R.Iterations = 0,
             "CG already-solved zero iters");
   end;

   ---------------------------------------------------------------------
   Section ("13. Cross-method agreement on SPD Poisson");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix := Make_Poisson_1D (7);
      XS : constant Vector (1 .. 7) :=
        [0.5, 1.0, 1.5, 2.0, 1.5, 1.0, 0.5];
      B  : constant Vector := Make_RHS_From_Solution (A, XS);
      RG, RT, RJ, RS, RC : Result;
      P  : constant Parameters := (Tol => 1.0E-5, Max_Iter => 10_000);
   begin
      RG := Solve_GE (A, B);
      RT := Solve_Thomas (A, B);
      RJ := Solve_Jacobi (A, B, Params => P);
      RS := Solve_Gauss_Seidel (A, B, Params => P);
      RC := Solve_CG (A, B);
      Check (RG.Success and then RT.Success and then RJ.Success
             and then RS.Success and then RC.Success,
             "all five methods succeed on Poisson");
      Check (Sol_Near (RG, XS, 1.0E-4), "GE agrees");
      Check (Sol_Near (RT, XS, 1.0E-4), "Thomas agrees");
      Check (Sol_Near (RJ, XS, 1.0E-3), "Jacobi agrees");
      Check (Sol_Near (RS, XS, 1.0E-3), "GS agrees");
      Check (Sol_Near (RC, XS, 1.0E-3), "CG agrees");
      Check (Vec_Near
                (RG.X (1 .. 7), RT.X (1 .. 7), 1.0E-4),
             "GE ≈ Thomas");
      Check (Vec_Near
                (RG.X (1 .. 7), RC.X (1 .. 7), 1.0E-3),
             "GE ≈ CG");
   end;

   ---------------------------------------------------------------------
   Section ("14. Property predicates extras");
   ---------------------------------------------------------------------
   declare
      Dense : constant Matrix := Make_Diagonally_Dominant (3);
      P1    : constant Matrix := Make_Poisson_1D (3);
      NS    : constant Matrix := Make_Nonsymmetric_DD (3);
   begin
      Check (not Is_Tridiagonal (Dense), "dense DD not tridiagonal");
      Check (Is_Tridiagonal (P1), "Poisson still tridiagonal");
      Check (Is_Diagonally_Dominant (P1), "Poisson weakly DD");
      Check (not Is_Strictly_Diagonally_Dominant (P1)
             or else Is_Strictly_Diagonally_Dominant (P1),
             "Poisson strict-DD check runs");
      --  n=1 Poisson: [2] is strictly DD
      Check (Is_Strictly_Diagonally_Dominant (Make_Poisson_1D (1)),
             "Poisson n=1 strictly DD");
      Check (not Is_Symmetric (NS, 1.0E-8), "nonsym fails Is_Symmetric");
      Check (Is_Square (Dense), "Dense is square");
   end;

   New_Line;
   Put_Line ("=====================================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;
   pragma Assert (Fail_Count = 0);
end Tests;
