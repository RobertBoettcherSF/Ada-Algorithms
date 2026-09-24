--  Standalone test suite for Successive_Over_Relaxation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Successive_Over_Relaxation; use Successive_Over_Relaxation;

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
   Ada.Text_IO.Put_Line ("Successive_Over_Relaxation test suite");
   Ada.Text_IO.Put_Line ("=====================================");

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
   Section ("2. Mat_Vec / Residual / dominance helpers");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[4.0, 1.0],
         [1.0, 3.0]];
      Asym : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 2.0],
         [0.0, 1.0]];
      X : constant Vector (1 .. 2) := [1.0, 1.0];
      B : constant Vector (1 .. 2) := [5.0, 4.0];
      Y : constant Vector := Mat_Vec (A, X);
      R : constant Vector := Residual (A, X, B);
   begin
      Check (Approx (Y (1), 5.0), "Mat_Vec row1");
      Check (Approx (Y (2), 4.0), "Mat_Vec row2");
      Check (Approx (R (1), 0.0), "Residual zero x");
      Check (Approx (R (2), 0.0), "Residual zero y");
      Check (Approx (Residual_Norm (A, X, B), 0.0), "Residual_Norm 0");
      Check (Is_Symmetric (A), "Is_Symmetric SPD example");
      Check (not Is_Symmetric (Asym), "Is_Symmetric rejects");
      Check (Is_Diagonally_Dominant (A), "Diag dominant A");
      Check (not Is_Diagonally_Dominant (Asym), "Diag dominant rejects");
      Check (Is_Strictly_Diagonally_Dominant (A), "Strict DD A");
      Check (not Is_Strictly_Diagonally_Dominant (Asym), "Strict DD rejects");
   end;

   ---------------------------------------------------------------------
   Section ("3. Make_Example generators");
   ---------------------------------------------------------------------
   declare
      D  : constant Matrix := Make_Example (Diagonally_Dominant, 3);
      P  : constant Matrix := Make_Example (Poisson_1D, 4);
      DPO : constant Matrix := Make_Example (Diagonal_Plus_Ones, 3);
      Z  : constant Vector := Zero_Vector (3);
      Ones : constant Vector := Make_RHS_Ones (3);
      X_Star : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      B_From : constant Vector := Make_RHS_From_Solution (D, X_Star);
   begin
      Check (Approx (D (1, 1), 3.0), "DD diagonal");
      Check (Approx (D (1, 2), 1.0), "DD off");
      Check (Is_Symmetric (D), "DD symmetric");
      Check (Is_Diagonally_Dominant (D), "DD dominant");
      Check (Is_Strictly_Diagonally_Dominant (D), "DD strict");
      Check (Approx (P (1, 1), 2.0), "Poisson diag");
      Check (Approx (P (1, 2), -1.0), "Poisson off");
      Check (Approx (P (2, 1), -1.0), "Poisson sym");
      Check (Approx (P (4, 4), 2.0), "Poisson last");
      Check (Is_Symmetric (P), "Poisson symmetric");
      Check (Is_Diagonally_Dominant (P), "Poisson dominant");
      Check (Approx (DPO (1, 1), 4.0), "Diag+ones diagonal");
      Check (Approx (DPO (1, 2), 1.0), "Diag+ones off");
      Check (Is_Symmetric (DPO), "Diag+ones symmetric");
      Check (Is_Diagonally_Dominant (DPO), "Diag+ones dominant");
      Check (Approx (Z (1), 0.0) and Approx (Z (3), 0.0), "Zero_Vector");
      Check (Approx (Ones (2), 1.0), "Make_RHS_Ones");
      Check (Approx (B_From (1), Mat_Vec (D, X_Star) (1)), "RHS from sol");
   end;

   ---------------------------------------------------------------------
   Section ("4. Known 2×2 (exact solve via SOR)");
   ---------------------------------------------------------------------
   --  A = [[4,1],[1,3]], b = A*(1,2) = (6,7); exact x* = (1,2)
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[4.0, 1.0],
         [1.0, 3.0]];
      X_Star : constant Vector (1 .. 2) := [1.0, 2.0];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      Res : constant Result :=
        Solve_SOR (A, B, Params =>
          (Omega => 1.2, Tol => 1.0E-8, Max_Iter => 200));
   begin
      Check (Res.Success, "2x2 Success");
      Check (Res.Stat = Converged, "2x2 Converged");
      Check (Res.N = 2, "2x2 N");
      Check (Approx (Res.X (1), 1.0, 1.0E-5), "2x2 x1");
      Check (Approx (Res.X (2), 2.0, 1.0E-5), "2x2 x2");
      Check (Res.Residual <= 1.0E-6, "2x2 residual tol");
      Check (Approx (Residual_Norm (A, Res.X (1 .. 2), B),
                     Res.Residual, 1.0E-5),
             "2x2 Residual matches");
   end;

   ---------------------------------------------------------------------
   Section ("5. Known 3×3 SPD exact");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 3, 1 .. 3) :=
        [[4.0, 1.0, 0.0],
         [1.0, 3.0, 1.0],
         [0.0, 1.0, 2.0]];
      X_Star : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      Res : constant Result :=
        Solve_SOR (A, B, Params =>
          (Omega => 1.1, Tol => 1.0E-7, Max_Iter => 500));
   begin
      Check (Is_Symmetric (A), "3x3 symmetric");
      Check (Is_Diagonally_Dominant (A), "3x3 dominant");
      Check (Res.Success, "3x3 Success");
      Check (Approx (Res.X (1), 1.0, 1.0E-4), "3x3 x1");
      Check (Approx (Res.X (2), 2.0, 1.0E-4), "3x3 x2");
      Check (Approx (Res.X (3), 3.0, 1.0E-4), "3x3 x3");
      Check (Res.Residual <= 1.0E-5, "3x3 residual");
   end;

   ---------------------------------------------------------------------
   Section ("6. omega=1 ≡ Gauss–Seidel equivalence");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Diagonal_Plus_Ones, 4);
      X_Star : constant Vector (1 .. 4) := [1.0, -1.0, 2.0, 0.5];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      P_SOR : constant Parameters :=
        (Omega => 1.0, Tol => 1.0E-8, Max_Iter => 300);
      P_GS  : constant Parameters :=
        (Omega => 1.5, Tol => 1.0E-8, Max_Iter => 300);  -- Omega overridden
      R_SOR : constant Result := Solve_SOR (A, B, Params => P_SOR);
      R_GS  : constant Result :=
        Solve_Gauss_Seidel (A, B, Params => P_GS);
   begin
      Check (R_SOR.Success, "omega=1 SOR Success");
      Check (R_GS.Success, "Gauss–Seidel Success");
      Check (Approx (R_SOR.X (1), R_GS.X (1), 1.0E-5), "GS eq x1");
      Check (Approx (R_SOR.X (2), R_GS.X (2), 1.0E-5), "GS eq x2");
      Check (Approx (R_SOR.X (3), R_GS.X (3), 1.0E-5), "GS eq x3");
      Check (Approx (R_SOR.X (4), R_GS.X (4), 1.0E-5), "GS eq x4");
      Check (R_SOR.Iterations = R_GS.Iterations, "GS eq iterations");
      Check (Approx (R_SOR.Residual, R_GS.Residual, 1.0E-6),
             "GS eq residual");
      Check (Approx (R_GS.X (1), 1.0, 1.0E-4), "GS recovers x1");
      Check (Approx (R_GS.X (2), -1.0, 1.0E-4), "GS recovers x2");
   end;

   ---------------------------------------------------------------------
   Section ("7. Identity / diagonal systems");
   ---------------------------------------------------------------------
   declare
      I3 : Matrix (1 .. 3, 1 .. 3) := [others => [others => 0.0]];
      B  : constant Vector (1 .. 3) := [2.0, -1.0, 4.0];
      Res : Result;
   begin
      for K in 1 .. 3 loop
         I3 (K, K) := 1.0;
      end loop;
      Res := Solve_SOR
        (I3, B, Params => (Omega => 1.0, Tol => 1.0E-10, Max_Iter => 5));
      Check (Res.Success, "Identity Success");
      Check (Approx (Res.X (1), 2.0, 1.0E-6), "Identity x1");
      Check (Approx (Res.X (2), -1.0, 1.0E-6), "Identity x2");
      Check (Approx (Res.X (3), 4.0, 1.0E-6), "Identity x3");
      Check (Res.Iterations <= 1, "Identity ≤1 iter (exact in 1)");
   end;

   declare
      D : Matrix (1 .. 4, 1 .. 4) := [others => [others => 0.0]];
      B : constant Vector (1 .. 4) := [2.0, 4.0, 6.0, 8.0];
      Res : Result;
   begin
      for K in 1 .. 4 loop
         D (K, K) := Float (K);
      end loop;
      Res := Solve_Gauss_Seidel
        (D, B, Params => (Omega => 1.0, Tol => 1.0E-10, Max_Iter => 5));
      Check (Res.Success, "Diagonal Success");
      Check (Approx (Res.X (1), 2.0, 1.0E-6), "Diagonal x1");
      Check (Approx (Res.X (2), 2.0, 1.0E-6), "Diagonal x2");
      Check (Approx (Res.X (3), 2.0, 1.0E-6), "Diagonal x3");
      Check (Approx (Res.X (4), 2.0, 1.0E-6), "Diagonal x4");
   end;

   ---------------------------------------------------------------------
   Section ("8. Poisson_1D SPD system");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Poisson_1D, 8);
      X_Star : Vector (1 .. 8);
      B : Vector (1 .. 8);
      Res : Result;
   begin
      for I in 1 .. 8 loop
         X_Star (I) := Float (I);
      end loop;
      B := Make_RHS_From_Solution (A, X_Star);
      Res := Solve_SOR
        (A, B, Params => (Omega => 1.5, Tol => 1.0E-5, Max_Iter => 2000));
      Check (Res.Success, "Poisson Success");
      Check (Approx (Res.X (1), 1.0, 1.0E-3), "Poisson x1");
      Check (Approx (Res.X (4), 4.0, 1.0E-3), "Poisson x4");
      Check (Approx (Res.X (8), 8.0, 1.0E-3), "Poisson x8");
      Check (Res.Residual <= 1.0E-5, "Poisson residual");
   end;

   ---------------------------------------------------------------------
   Section ("9. Bad omega / zero diagonal / iteration limit");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Diagonally_Dominant, 3);
      B : constant Vector := Make_RHS_Ones (3);
      R_Lo : constant Result :=
        Solve_SOR (A, B, Params =>
          (Omega => 0.0, Tol => 1.0E-6, Max_Iter => 10));
      R_Hi : constant Result :=
        Solve_SOR (A, B, Params =>
          (Omega => 2.0, Tol => 1.0E-6, Max_Iter => 10));
      R_Neg : constant Result :=
        Solve_SOR (A, B, Params =>
          (Omega => -0.5, Tol => 1.0E-6, Max_Iter => 10));
      Z : constant Matrix (1 .. 2, 1 .. 2) := [[0.0, 1.0], [1.0, 1.0]];
      R_Z : constant Result :=
        Solve_SOR (Z, [1.0, 1.0], Params =>
          (Omega => 1.0, Tol => 1.0E-6, Max_Iter => 10));
      R_Lim : constant Result :=
        Solve_SOR (A, B, Params =>
          (Omega => 1.0, Tol => 0.0, Max_Iter => 2));
   begin
      Check (not R_Lo.Success and R_Lo.Stat = Bad_Omega, "Omega=0 rejected");
      Check (not R_Hi.Success and R_Hi.Stat = Bad_Omega, "Omega=2 rejected");
      Check (not R_Neg.Success and R_Neg.Stat = Bad_Omega, "Omega<0 rejected");
      Check (not R_Z.Success and R_Z.Stat = Zero_Diagonal,
             "Zero diagonal rejected");
      Check (not R_Lim.Success and R_Lim.Stat = Iteration_Limit,
             "Iteration limit status");
      Check (R_Lim.Iterations = 2, "Iteration limit count");
   end;

   ---------------------------------------------------------------------
   Section ("10. Under-/over-relaxation still converge on DD");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Diagonally_Dominant, 5);
      X_Star : constant Vector (1 .. 5) := [1.0, 2.0, 3.0, 4.0, 5.0];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      R_Under : constant Result :=
        Solve_SOR (A, B, Params =>
          (Omega => 0.7, Tol => 1.0E-7, Max_Iter => 1000));
      R_Over : constant Result :=
        Solve_SOR (A, B, Params =>
          (Omega => 1.4, Tol => 1.0E-7, Max_Iter => 1000));
   begin
      Check (R_Under.Success, "Under-relax Success");
      Check (R_Over.Success, "Over-relax Success");
      Check (Approx (R_Under.X (3), 3.0, 1.0E-4), "Under x3");
      Check (Approx (R_Over.X (5), 5.0, 1.0E-4), "Over x5");
      Check (R_Under.Residual <= 1.0E-6, "Under residual");
      Check (R_Over.Residual <= 1.0E-6, "Over residual");
   end;

   ---------------------------------------------------------------------
   Section ("11. Already-solved start / custom X0");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Poisson_1D, 3);
      X_Star : constant Vector (1 .. 3) := [2.0, 3.0, 4.0];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      R0 : constant Result :=
        Solve_SOR (A, B, X0 => X_Star, Params =>
          (Omega => 1.0, Tol => 1.0E-8, Max_Iter => 10));
      X_Bad : constant Vector (1 .. 3) := [0.0, 0.0, 0.0];
      R1 : constant Result :=
        Solve_SOR (A, B, X0 => X_Bad, Params =>
          (Omega => 1.2, Tol => 1.0E-5, Max_Iter => 500));
   begin
      Check (R0.Success, "Exact start Success");
      Check (R0.Iterations = 0, "Exact start 0 iters");
      Check (Approx (R0.X (2), 3.0, 1.0E-6), "Exact start x2");
      Check (R1.Success, "Zero start Success");
      Check (Approx (R1.X (1), 2.0, 1.0E-4), "Zero start x1");
      Check (Approx (R1.X (3), 4.0, 1.0E-4), "Zero start x3");
   end;

   ---------------------------------------------------------------------
   Section ("12. Empty X0 defaults to zero; Max_N boundary");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Diagonal_Plus_Ones, 2);
      B : constant Vector := Make_RHS_From_Solution (A, [3.0, -1.0]);
      Res : constant Result :=
        Solve_SOR (A, B, Params =>
          (Omega => 1.0, Tol => 1.0E-8, Max_Iter => 100));
   begin
      Check (Res.Success, "Empty X0 Success");
      Check (Approx (Res.X (1), 3.0, 1.0E-5), "Empty X0 x1");
      Check (Approx (Res.X (2), -1.0, 1.0E-5), "Empty X0 x2");
   end;

   declare
      A : constant Matrix := Make_Example (Poisson_1D, Max_N);
      X_Star : Vector (1 .. Max_N);
      B : Vector (1 .. Max_N);
      Res : Result;
   begin
      for I in 1 .. Max_N loop
         X_Star (I) := 1.0;
      end loop;
      B := Make_RHS_From_Solution (A, X_Star);
      Res := Solve_SOR
        (A, B, Params => (Omega => 1.6, Tol => 1.0E-5, Max_Iter => 5000));
      Check (Res.N = Max_N, "Max_N dimension");
      Check (Res.Success, "Max_N Success");
      Check (Approx (Res.X (1), 1.0, 1.0E-3), "Max_N x1");
      Check (Approx (Res.X (Max_N), 1.0, 1.0E-3), "Max_N x_n");
   end;

   ---------------------------------------------------------------------
   Section ("13. Residual decreases under Gauss–Seidel on DD");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Diagonally_Dominant, 4);
      B : constant Vector := Make_RHS_Ones (4);
      Prev, Cur : Float;
      Ok_Mono : Boolean := True;
   begin
      Prev := Residual_Norm (A, Zero_Vector (4), B);
      for Step in 1 .. 8 loop
         declare
            Partial : constant Result :=
              Solve_Gauss_Seidel
                (A, B, Params => (Omega => 1.0, Tol => 0.0, Max_Iter => Step));
         begin
            Cur := Partial.Residual;
            if Cur > Prev + 1.0E-5 then
               Ok_Mono := False;
            end if;
            Prev := Cur;
         end;
      end loop;
      Check (Ok_Mono, "Residual nonincreasing over partial GS runs");
      Check (Prev <= 1.0E-2, "Residual smaller after 8 GS steps");
   end;

   ---------------------------------------------------------------------
   Section ("14. Classic 2×2 wiki-style with omega≠1");
   ---------------------------------------------------------------------
   --  A = [[2,1],[1,2]], b = [3,3], exact x* = (1,1)
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[2.0, 1.0],
         [1.0, 2.0]];
      B : constant Vector (1 .. 2) := [3.0, 3.0];
      R_GS : constant Result :=
        Solve_Gauss_Seidel (A, B, Params =>
          (Omega => 1.0, Tol => 1.0E-9, Max_Iter => 100));
      R_SOR : constant Result :=
        Solve_SOR (A, B, Params =>
          (Omega => 1.25, Tol => 1.0E-9, Max_Iter => 100));
   begin
      Check (R_GS.Success, "Wiki 2x2 GS Success");
      Check (R_SOR.Success, "Wiki 2x2 SOR Success");
      Check (Approx (R_GS.X (1), 1.0, 1.0E-6), "Wiki GS x1");
      Check (Approx (R_GS.X (2), 1.0, 1.0E-6), "Wiki GS x2");
      Check (Approx (R_SOR.X (1), 1.0, 1.0E-6), "Wiki SOR x1");
      Check (Approx (R_SOR.X (2), 1.0, 1.0E-6), "Wiki SOR x2");
      --  Over-relaxation should not need more iters than GS on this tiny SPD
      Check (R_SOR.Iterations <= R_GS.Iterations + 2,
             "SOR iters competitive with GS");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Pass_Count =" & Pass_Count'Image
      & "  Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
   end if;

   if Fail_Count /= 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
