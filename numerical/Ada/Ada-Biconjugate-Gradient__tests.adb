--  Standalone test suite for Biconjugate_Gradient (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Biconjugate_Gradient; use Biconjugate_Gradient;

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
   Ada.Text_IO.Put_Line ("Biconjugate_Gradient test suite");
   Ada.Text_IO.Put_Line ("===============================");

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
   end;

   ---------------------------------------------------------------------
   Section ("2. Mat_Vec / Mat_Vec_T / Transpose / Residual");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[4.0, 1.0],
         [2.0, 3.0]];
      X : constant Vector (1 .. 2) := [1.0, 1.0];
      B : constant Vector (1 .. 2) := [5.0, 5.0];
      Y : constant Vector := Mat_Vec (A, X);
      Yt : constant Vector := Mat_Vec_T (A, X);
      A_T : constant Matrix := Transpose (A);
      R : constant Vector := Residual (A, X, B);
   begin
      Check (Approx (Y (1), 5.0), "Mat_Vec row1");
      Check (Approx (Y (2), 5.0), "Mat_Vec row2");
      Check (Approx (Yt (1), 6.0), "Mat_Vec_T col1");
      Check (Approx (Yt (2), 4.0), "Mat_Vec_T col2");
      Check (Approx (A_T (1, 2), 2.0), "Transpose A12");
      Check (Approx (A_T (2, 1), 1.0), "Transpose A21");
      Check (Vec_Near (Mat_Vec (A_T, X), Yt), "Mat_Vec(Aᵀ)≡Mat_Vec_T");
      Check (Approx (R (1), 0.0), "Residual zero x");
      Check (Approx (R (2), 0.0), "Residual zero y");
      Check (Approx (Residual_Norm (A, X, B), 0.0), "Residual_Norm 0");
      Check (not Is_Symmetric (A), "nonsym Fixed_2x2-like");
      Check (Is_Diagonally_Dominant (A), "diag dominant A");
   end;

   ---------------------------------------------------------------------
   Section ("3. Make_Example generators");
   ---------------------------------------------------------------------
   declare
      ND : constant Matrix := Make_Example (Nonsym_DD, 4);
      CD : constant Matrix := Make_Example (Conv_Diff_1D, 5);
      SP : constant Matrix := Make_Example (SPD_Poisson, 4);
      F2 : constant Matrix := Make_Example (Fixed_2x2, 2);
      F3 : constant Matrix := Make_Example (Fixed_3x3, 3);
      Z  : constant Vector := Zero_Vector (3);
      Ones : constant Vector := Make_RHS_Ones (3);
   begin
      Check (not Is_Symmetric (ND), "Nonsym_DD nonsymmetric");
      Check (Is_Diagonally_Dominant (ND), "Nonsym_DD dominant");
      Check (Approx (ND (1, 1), 6.0), "Nonsym_DD diag n+2");
      Check (not Is_Symmetric (CD), "Conv_Diff nonsymmetric");
      Check (Approx (CD (2, 1), -1.4, 1.0E-6), "Conv_Diff lower");
      Check (Approx (CD (1, 2), -0.6, 1.0E-6), "Conv_Diff upper");
      Check (Is_Symmetric (SP), "SPD_Poisson symmetric");
      Check (Is_Diagonally_Dominant (SP), "SPD_Poisson dominant");
      Check (Approx (SP (1, 1), 2.0), "SPD_Poisson diag");
      Check (Approx (F2 (2, 1), 2.0), "Fixed_2x2 A21");
      Check (Approx (F3 (2, 2), 4.0), "Fixed_3x3 A22");
      Check (Approx (Z (1), 0.0) and Approx (Z (3), 0.0), "Zero_Vector");
      Check (Approx (Ones (2), 1.0), "Make_RHS_Ones");
      Check (Vec_Near (Mat_Vec_T (SP, Ones), Mat_Vec (SP, Ones)),
             "SPD Mat_Vec_T ≡ Mat_Vec");
   end;

   ---------------------------------------------------------------------
   Section ("4. Known Fixed_2x2 nonsymmetric");
   ---------------------------------------------------------------------
   --  A = [[4,1],[2,3]], x* = (1,2), b = A x* = (6,8)
   declare
      A : constant Matrix := Make_Example (Fixed_2x2, 2);
      X_Star : constant Vector (1 .. 2) := [1.0, 2.0];
      B : constant Vector := Mat_Vec (A, X_Star);
      Res : constant Result :=
        Solve (A, B, Params => (Tol => 1.0E-8, Max_Iter => 0));
   begin
      Check (Approx (B (1), 6.0), "2x2 b1");
      Check (Approx (B (2), 8.0), "2x2 b2");
      Check (Res.Success, "2x2 Success");
      Check (Res.Stat = Converged, "2x2 Converged");
      Check (Res.N = 2, "2x2 N");
      Check (Approx (Res.X (1), 1.0, 1.0E-4), "2x2 x1");
      Check (Approx (Res.X (2), 2.0, 1.0E-4), "2x2 x2");
      Check (Res.Residual <= 1.0E-6, "2x2 residual tol");
      Check (Approx (Residual_Norm (A, Res.X (1 .. 2), B),
                     Res.Residual, 1.0E-5),
             "2x2 Residual matches");
   end;

   ---------------------------------------------------------------------
   Section ("5. Known Fixed_3x3 nonsymmetric");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Fixed_3x3, 3);
      X_Star : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      B : constant Vector := Mat_Vec (A, X_Star);
      Res : constant Result :=
        Solve (A, B, Params => (Tol => 1.0E-7, Max_Iter => 0));
   begin
      Check (not Is_Symmetric (A), "3x3 nonsym");
      Check (Res.Success, "3x3 Success");
      Check (Approx (Res.X (1), 1.0, 1.0E-4), "3x3 x1");
      Check (Approx (Res.X (2), 2.0, 1.0E-4), "3x3 x2");
      Check (Approx (Res.X (3), 3.0, 1.0E-4), "3x3 x3");
      Check (Res.Residual <= 1.0E-5, "3x3 residual");
      Check (Res.Iterations <= 6, "3x3 ≤ 2n iters");
   end;

   ---------------------------------------------------------------------
   Section ("6. SPD recovery (Poisson / identity / diagonal)");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (SPD_Poisson, 5);
      X_Star : constant Vector (1 .. 5) := [1.0, -1.0, 2.0, 0.5, -0.25];
      B : constant Vector := Mat_Vec (A, X_Star);
      Res : constant Result :=
        Solve (A, B, Params => (Tol => 1.0E-6, Max_Iter => 0));
   begin
      Check (Is_Symmetric (A), "Poisson symmetric");
      Check (Res.Success, "Poisson BiCG Success");
      Check (Vec_Near (Res.X (1 .. 5), X_Star, 1.0E-3), "Poisson x*");
      Check (Res.Residual <= 1.0E-5, "Poisson residual");
   end;

   declare
      I3 : Matrix (1 .. 3, 1 .. 3) := [others => [others => 0.0]];
      B  : constant Vector (1 .. 3) := [2.0, -1.0, 4.0];
      Res : Result;
   begin
      for K in 1 .. 3 loop
         I3 (K, K) := 1.0;
      end loop;
      Res := Biconjugate_Gradient.Biconjugate_Gradient
        (I3, B, Zero_Vector (3), (Tol => 1.0E-8, Max_Iter => 0));
      Check (Res.Success, "Identity Success");
      Check (Approx (Res.X (1), 2.0, 1.0E-5), "Identity x1");
      Check (Approx (Res.X (2), -1.0, 1.0E-5), "Identity x2");
      Check (Approx (Res.X (3), 4.0, 1.0E-5), "Identity x3");
      Check (Res.Iterations <= 1, "Identity few steps");
   end;

   declare
      D : Matrix (1 .. 4, 1 .. 4) := [others => [others => 0.0]];
      B : constant Vector (1 .. 4) := [2.0, 4.0, 6.0, 8.0];
      Res : Result;
   begin
      for K in 1 .. 4 loop
         D (K, K) := 2.0;
      end loop;
      Res := Solve (D, B, Params => (Tol => 1.0E-8, Max_Iter => 0));
      Check (Res.Success, "Diagonal Success");
      Check (Approx (Res.X (1), 1.0, 1.0E-5), "Diagonal x1");
      Check (Approx (Res.X (2), 2.0, 1.0E-5), "Diagonal x2");
      Check (Approx (Res.X (3), 3.0, 1.0E-5), "Diagonal x3");
      Check (Approx (Res.X (4), 4.0, 1.0E-5), "Diagonal x4");
   end;

   ---------------------------------------------------------------------
   Section ("7. Nonsym_DD and Conv_Diff_1D solvable systems");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Nonsym_DD, 6);
      X_Star : Vector (1 .. 6);
      B : Vector (1 .. 6);
      Res : Result;
   begin
      for I in 1 .. 6 loop
         X_Star (I) := Float (I) * 0.25 - 0.5;
      end loop;
      B := Mat_Vec (A, X_Star);
      Res := Solve (A, B, Params => (Tol => 1.0E-7, Max_Iter => 40));
      Check (Res.Success, "Nonsym_DD Success");
      Check (Vec_Near (Res.X (1 .. 6), X_Star, 5.0E-4), "Nonsym_DD x*");
      Check (Res.Residual <= 1.0E-4, "Nonsym_DD residual");
   end;

   declare
      A : constant Matrix := Make_Example (Conv_Diff_1D, 8);
      X_Star : Vector (1 .. 8);
      B : Vector (1 .. 8);
      Res : Result;
   begin
      for I in 1 .. 8 loop
         X_Star (I) := Float (I) * 0.1;
      end loop;
      B := Mat_Vec (A, X_Star);
      Res := Solve (A, B, Params => (Tol => 1.0E-6, Max_Iter => 0));
      Check (Res.Success, "Conv_Diff Success");
      Check (Vec_Near (Res.X (1 .. 8), X_Star, 5.0E-4), "Conv_Diff x*");
      Check (Res.Residual <= 1.0E-5, "Conv_Diff residual");
      Check (Res.Iterations <= 16, "Conv_Diff ≤ 2n");
   end;

   ---------------------------------------------------------------------
   Section ("8. Already solved / nonzero start / Max_Iter");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Fixed_2x2, 2);
      X_Exact : constant Vector (1 .. 2) := [1.0, 2.0];
      B : constant Vector := Mat_Vec (A, X_Exact);
      Res0 : constant Result :=
        Biconjugate_Gradient.Biconjugate_Gradient
          (A, B, X_Exact, (Tol => 1.0E-8, Max_Iter => 0));
      Res1 : constant Result :=
        Biconjugate_Gradient.Biconjugate_Gradient
          (A, B, [0.0, 0.0], (Tol => 1.0E-8, Max_Iter => 0));
      Limited_Run : constant Result :=
        Biconjugate_Gradient.Biconjugate_Gradient
          (A, B, Zero_Vector (2), (Tol => 1.0E-20, Max_Iter => 1));
   begin
      Check (Res0.Success, "Already solved Success");
      Check (Res0.Iterations = 0, "Already solved 0 iters");
      Check (Approx (Res0.Residual, 0.0, 1.0E-7), "Already solved res");
      Check (Res1.Success, "From zero Success");
      Check (Approx (Res1.X (1), 1.0, 1.0E-4), "From zero x1");
      Check (Approx (Res1.X (2), 2.0, 1.0E-4), "From zero x2");
      Check (Limited_Run.Iterations <= 1, "Max_Iter respected");
      Check (Limited_Run.Stat = Iteration_Limit
             or else Limited_Run.Stat = Converged
             or else Limited_Run.Stat = Breakdown,
             "Max_Iter status");
   end;

   ---------------------------------------------------------------------
   Section ("9. Wikipedia-style SPD 2×2 (BiCG recovers CG path)");
   ---------------------------------------------------------------------
   --  A = [[4,1],[1,3]], b = [1,2], exact x* = [1/11, 7/11].
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[4.0, 1.0],
         [1.0, 3.0]];
      B : constant Vector (1 .. 2) := [1.0, 2.0];
      X0 : constant Vector (1 .. 2) := [2.0, 1.0];
      Res : constant Result :=
        Biconjugate_Gradient.Biconjugate_Gradient
          (A, B, X0, (Tol => 1.0E-8, Max_Iter => 0));
      Exact_X : constant Float := 1.0 / 11.0;
      Exact_Y : constant Float := 7.0 / 11.0;
   begin
      Check (Is_Symmetric (A), "Wiki 2x2 symmetric");
      Check (Res.Success, "Wiki 2x2 Success");
      Check (Approx (Res.X (1), Exact_X, 1.0E-5), "Wiki 2x2 x1 = 1/11");
      Check (Approx (Res.X (2), Exact_Y, 1.0E-5), "Wiki 2x2 x2 = 7/11");
      Check (Res.Residual <= 1.0E-6, "Wiki 2x2 residual");
   end;

   ---------------------------------------------------------------------
   Section ("10. API defaults / Solve empty X0 / Parameters");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (SPD_Poisson, 3);
      B : constant Vector := Make_RHS_Ones (3);
      R_Default : constant Result := Solve (A, B);
      R_Named   : constant Result :=
        Biconjugate_Gradient.Biconjugate_Gradient
          (A, B, Zero_Vector (3));
   begin
      Check (R_Default.Success, "Default Params Success");
      Check (R_Named.Success, "Named BiCG Success");
      Check (Vec_Near (R_Default.X (1 .. 3), R_Named.X (1 .. 3), 1.0E-4),
             "Solve ≡ Biconjugate_Gradient");
      Check (Default_Parameters.Tol = 1.0E-6, "Default Tol");
      Check (Default_Parameters.Max_Iter = 0, "Default Max_Iter 0→2N");
      Check (Make_Example (SPD_Poisson, Max_N)'Length (1) = Max_N,
             "Make_Example accepts Max_N");
      Check (R_Default.N = 3, "Result.N set");
      Check (R_Default.Success = (R_Default.Stat = Converged),
             "Success iff Converged");
   end;

   ---------------------------------------------------------------------
   Section ("11. Residual consistency across sizes");
   ---------------------------------------------------------------------
   for N in Dimension range 2 .. 8 loop
      declare
         A : constant Matrix := Make_Example (Nonsym_DD, N);
         X_Star : Vector (1 .. N);
         B : Vector (1 .. N);
         Res : Result;
         Ok : Boolean;
      begin
         for I in 1 .. N loop
            X_Star (I) := Float (I);
         end loop;
         B := Mat_Vec (A, X_Star);
         Res := Solve (A, B, Params => (Tol => 1.0E-6, Max_Iter => 0));
         Ok := Res.Success
           and then Vec_Near (Res.X (1 .. N), X_Star, 1.0E-3)
           and then Res.Residual <= 1.0E-4;
         Check (Ok, "Nonsym_DD n=" & N'Image);
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("12. Iteration_Limit / Breakdown-safe paths");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Conv_Diff_1D, 6);
      X_Star : constant Vector (1 .. 6) :=
        [1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
      B : constant Vector := Mat_Vec (A, X_Star);
      Tight : constant Result :=
        Biconjugate_Gradient.Biconjugate_Gradient
          (A, B, Zero_Vector (6), (Tol => 1.0E-20, Max_Iter => 2));
   begin
      Check (Tight.Iterations <= 2, "Tight Max_Iter bound");
      Check (Tight.Stat = Iteration_Limit
             or else Tight.Stat = Converged
             or else Tight.Stat = Breakdown,
             "Tight status is terminal");
      Check (not (Tight.Stat = Ill_Started), "Not Ill_Started");
      Check (not (Tight.Stat = Dimension_Error), "Not Dimension_Error");
   end;

   --  Singular-ish / zero RHS already-at-solution edge
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 1.0]];
      B : constant Vector (1 .. 2) := [0.0, 0.0];
      Res : constant Result :=
        Solve (A, B, Params => (Tol => 1.0E-8, Max_Iter => 0));
   begin
      Check (Res.Success, "Zero RHS Success");
      Check (Res.Iterations = 0, "Zero RHS 0 iters");
      Check (Approx (Res.X (1), 0.0, 1.0E-8), "Zero RHS x1");
      Check (Approx (Res.X (2), 0.0, 1.0E-8), "Zero RHS x2");
   end;

   ---------------------------------------------------------------------
   Section ("13. Mat_Vec_T consistency / Transpose round-trip");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Conv_Diff_1D, 4);
      A_T : constant Matrix := Transpose (A);
      A_TT : constant Matrix := Transpose (A_T);
      X : constant Vector (1 .. 4) := [1.0, -1.0, 0.5, 2.0];
   begin
      Check (Vec_Near
               (Mat_Vec_T (A, X), Mat_Vec (A_T, X), 1.0E-6),
             "Mat_Vec_T ≡ Mat_Vec(Transpose)");
      Check (Approx (A_TT (1, 2), A (1, 2), 1.0E-9), "Transpose² A12");
      Check (Approx (A_TT (3, 1), A (3, 1), 1.0E-9), "Transpose² A31");
      Check (Approx (A_TT (4, 4), A (4, 4), 1.0E-9), "Transpose² A44");
      Check (not Is_Symmetric (A), "Conv_Diff still nonsym");
      Check (Is_Symmetric (Make_Example (SPD_Poisson, 4)),
             "Poisson still sym");
   end;

   ---------------------------------------------------------------------
   Section ("14. Nonzero start residual decrease");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Nonsym_DD, 4);
      X_Star : constant Vector (1 .. 4) := [1.0, 2.0, 3.0, 4.0];
      B : constant Vector := Mat_Vec (A, X_Star);
      X0 : constant Vector (1 .. 4) := [0.5, 0.5, 0.5, 0.5];
      R0 : constant Float := Residual_Norm (A, X0, B);
      Res : constant Result :=
        Biconjugate_Gradient.Biconjugate_Gradient
          (A, B, X0, (Tol => 1.0E-7, Max_Iter => 0));
   begin
      Check (R0 > 0.0, "Nonzero start residual > 0");
      Check (Res.Success, "Nonzero start Success");
      Check (Res.Residual < R0, "Residual decreased");
      Check (Vec_Near (Res.X (1 .. 4), X_Star, 1.0E-3), "Nonzero start x*");
   end;

   ---------------------------------------------------------------------
   Section ("15. Status enumeration / Success flag");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Make_Example (Fixed_2x2, 2);
      B : constant Vector := Mat_Vec (A, [1.0, 1.0]);
      Good : constant Result := Solve (A, B);
      Bad_Budget : constant Result :=
        Biconjugate_Gradient.Biconjugate_Gradient
          (A, B, Zero_Vector (2), (Tol => 1.0E-30, Max_Iter => 0));
   begin
      Check (Good.Stat = Converged, "Good → Converged");
      Check (Good.Success, "Good Success True");
      Check (Status'Pos (Converged) = 0, "Status Converged pos");
      Check (Status'Pos (Iteration_Limit) = 1, "Status Iter pos");
      Check (Status'Pos (Breakdown) = 2, "Status Breakdown pos");
      Check (Status'Pos (Ill_Started) = 3, "Status Ill_Started pos");
      Check (Status'Pos (Dimension_Error) = 4, "Status Dim_Error pos");
      Check (Bad_Budget.Stat = Converged
             or else Bad_Budget.Stat = Iteration_Limit
             or else Bad_Budget.Stat = Breakdown,
             "Tight tol terminal status");
      Check (Ill_Started'Image'Length > 0, "Ill_Started named");
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
