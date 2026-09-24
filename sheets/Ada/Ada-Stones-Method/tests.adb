--  Standalone test suite for Stones_Method (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Stones_Method; use Stones_Method;

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
   Ada.Text_IO.Put_Line ("Stones_Method test suite");
   Ada.Text_IO.Put_Line ("========================");

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
   Section ("2. Mat_Vec / Residual / symmetry");
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
   end;

   ---------------------------------------------------------------------
   Section ("3. Make_Poisson_2D / pentadiagonal");
   ---------------------------------------------------------------------
   declare
      P  : constant Pentadiagonal := Make_Poisson_2D (2);
      A  : constant Matrix := Pentadiagonal_To_Dense (P);
      X  : constant Vector (1 .. 4) := [1.0, 2.0, 3.0, 4.0];
      Ax : constant Vector := Apply_Pentadiagonal (P, X);
      Ad : constant Vector := Mat_Vec (A, X);
   begin
      Check (P.N_Grid = 2, "Poisson2D N_Grid");
      Check (P.N = 4, "Poisson2D N");
      Check (Approx (P.A_P (1), 4.0), "Poisson2D A_P");
      Check (Approx (P.A_E (1), -1.0), "Poisson2D A_E");
      Check (Approx (P.A_W (1), 0.0), "Poisson2D no west on left");
      Check (Approx (P.A_S (1), 0.0), "Poisson2D no south on bottom");
      Check (Approx (P.A_N (1), -1.0), "Poisson2D A_N");
      Check (Approx (P.A_W (2), -1.0), "Poisson2D west of (1,2)");
      Check (Is_Symmetric (A), "Dense Poisson2D symmetric");
      Check (Is_Diagonally_Dominant (A), "Dense Poisson2D DD");
      Check (Approx (Ax (1), Ad (1)), "Penta vs dense 1");
      Check (Approx (Ax (2), Ad (2)), "Penta vs dense 2");
      Check (Approx (Ax (3), Ad (3)), "Penta vs dense 3");
      Check (Approx (Ax (4), Ad (4)), "Penta vs dense 4");
   end;

   ---------------------------------------------------------------------
   Section ("4. Make_Example generators");
   ---------------------------------------------------------------------
   declare
      D   : constant Matrix := Make_Example (Diagonally_Dominant, 3);
      P1  : constant Matrix := Make_Example (Poisson_1D, 4);
      P2  : constant Matrix := Make_Example (Poisson_2D, 2);
      Z   : constant Vector := Zero_Vector (3);
      Ones : constant Vector := Make_RHS_Ones (3);
      X_Star : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      B_From : constant Vector := Make_RHS_From_Solution (D, X_Star);
   begin
      Check (Approx (D (1, 1), 3.0), "DD diagonal");
      Check (Approx (D (1, 2), 1.0), "DD off");
      Check (Is_Symmetric (D), "DD symmetric");
      Check (Is_Diagonally_Dominant (D), "DD dominant");
      Check (Approx (P1 (1, 1), 2.0), "Poisson1D diag");
      Check (Approx (P1 (1, 2), -1.0), "Poisson1D off");
      Check (Is_Symmetric (P1), "Poisson1D symmetric");
      Check (P2'Length (1) = 4, "Poisson2D dense size");
      Check (Approx (Z (1), 0.0) and Approx (Z (3), 0.0), "Zero_Vector");
      Check (Approx (Ones (2), 1.0), "Make_RHS_Ones");
      Check (Approx (B_From (1), Mat_Vec (D, X_Star) (1)), "RHS from sol");
   end;

   ---------------------------------------------------------------------
   Section ("5. Factor_SIP + Apply on 2×2 grid");
   ---------------------------------------------------------------------
   declare
      P : constant Pentadiagonal := Make_Poisson_2D (2);
      F : constant SIP_Factors := Factor_SIP (P, 0.92);
      R : constant Vector (1 .. 4) := [1.0, 0.0, 0.0, 0.0];
      Z : constant Vector := Apply_SIP_Preconditioner (F, R);
   begin
      Check (F.Valid, "Factor_SIP valid");
      Check (F.N = 4, "Factor_SIP N");
      Check (Approx (F.Alpha, 0.92), "Factor_SIP alpha");
      Check (abs (F.L_P (1)) > 0.0, "Factor_SIP L_P nonzero");
      Check (Z'Length = 4, "Apply_SIP length");
      Check (Norm2 (Z) > 0.0, "Apply_SIP nonzero response");
   end;

   ---------------------------------------------------------------------
   Section ("6. Tiny Poisson 2×2 known solution (SIP)");
   ---------------------------------------------------------------------
   --  Exact x* = (1,2,3,4); b := A x*
   declare
      P : constant Pentadiagonal := Make_Poisson_2D (2);
      X_Star : constant Vector (1 .. 4) := [1.0, 2.0, 3.0, 4.0];
      B : constant Vector := Make_RHS_From_Solution (P, X_Star);
      Res : constant Result :=
        Solve_SIP (P, B, Params =>
          (Alpha => 0.92, Tol => 1.0E-8, Max_Iter => 200));
   begin
      Check (Res.Success, "2x2 SIP Success");
      Check (Res.Stat = Converged, "2x2 SIP Converged");
      Check (Res.N = 4, "2x2 SIP N");
      Check (Approx (Res.X (1), 1.0, 1.0E-4), "2x2 SIP x1");
      Check (Approx (Res.X (2), 2.0, 1.0E-4), "2x2 SIP x2");
      Check (Approx (Res.X (3), 3.0, 1.0E-4), "2x2 SIP x3");
      Check (Approx (Res.X (4), 4.0, 1.0E-4), "2x2 SIP x4");
      Check (Res.Residual <= 1.0E-6, "2x2 SIP residual");
      Check (Approx (Residual_Norm_Penta (P, Res.X (1 .. 4), B),
                     Res.Residual, 1.0E-5),
             "2x2 SIP Residual matches");
   end;

   ---------------------------------------------------------------------
   Section ("7. Residual decreases across SIP iterations");
   ---------------------------------------------------------------------
   declare
      P : constant Pentadiagonal := Make_Poisson_2D (3);
      X_Star : constant Vector (1 .. 9) :=
        [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0];
      B : constant Vector := Make_RHS_From_Solution (P, X_Star);
      R0 : constant Float :=
        Residual_Norm_Penta (P, Zero_Vector (9), B);
      Res1 : constant Result :=
        Solve_SIP (P, B, Params =>
          (Alpha => 0.92, Tol => 0.0, Max_Iter => 1));
      Res5 : constant Result :=
        Solve_SIP (P, B, Params =>
          (Alpha => 0.92, Tol => 0.0, Max_Iter => 5));
      ResC : constant Result :=
        Solve_SIP (P, B, Params =>
          (Alpha => 0.92, Tol => 1.0E-8, Max_Iter => 500));
   begin
      Check (R0 > 0.0, "3x3 initial residual positive");
      Check (Res1.Residual < R0, "3x3 residual after 1 iter < R0");
      Check (Res5.Residual < Res1.Residual,
             "3x3 residual after 5 < after 1");
      Check (ResC.Success, "3x3 SIP converges");
      Check (ResC.Residual <= 1.0E-6, "3x3 final residual small");
      Check (Approx (ResC.X (5), 5.0, 1.0E-3), "3x3 center value");
   end;

   ---------------------------------------------------------------------
   Section ("8. Alpha = 0 (ILU-like) still works");
   ---------------------------------------------------------------------
   declare
      P : constant Pentadiagonal := Make_Poisson_2D (2);
      X_Star : constant Vector (1 .. 4) := [1.0, 1.0, 1.0, 1.0];
      B : constant Vector := Make_RHS_From_Solution (P, X_Star);
      Res : constant Result :=
        Solve_SIP (P, B, Params =>
          (Alpha => 0.0, Tol => 1.0E-8, Max_Iter => 200));
   begin
      Check (Res.Success, "alpha0 Success");
      Check (Approx (Res.X (1), 1.0, 1.0E-4), "alpha0 x1");
      Check (Approx (Res.X (4), 1.0, 1.0E-4), "alpha0 x4");
   end;

   ---------------------------------------------------------------------
   Section ("9. Bad_Alpha / factorization edge");
   ---------------------------------------------------------------------
   declare
      P : constant Pentadiagonal := Make_Poisson_2D (2);
      B : constant Vector := Make_RHS_Ones (4);
      Bad : constant Result :=
        Solve_SIP (P, B, Params =>
          (Alpha => 1.5, Tol => 1.0E-8, Max_Iter => 10));
   begin
      Check (Bad.Stat = Bad_Alpha, "Bad_Alpha rejected");
      Check (not Bad.Success, "Bad_Alpha not success");
   end;

   ---------------------------------------------------------------------
   Section ("10. Dense SIP / ILU0 on DD system");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Diagonally_Dominant, 4);
      X_Star : constant Vector (1 .. 4) := [1.0, -1.0, 2.0, 0.5];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      F : constant Dense_ILU := Factor_ILU0 (A, 0.5);
      Res : constant Result :=
        Solve_SIP_Dense (A, B, Params =>
          (Alpha => 0.5, Tol => 1.0E-8, Max_Iter => 200));
   begin
      Check (F.Valid, "Dense ILU0 valid");
      Check (Res.Success, "Dense SIP Success");
      Check (Approx (Res.X (1), 1.0, 1.0E-4), "Dense SIP x1");
      Check (Approx (Res.X (2), -1.0, 1.0E-4), "Dense SIP x2");
      Check (Approx (Res.X (3), 2.0, 1.0E-4), "Dense SIP x3");
      Check (Approx (Res.X (4), 0.5, 1.0E-4), "Dense SIP x4");
      Check (Res.Residual <= 1.0E-6, "Dense SIP residual");
   end;

   ---------------------------------------------------------------------
   Section ("11. Dense Poisson_1D via SIP_Dense");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Poisson_1D, 5);
      X_Star : constant Vector (1 .. 5) := [1.0, 2.0, 3.0, 2.0, 1.0];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      Res : constant Result :=
        Solve_SIP_Dense (A, B, Params =>
          (Alpha => 0.0, Tol => 1.0E-8, Max_Iter => 100));
   begin
      Check (Res.Success, "P1D dense Success");
      Check (Approx (Res.X (1), 1.0, 1.0E-4), "P1D x1");
      Check (Approx (Res.X (3), 3.0, 1.0E-4), "P1D x3");
      Check (Approx (Res.X (5), 1.0, 1.0E-4), "P1D x5");
   end;

   ---------------------------------------------------------------------
   Section ("12. Jacobi / Gauss–Seidel comparison");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Diagonally_Dominant, 3);
      X_Star : constant Vector (1 .. 3) := [2.0, 1.0, -1.0];
      B : constant Vector := Make_RHS_From_Solution (A, X_Star);
      RJ : constant Result :=
        Solve_Jacobi (A, B, Params =>
          (Alpha => 0.0, Tol => 1.0E-8, Max_Iter => 500));
      RG : constant Result :=
        Solve_Gauss_Seidel (A, B, Params =>
          (Alpha => 0.0, Tol => 1.0E-8, Max_Iter => 500));
      RS : constant Result :=
        Solve_SIP_Dense (A, B, Params =>
          (Alpha => 0.9, Tol => 1.0E-8, Max_Iter => 200));
   begin
      Check (RJ.Success, "Jacobi Success");
      Check (RG.Success, "GS Success");
      Check (RS.Success, "SIP vs GS Success");
      Check (Approx (RJ.X (1), 2.0, 1.0E-4), "Jacobi x1");
      Check (Approx (RG.X (2), 1.0, 1.0E-4), "GS x2");
      Check (Approx (RS.X (3), -1.0, 1.0E-4), "SIP x3");
      Check (RG.Iterations <= RJ.Iterations,
             "GS iters ≤ Jacobi iters");
      Check (RS.Iterations <= RG.Iterations + 5,
             "SIP competitive with GS");
   end;

   ---------------------------------------------------------------------
   Section ("13. Larger 4×4 Poisson SIP");
   ---------------------------------------------------------------------
   declare
      P : constant Pentadiagonal := Make_Poisson_2D (4);
      X_Star : Vector (1 .. 16);
      B : Vector (1 .. 16);
      Res : Result;
   begin
      for I in 1 .. 16 loop
         X_Star (I) := Float (I);
      end loop;
      B := Make_RHS_From_Solution (P, X_Star);
      --  Float residual floor with alpha=0.92 can stall near 1e-5 on
      --  this size; alpha closer to 1 recovers full convergence.
      Res := Solve_SIP (P, B, Params =>
        (Alpha => 0.99, Tol => 1.0E-6, Max_Iter => 1_000));
      Check (P.N = 16, "4x4 N");
      Check (Res.Success, "4x4 SIP Success");
      Check (Approx (Res.X (1), 1.0, 1.0E-3), "4x4 x1");
      Check (Approx (Res.X (16), 16.0, 1.0E-3), "4x4 x16");
      Check (Res.Residual <= 1.0E-5, "4x4 residual");
   end;

   ---------------------------------------------------------------------
   Section ("14. Nonzero start / RHS helpers");
   ---------------------------------------------------------------------
   declare
      P : constant Pentadiagonal := Make_Poisson_2D (2);
      X0 : constant Vector (1 .. 4) := [0.5, 0.5, 0.5, 0.5];
      X_Star : constant Vector (1 .. 4) := [1.0, 1.0, 1.0, 1.0];
      B : constant Vector := Make_RHS_From_Solution (P, X_Star);
      Res : constant Result :=
        Solve_SIP (P, B, X0, Params =>
          (Alpha => 0.92, Tol => 1.0E-8, Max_Iter => 100));
      Rvec : constant Vector := Residual_Penta (P, X_Star, B);
   begin
      Check (Res.Success, "warm start Success");
      Check (Approx (Norm2 (Rvec), 0.0), "exact residual 0");
      Check (Approx (Res.X (2), 1.0, 1.0E-4), "warm start x2");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("----------------------------------------");
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
