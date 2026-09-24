--  Standalone test suite for Gauss_Seidel (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Gauss_Seidel; use Gauss_Seidel;

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
   Ada.Text_IO.Put_Line ("Gauss_Seidel test suite");
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
      Check (Approx (Scale (U, 0.0) (2), 0.0), "Scale zero");
      Check (Approx (Add (U, Scale (U, -1.0)) (1), 0.0), "Add inverse");
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
      Check (Approx (Residual_Norm (A, [0.0, 0.0], B), Norm2 (B)),
             "Residual_Norm at zero = ‖b‖");
   end;

   ---------------------------------------------------------------------
   Section ("3. Make_Example generators");
   ---------------------------------------------------------------------
   declare
      D   : constant Matrix := Make_Example (Diagonally_Dominant, 3);
      P   : constant Matrix := Make_Example (Poisson_1D, 4);
      DPO : constant Matrix := Make_Example (Diagonal_Plus_Ones, 3);
      NC  : constant Matrix := Make_Example (Non_Convergent, 2);
      Z   : constant Vector := Zero_Vector (3);
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
      Check (Approx (NC (1, 1), 1.0), "NonConvergent a11");
      Check (Approx (NC (1, 2), 2.0), "NonConvergent a12");
      Check (Approx (NC (2, 1), 3.0), "NonConvergent a21");
      Check (not Is_Diagonally_Dominant (NC), "NonConvergent not DD");
   end;

   ---------------------------------------------------------------------
   Section ("4. Known 2×2 exact solve");
   ---------------------------------------------------------------------
   --  A = [[4,1],[1,3]], b = A*(1,2) = (6,7); exact x* = (1,2)
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[4.0, 1.0],
         [1.0, 3.0]];
      X_Star : constant Vector (1 .. 2) := [1.0, 2.0];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      Res : constant Result :=
        Solve (A, B, Params => (Tol => 1.0E-8, Max_Iter => 200));
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
        Solve (A, B, Params => (Tol => 1.0E-7, Max_Iter => 500));
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
   Section ("6. Identity / diagonal systems");
   ---------------------------------------------------------------------
   declare
      I3 : Matrix (1 .. 3, 1 .. 3) := [others => [others => 0.0]];
      B  : constant Vector (1 .. 3) := [2.0, -1.0, 4.0];
      Res : Result;
   begin
      for K in 1 .. 3 loop
         I3 (K, K) := 1.0;
      end loop;
      Res := Solve
        (I3, B, Params => (Tol => 1.0E-10, Max_Iter => 5));
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
      Res := Solve
        (D, B, Params => (Tol => 1.0E-10, Max_Iter => 5));
      Check (Res.Success, "Diagonal Success");
      Check (Approx (Res.X (1), 2.0, 1.0E-6), "Diagonal x1");
      Check (Approx (Res.X (2), 2.0, 1.0E-6), "Diagonal x2");
      Check (Approx (Res.X (3), 2.0, 1.0E-6), "Diagonal x3");
      Check (Approx (Res.X (4), 2.0, 1.0E-6), "Diagonal x4");
      Check (Res.Iterations <= 1, "Diagonal ≤1 iter");
   end;

   ---------------------------------------------------------------------
   Section ("7. Diagonally_Dominant builder systems");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Diagonally_Dominant, 5);
      X_Star : constant Vector (1 .. 5) := [1.0, 2.0, 3.0, 4.0, 5.0];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      Res : constant Result :=
        Solve (A, B, Params => (Tol => 1.0E-7, Max_Iter => 1000));
   begin
      Check (Res.Success, "DD5 Success");
      Check (Approx (Res.X (1), 1.0, 1.0E-4), "DD5 x1");
      Check (Approx (Res.X (3), 3.0, 1.0E-4), "DD5 x3");
      Check (Approx (Res.X (5), 5.0, 1.0E-4), "DD5 x5");
      Check (Res.Residual <= 1.0E-6, "DD5 residual");
   end;

   declare
      A : constant Matrix := Make_Example (Diagonal_Plus_Ones, 4);
      X_Star : constant Vector (1 .. 4) := [1.0, -1.0, 2.0, 0.5];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      Res : constant Result :=
        Solve (A, B, Params => (Tol => 1.0E-8, Max_Iter => 300));
   begin
      Check (Res.Success, "DPO4 Success");
      Check (Approx (Res.X (1), 1.0, 1.0E-4), "DPO4 x1");
      Check (Approx (Res.X (2), -1.0, 1.0E-4), "DPO4 x2");
      Check (Approx (Res.X (3), 2.0, 1.0E-4), "DPO4 x3");
      Check (Approx (Res.X (4), 0.5, 1.0E-4), "DPO4 x4");
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
      Res := Solve
        (A, B, Params => (Tol => 1.0E-5, Max_Iter => 2000));
      Check (Res.Success, "Poisson Success");
      Check (Approx (Res.X (1), 1.0, 1.0E-3), "Poisson x1");
      Check (Approx (Res.X (4), 4.0, 1.0E-3), "Poisson x4");
      Check (Approx (Res.X (8), 8.0, 1.0E-3), "Poisson x8");
      Check (Res.Residual <= 1.0E-5, "Poisson residual");
   end;

   declare
      A : constant Matrix := Make_Example (Poisson_1D, 3);
      B : constant Vector (1 .. 3) := [1.0, 0.0, 1.0];
      Res : constant Result :=
        Solve (A, B, Params => (Tol => 1.0E-8, Max_Iter => 500));
   begin
      Check (Res.Success, "Poisson3 Success");
      Check (Res.Residual <= 1.0E-7, "Poisson3 residual");
      Check (Approx (Residual_Norm (A, Res.X (1 .. 3), B),
                     Res.Residual, 1.0E-6),
             "Poisson3 Residual matches");
   end;

   ---------------------------------------------------------------------
   Section ("9. Zero diagonal / iteration limit / non-convergent");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Diagonally_Dominant, 3);
      B : constant Vector := Make_RHS_Ones (3);
      Z : constant Matrix (1 .. 2, 1 .. 2) := [[0.0, 1.0], [1.0, 1.0]];
      R_Z : constant Result :=
        Solve (Z, [1.0, 1.0], Params => (Tol => 1.0E-6, Max_Iter => 10));
      R_Lim : constant Result :=
        Solve (A, B, Params => (Tol => 0.0, Max_Iter => 2));
      Tiny : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0E-14, 1.0], [1.0, 1.0]];
      R_Tiny : constant Result :=
        Solve (Tiny, [1.0, 1.0], Params => (Tol => 1.0E-6, Max_Iter => 10));
      NC : constant Matrix := Make_Example (Non_Convergent, 2);
      R_NC : constant Result :=
        Solve (NC, [1.0, 1.0], Params => (Tol => 1.0E-8, Max_Iter => 20));
   begin
      Check (not R_Z.Success and R_Z.Stat = Zero_Diagonal,
             "Zero diagonal rejected");
      Check (not R_Lim.Success and R_Lim.Stat = Iteration_Limit,
             "Iteration limit status");
      Check (R_Lim.Iterations = 2, "Iteration limit count");
      Check (not R_Tiny.Success and R_Tiny.Stat = Zero_Diagonal,
             "Tiny diagonal rejected");
      Check (not R_NC.Success and R_NC.Stat = Iteration_Limit,
             "Non-convergent hits Iteration_Limit");
      Check (R_NC.Iterations = 20, "Non-convergent used full budget");
   end;

   ---------------------------------------------------------------------
   Section ("10. Already-solved start / custom X0");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Poisson_1D, 3);
      X_Star : constant Vector (1 .. 3) := [2.0, 3.0, 4.0];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      R0 : constant Result :=
        Solve (A, B, X0 => X_Star, Params =>
          (Tol => 1.0E-8, Max_Iter => 10));
      X_Bad : constant Vector (1 .. 3) := [0.0, 0.0, 0.0];
      R1 : constant Result :=
        Solve (A, B, X0 => X_Bad, Params =>
          (Tol => 1.0E-5, Max_Iter => 500));
   begin
      Check (R0.Success, "Exact start Success");
      Check (R0.Iterations = 0, "Exact start 0 iters");
      Check (Approx (R0.X (2), 3.0, 1.0E-6), "Exact start x2");
      Check (R1.Success, "Zero start Success");
      Check (Approx (R1.X (1), 2.0, 1.0E-4), "Zero start x1");
      Check (Approx (R1.X (3), 4.0, 1.0E-4), "Zero start x3");
   end;

   ---------------------------------------------------------------------
   Section ("11. Empty X0 defaults to zero; Max_N boundary");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Diagonal_Plus_Ones, 2);
      B : constant Vector := Make_RHS_From_Solution (A, [3.0, -1.0]);
      Res : constant Result :=
        Solve (A, B, Params => (Tol => 1.0E-8, Max_Iter => 100));
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
      Res := Solve
        (A, B, Params => (Tol => 1.0E-5, Max_Iter => 5000));
      Check (Res.N = Max_N, "Max_N dimension");
      Check (Res.Success, "Max_N Success");
      Check (Approx (Res.X (1), 1.0, 1.0E-3), "Max_N x1");
      Check (Approx (Res.X (Max_N), 1.0, 1.0E-3), "Max_N x_n");
   end;

   ---------------------------------------------------------------------
   Section ("12. Residual decreases under GS on DD");
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
              Solve
                (A, B, Params => (Tol => 0.0, Max_Iter => Step));
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
   Section ("13. Classic wiki-style 2×2");
   ---------------------------------------------------------------------
   --  A = [[2,1],[1,2]], b = [3,3], exact x* = (1,1)
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[2.0, 1.0],
         [1.0, 2.0]];
      B : constant Vector (1 .. 2) := [3.0, 3.0];
      R_GS : constant Result :=
        Solve (A, B, Params => (Tol => 1.0E-9, Max_Iter => 100));
   begin
      Check (R_GS.Success, "Wiki 2x2 GS Success");
      Check (Approx (R_GS.X (1), 1.0, 1.0E-6), "Wiki GS x1");
      Check (Approx (R_GS.X (2), 1.0, 1.0E-6), "Wiki GS x2");
      Check (R_GS.Residual <= 1.0E-8, "Wiki GS residual");
      Check (R_GS.Stat = Converged, "Wiki GS Converged");
   end;

   ---------------------------------------------------------------------
   Section ("14. Tol sensitivity");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Diagonally_Dominant, 4);
      X_Star : constant Vector (1 .. 4) := [0.5, 1.5, -0.5, 2.0];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      R_Loose : constant Result :=
        Solve (A, B, Params => (Tol => 1.0E-3, Max_Iter => 500));
      R_Tight : constant Result :=
        Solve (A, B, Params => (Tol => 1.0E-8, Max_Iter => 2000));
   begin
      Check (R_Loose.Success, "Loose Tol Success");
      Check (R_Tight.Success, "Tight Tol Success");
      Check (R_Loose.Residual <= 1.0E-3, "Loose residual bound");
      Check (R_Tight.Residual <= 1.0E-8, "Tight residual bound");
      Check (R_Tight.Iterations >= R_Loose.Iterations,
             "Tighter Tol needs ≥ iters");
      Check (Approx (R_Tight.X (1), 0.5, 1.0E-5), "Tight x1");
      Check (Approx (R_Tight.X (4), 2.0, 1.0E-5), "Tight x4");
   end;

   ---------------------------------------------------------------------
   Section ("15. Default Max_Iter / Default_Parameters");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Poisson_1D, 5);
      X_Star : constant Vector (1 .. 5) := [1.0, 1.0, 1.0, 1.0, 1.0];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      Res : constant Result := Solve (A, B);
   begin
      Check (Res.Success, "Defaults Success");
      Check (Approx (Res.X (3), 1.0, 1.0E-4), "Defaults x3");
      Check (Res.Residual <= Default_Parameters.Tol, "Defaults residual");
      Check (Near (Default_Parameters.Tol, 1.0E-6), "Default Tol value");
      Check (Default_Parameters.Max_Iter = 0, "Default Max_Iter 0");
   end;

   ---------------------------------------------------------------------
   Section ("16. Successive displacement uses new values");
   ---------------------------------------------------------------------
   --  On a lower-triangular system GS solves exactly in one sweep
   declare
      A : constant Matrix (1 .. 3, 1 .. 3) :=
        [[2.0, 0.0, 0.0],
         [1.0, 3.0, 0.0],
         [1.0, 1.0, 4.0]];
      X_Star : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      Res : constant Result :=
        Solve (A, B, Params => (Tol => 1.0E-10, Max_Iter => 5));
   begin
      Check (Res.Success, "Lower-tri Success");
      Check (Res.Iterations <= 1, "Lower-tri exact in ≤1 sweep");
      Check (Approx (Res.X (1), 1.0, 1.0E-6), "Lower-tri x1");
      Check (Approx (Res.X (2), 2.0, 1.0E-6), "Lower-tri x2");
      Check (Approx (Res.X (3), 3.0, 1.0E-6), "Lower-tri x3");
   end;

   ---------------------------------------------------------------------
   Section ("17. Extra residual / Vec_Near checks");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Diagonally_Dominant, 3);
      X_Star : constant Vector (1 .. 3) := [2.0, -1.0, 0.5];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      Res : constant Result :=
        Solve (A, B, Params => (Tol => 1.0E-8, Max_Iter => 400));
      Rvec : constant Vector := Residual (A, Res.X (1 .. 3), B);
   begin
      Check (Res.Success, "Extra Success");
      Check (Vec_Near (Res.X (1 .. 3), X_Star, 1.0E-4), "Vec_Near solution");
      Check (Approx (Norm2 (Rvec), Res.Residual, 1.0E-6),
             "‖r‖ matches Result.Residual");
      Check (Approx (Rvec (1), 0.0, 1.0E-6), "r1 ~ 0");
      Check (Approx (Rvec (2), 0.0, 1.0E-6), "r2 ~ 0");
      Check (Approx (Rvec (3), 0.0, 1.0E-6), "r3 ~ 0");
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
