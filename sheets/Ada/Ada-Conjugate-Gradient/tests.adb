--  Standalone test suite for Conjugate_Gradient (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Conjugate_Gradient; use Conjugate_Gradient;

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
   Ada.Text_IO.Put_Line ("Conjugate_Gradient test suite");
   Ada.Text_IO.Put_Line ("=============================");

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
   Section ("2. Mat_Vec / Residual / symmetry helpers");
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
      Check (Is_Symmetric (A, 1.0E-9), "Is_Symmetric tight tol");
   end;

   ---------------------------------------------------------------------
   Section ("3. Make_SPD_Example generators");
   ---------------------------------------------------------------------
   declare
      H : constant Matrix := Make_SPD_Example (Hilbert_Tiny, 3);
      D : constant Matrix := Make_SPD_Example (Diagonal_Plus_Ones, 3);
      P : constant Matrix := Make_SPD_Example (Poisson_1D, 4);
      Z : constant Vector := Zero_Vector (3);
      Ones : constant Vector := Make_RHS_Ones (3);
   begin
      Check (Approx (H (1, 1), 1.0), "Hilbert H11");
      Check (Approx (H (1, 2), 0.5), "Hilbert H12");
      Check (Approx (H (2, 2), 1.0 / 3.0, 1.0E-6), "Hilbert H22");
      Check (Is_Symmetric (H), "Hilbert symmetric");
      Check (Approx (D (1, 1), 4.0), "Diag+ones diagonal");
      Check (Approx (D (1, 2), 1.0), "Diag+ones off");
      Check (Is_Symmetric (D), "Diag+ones symmetric");
      Check (Is_Diagonally_Dominant (D), "Diag+ones dominant");
      Check (Approx (P (1, 1), 2.0), "Poisson diag");
      Check (Approx (P (1, 2), -1.0), "Poisson off");
      Check (Approx (P (2, 1), -1.0), "Poisson sym");
      Check (Approx (P (4, 4), 2.0), "Poisson last");
      Check (Is_Symmetric (P), "Poisson symmetric");
      Check (Is_Diagonally_Dominant (P), "Poisson dominant");
      Check (Approx (Z (1), 0.0) and Approx (Z (3), 0.0), "Zero_Vector");
      Check (Approx (Ones (2), 1.0), "Make_RHS_Ones");
   end;

   ---------------------------------------------------------------------
   Section ("4. Known 2×2 SPD (Wikipedia Hestenes–Stiefel example)");
   ---------------------------------------------------------------------
   --  A = [[4,1],[1,3]], b = [1,2], exact x* = [1/11, 7/11].
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[4.0, 1.0],
         [1.0, 3.0]];
      B : constant Vector (1 .. 2) := [1.0, 2.0];
      X0 : constant Vector (1 .. 2) := [2.0, 1.0];
      Res : constant Result :=
        Conjugate_Gradient.Conjugate_Gradient (A, B, X0, (Tol => 1.0E-8, Max_Iter => 0));
      Exact_X : constant Float := 1.0 / 11.0;
      Exact_Y : constant Float := 7.0 / 11.0;
   begin
      Check (Res.Success, "2x2 Success");
      Check (Res.Stat = Converged, "2x2 Converged");
      Check (Res.N = 2, "2x2 N");
      Check (Res.Iterations <= 2, "2x2 ≤ n steps");
      Check (Approx (Res.X (1), Exact_X, 1.0E-5), "2x2 x1 = 1/11");
      Check (Approx (Res.X (2), Exact_Y, 1.0E-5), "2x2 x2 = 7/11");
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
      --  Choose x* = (1, 2, 3); b = A x*
      X_Star : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      B : constant Vector := Mat_Vec (A, X_Star);
      Res : constant Result :=
        Solve_SPD (A, B, Params => (Tol => 1.0E-7, Max_Iter => 0));
   begin
      Check (Is_Symmetric (A), "3x3 symmetric");
      Check (Is_Diagonally_Dominant (A), "3x3 dominant");
      Check (Res.Success, "3x3 Success");
      Check (Res.Iterations <= 3, "3x3 ≤ n steps");
      Check (Approx (Res.X (1), 1.0, 1.0E-4), "3x3 x1");
      Check (Approx (Res.X (2), 2.0, 1.0E-4), "3x3 x2");
      Check (Approx (Res.X (3), 3.0, 1.0E-4), "3x3 x3");
      Check (Res.Residual <= 1.0E-5, "3x3 residual");
   end;

   ---------------------------------------------------------------------
   Section ("6. Residual decreases / identity / diagonal systems");
   ---------------------------------------------------------------------
   declare
      I3 : Matrix (1 .. 3, 1 .. 3) := [others => [others => 0.0]];
      B  : constant Vector (1 .. 3) := [2.0, -1.0, 4.0];
      X0 : constant Vector (1 .. 3) := [0.0, 0.0, 0.0];
      Res : Result;
      R0, R1 : Float;
   begin
      for K in 1 .. 3 loop
         I3 (K, K) := 1.0;
      end loop;
      R0 := Residual_Norm (I3, X0, B);
      Res := Conjugate_Gradient.Conjugate_Gradient
        (I3, B, X0, (Tol => 1.0E-8, Max_Iter => 1));
      R1 := Res.Residual;
      Check (R0 > R1, "Residual decreases after 1 step");
      Check (Res.Success, "Identity Success");
      Check (Approx (Res.X (1), 2.0, 1.0E-5), "Identity x1");
      Check (Approx (Res.X (2), -1.0, 1.0E-5), "Identity x2");
      Check (Approx (Res.X (3), 4.0, 1.0E-5), "Identity x3");
      Check (Res.Iterations <= 1, "Identity 1-step (eigencluster)");
   end;

   declare
      D : Matrix (1 .. 4, 1 .. 4) := [others => [others => 0.0]];
      B : constant Vector (1 .. 4) := [2.0, 4.0, 6.0, 8.0];
      Res : Result;
   begin
      for K in 1 .. 4 loop
         D (K, K) := 2.0;
      end loop;
      Res := Solve_SPD (D, B, Params => (Tol => 1.0E-8, Max_Iter => 0));
      Check (Res.Success, "Diagonal Success");
      Check (Approx (Res.X (1), 1.0, 1.0E-5), "Diagonal x1");
      Check (Approx (Res.X (2), 2.0, 1.0E-5), "Diagonal x2");
      Check (Approx (Res.X (3), 3.0, 1.0E-5), "Diagonal x3");
      Check (Approx (Res.X (4), 4.0, 1.0E-5), "Diagonal x4");
   end;

   ---------------------------------------------------------------------
   Section ("7. n-step finite termination (approx. exact arith)");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_SPD_Example (Diagonal_Plus_Ones, 5);
      X_Star : constant Vector (1 .. 5) := [1.0, -1.0, 2.0, 0.5, -0.25];
      B : constant Vector := Mat_Vec (A, X_Star);
      Res : constant Result :=
        Solve_SPD (A, B, Params => (Tol => 1.0E-6, Max_Iter => 0));
   begin
      Check (Res.Success, "n-step Success");
      Check (Res.Iterations <= 5, "n-step ≤ 5");
      Check (Vec_Near (Res.X (1 .. 5), X_Star, 1.0E-3), "n-step solution");
      Check (Res.Residual <= 1.0E-5, "n-step residual");
   end;

   declare
      A : constant Matrix := Make_SPD_Example (Poisson_1D, 8);
      X_Star : Vector (1 .. 8);
      B : Vector (1 .. 8);
      Res : Result;
   begin
      for I in 1 .. 8 loop
         X_Star (I) := Float (I) * 0.1;
      end loop;
      B := Mat_Vec (A, X_Star);
      Res := Solve_SPD (A, B, Params => (Tol => 1.0E-6, Max_Iter => 0));
      Check (Res.Success, "Poisson Success");
      Check (Res.Iterations <= 8, "Poisson ≤ n");
      Check (Vec_Near (Res.X (1 .. 8), X_Star, 5.0E-4), "Poisson x*");
      Check (Res.Residual <= 1.0E-5, "Poisson residual");
   end;

   ---------------------------------------------------------------------
   Section ("8. Hilbert tiny / Solve_SPD zero start / Max_Iter");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_SPD_Example (Hilbert_Tiny, 3);
      X_Star : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      B : constant Vector := Mat_Vec (A, X_Star);
      Res : constant Result :=
        Solve_SPD (A, B, Params => (Tol => 1.0E-5, Max_Iter => 20));
      Limited_Run : constant Result :=
        Conjugate_Gradient.Conjugate_Gradient
          (A, B, Zero_Vector (3), (Tol => 1.0E-20, Max_Iter => 1));
   begin
      Check (Res.Success, "Hilbert Success");
      Check (Vec_Near (Res.X (1 .. 3), X_Star, 5.0E-3), "Hilbert x*");
      Check (Limited_Run.Iterations <= 1, "Max_Iter respected");
      Check (Limited_Run.Stat = Iteration_Limit
             or else Limited_Run.Stat = Converged,
             "Max_Iter status");
   end;

   ---------------------------------------------------------------------
   Section ("9. Already solved / nonzero start");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[2.0, 0.0],
         [0.0, 2.0]];
      B : constant Vector (1 .. 2) := [4.0, 6.0];
      X_Exact : constant Vector (1 .. 2) := [2.0, 3.0];
      Res0 : constant Result :=
        Conjugate_Gradient.Conjugate_Gradient
          (A, B, X_Exact, (Tol => 1.0E-8, Max_Iter => 0));
      Res1 : constant Result :=
        Conjugate_Gradient.Conjugate_Gradient
          (A, B, [0.0, 0.0], (Tol => 1.0E-8, Max_Iter => 0));
   begin
      Check (Res0.Success, "Already solved Success");
      Check (Res0.Iterations = 0, "Already solved 0 iters");
      Check (Approx (Res0.Residual, 0.0, 1.0E-7), "Already solved res");
      Check (Res1.Success, "From zero Success");
      Check (Approx (Res1.X (1), 2.0, 1.0E-5), "From zero x1");
      Check (Approx (Res1.X (2), 3.0, 1.0E-5), "From zero x2");
   end;

   ---------------------------------------------------------------------
   Section ("10. Fletcher–Reeves nonlinear CG (Sphere / Rosenbrock)");
   ---------------------------------------------------------------------
   declare
      X0 : constant Vector (1 .. 3) := [3.0, -2.0, 1.0];
      Res : constant Result :=
        Fletcher_Reeves
          (Sphere'Access, Sphere_Grad'Access, X0,
           (Tol => 1.0E-6, Max_Iter => 50));
   begin
      Check (Res.Success, "Sphere FR Success");
      Check (Approx (Res.X (1), 0.0, 1.0E-4), "Sphere x1~0");
      Check (Approx (Res.X (2), 0.0, 1.0E-4), "Sphere x2~0");
      Check (Approx (Res.X (3), 0.0, 1.0E-4), "Sphere x3~0");
      Check (Approx (Sphere (Res.X (1 .. 3)), 0.0, 1.0E-8), "Sphere f~0");
      Check (Approx (Norm2 (Sphere_Grad (Res.X (1 .. 3))), 0.0, 1.0E-4),
             "Sphere ‖g‖~0");
   end;

   declare
      X0 : constant Vector (1 .. 2) := [-1.2, 1.0];
      Res : constant Result :=
        Fletcher_Reeves
          (Rosenbrock'Access, Rosenbrock_Grad'Access, X0,
           (Tol => 1.0E-5, Max_Iter => 400));
   begin
      Check (Res.Success or else Res.Residual < 1.0E-3,
             "Rosenbrock progress");
      Check (Approx (Res.X (1), 1.0, 5.0E-2)
             or else Rosenbrock (Res.X (1 .. 2))
                       < Rosenbrock (X0),
             "Rosenbrock toward (1,1) or decrease");
      Check (Rosenbrock (Res.X (1 .. 2)) < 1.0, "Rosenbrock f smallish");
      Check (Approx (Rosenbrock ([1.0, 1.0]), 0.0), "Rosenbrock min value");
      Check (Approx (Norm2 (Rosenbrock_Grad ([1.0, 1.0])), 0.0, 1.0E-6),
             "Rosenbrock grad at min");
   end;

   ---------------------------------------------------------------------
   Section ("11. API / Parameters defaults");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_SPD_Example (Poisson_1D, 3);
      B : constant Vector := Make_RHS_Ones (3);
      R_Default : constant Result := Solve_SPD (A, B);
      R_Named   : constant Result :=
        Conjugate_Gradient.Conjugate_Gradient (A, B, Zero_Vector (3));
   begin
      Check (R_Default.Success, "Default Params Success");
      Check (R_Named.Success, "Named CG Success");
      Check (Vec_Near (R_Default.X (1 .. 3), R_Named.X (1 .. 3), 1.0E-4),
             "Solve_SPD ≡ Conjugate_Gradient");
      Check (Default_Parameters.Tol = 1.0E-6, "Default Tol");
      Check (Default_Parameters.Max_Iter = 0, "Default Max_Iter 0→N");
      Check (Make_SPD_Example (Poisson_1D, Max_N)'Length (1) = Max_N,
             "Make_SPD_Example accepts Max_N");
   end;

   ---------------------------------------------------------------------
   Section ("12. Extra residual-decrease path checks");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_SPD_Example (Diagonal_Plus_Ones, 4);
      B : constant Vector := Make_RHS_Ones (4);
      X : Vector (1 .. 4) := [0.0, 0.0, 0.0, 0.0];
      Prev, Cur : Float;
      Ok_Mono : Boolean := True;
   begin
      Prev := Residual_Norm (A, X, B);
      for Step in 1 .. 4 loop
         declare
            Partial : constant Result :=
              Conjugate_Gradient.Conjugate_Gradient
                (A, B, Zero_Vector (4),
                 (Tol => 0.0, Max_Iter => Step));
         begin
            Cur := Partial.Residual;
            if Cur > Prev + 1.0E-5 then
               Ok_Mono := False;
            end if;
            Prev := Cur;
            X := Partial.X (1 .. 4);
         end;
      end loop;
      Check (Ok_Mono, "Residual nonincreasing over partial runs");
      Check (Prev <= 1.0E-4, "Final residual small after n steps");
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
