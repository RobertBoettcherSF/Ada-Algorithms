--  Levenberg_Marquardt body — damped least squares with Marquardt
--  diagonal scaling (Levenberg 1944; Marquardt 1963; Wikipedia).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Levenberg_Marquardt
  with SPARK_Mode => Off
is

   package EF is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use EF;

   ---------------------------------------------------------------------------
   -- Built-in sample data (curve-fitting demos)
   ---------------------------------------------------------------------------

   --  Abscissae shared by linear / quadratic / exponential demos.
   Sample_N : constant := 8;
   Sample_X : constant array (1 .. Sample_N) of Real :=
     [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5];

   --  y = 2 + 3 x
   Linear_Y : constant array (1 .. Sample_N) of Real :=
     [2.0, 3.5, 5.0, 6.5, 8.0, 9.5, 11.0, 12.5];

   --  y = 1 − 2 x + 0.5 x²
   Quadratic_Y : constant array (1 .. Sample_N) of Real :=
     [1.0, 0.125, -0.5, -0.875, -1.0, -0.875, -0.5, 0.125];

   --  y = 5 · e^(−0.4 x)
   Exp_Y : constant array (1 .. Sample_N) of Real :=
     [5.000_000_000_000_000,
      4.093_653_765_389_909,
      3.351_600_230_178_197,
      2.744_058_180_470_132,
      2.246_644_820_586_108,
      1.839_397_205_857_212,
      1.505_971_059_561_010,
      1.232_984_819_708_032];

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Params_Near
     (A, B : Parameter_Vector; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      for I in A'Range loop
         if abs (A (I) - B (I - A'First + B'First)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Params_Near;

   function Residuals_Near
     (A, B : Residual_Vector; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      for I in A'Range loop
         if abs (A (I) - B (I - A'First + B'First)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Residuals_Near;

   function Norm2 (X : Parameter_Vector) return Non_Negative is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I) * X (I);
      end loop;
      return Non_Negative (Sqrt (S));
   end Norm2;

   function Residual_Norm2 (R : Residual_Vector) return Non_Negative is
      S : Real := 0.0;
   begin
      for I in R'Range loop
         S := S + R (I) * R (I);
      end loop;
      return Non_Negative (Sqrt (S));
   end Residual_Norm2;

   function Dot (A, B : Parameter_Vector) return Real is
      S : Real := 0.0;
      J : Param_Index := B'First;
   begin
      for I in A'Range loop
         S := S + A (I) * B (J);
         if J < B'Last then
            J := J + 1;
         end if;
      end loop;
      return S;
   end Dot;

   function Residual_Dot (A, B : Residual_Vector) return Real is
      S : Real := 0.0;
      J : Residual_Index := B'First;
   begin
      for I in A'Range loop
         S := S + A (I) * B (J);
         if J < B'Last then
            J := J + 1;
         end if;
      end loop;
      return S;
   end Residual_Dot;

   function Add (A, B : Parameter_Vector) return Parameter_Vector is
      R : Parameter_Vector (A'Range);
      J : Param_Index := B'First;
   begin
      for I in A'Range loop
         R (I) := A (I) + B (J);
         if J < B'Last then
            J := J + 1;
         end if;
      end loop;
      return R;
   end Add;

   function Sub (A, B : Parameter_Vector) return Parameter_Vector is
      R : Parameter_Vector (A'Range);
      J : Param_Index := B'First;
   begin
      for I in A'Range loop
         R (I) := A (I) - B (J);
         if J < B'Last then
            J := J + 1;
         end if;
      end loop;
      return R;
   end Sub;

   function Scale (C : Real; X : Parameter_Vector) return Parameter_Vector is
      R : Parameter_Vector (X'Range);
   begin
      for I in X'Range loop
         R (I) := C * X (I);
      end loop;
      return R;
   end Scale;

   function Cost (R : Residual_Vector) return Non_Negative is
      S : Real := 0.0;
   begin
      for I in R'Range loop
         S := S + R (I) * R (I);
      end loop;
      return Non_Negative (0.5 * S);
   end Cost;

   ---------------------------------------------------------------------------
   -- Linear algebra
   ---------------------------------------------------------------------------

   function JTJ (J : Jacobian) return Square_Matrix is
      N : constant Param_Count := J'Length (2);
      A : Square_Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      Col_J : Param_Index;
      Col_K : Param_Index;
   begin
      for Pj in 1 .. N loop
         Col_J := J'First (2) + (Pj - 1);
         for Pk in 1 .. N loop
            Col_K := J'First (2) + (Pk - 1);
            declare
               S : Real := 0.0;
            begin
               for Ri in J'Range (1) loop
                  S := S + J (Ri, Col_J) * J (Ri, Col_K);
               end loop;
               A (Pj, Pk) := S;
            end;
         end loop;
      end loop;
      return A;
   end JTJ;

   function JTr (J : Jacobian; R : Residual_Vector) return Parameter_Vector is
      N : constant Param_Count := J'Length (2);
      G : Parameter_Vector (1 .. N) := [others => 0.0];
      Col : Param_Index;
      Rj  : Residual_Index;
   begin
      for Pj in 1 .. N loop
         Col := J'First (2) + (Pj - 1);
         declare
            S : Real := 0.0;
         begin
            Rj := R'First;
            for Ri in J'Range (1) loop
               S := S + J (Ri, Col) * R (Rj);
               if Rj < R'Last then
                  Rj := Rj + 1;
               end if;
            end loop;
            G (Pj) := S;
         end;
      end loop;
      return G;
   end JTr;

   function Mat_Vec (A : Square_Matrix; X : Parameter_Vector)
     return Parameter_Vector
   is
      N : constant Param_Count := X'Length;
      Y : Parameter_Vector (1 .. N) := [others => 0.0];
      Ai : Param_Index;
      Aj : Param_Index;
      Xj : Param_Index;
   begin
      for I in 1 .. N loop
         Ai := A'First (1) + (I - 1);
         declare
            S : Real := 0.0;
         begin
            Xj := X'First;
            for J in 1 .. N loop
               Aj := A'First (2) + (J - 1);
               S := S + A (Ai, Aj) * X (Xj);
               if Xj < X'Last then
                  Xj := Xj + 1;
               end if;
            end loop;
            Y (I) := S;
         end;
      end loop;
      return Y;
   end Mat_Vec;

   function Solve_SPD
     (A : Square_Matrix; B : Parameter_Vector) return Parameter_Vector
   is
      N : constant Param_Count := B'Length;
      M : array (1 .. N, 1 .. N) of Real;
      Rhs : array (1 .. N) of Real;
      X   : Parameter_Vector (1 .. N) := [others => 0.0];
      Pivot : Param_Index;
      Max_Abs : Real;
      Tmp : Real;
      Factor : Real;
   begin
      --  Copy into dense 1-based working arrays.
      for I in 1 .. N loop
         for J in 1 .. N loop
            M (I, J) := A (A'First (1) + (I - 1), A'First (2) + (J - 1));
         end loop;
         Rhs (I) := B (B'First + (I - 1));
      end loop;

      --  Gaussian elimination with partial pivoting.
      for K in 1 .. N loop
         Pivot := K;
         Max_Abs := abs (M (K, K));
         for I in K + 1 .. N loop
            if abs (M (I, K)) > Max_Abs then
               Max_Abs := abs (M (I, K));
               Pivot := I;
            end if;
         end loop;

         if Max_Abs < 1.0E-18 then
            raise Singular_System;
         end if;

         if Pivot /= K then
            for J in K .. N loop
               Tmp := M (K, J);
               M (K, J) := M (Pivot, J);
               M (Pivot, J) := Tmp;
            end loop;
            Tmp := Rhs (K);
            Rhs (K) := Rhs (Pivot);
            Rhs (Pivot) := Tmp;
         end if;

         for I in K + 1 .. N loop
            Factor := M (I, K) / M (K, K);
            M (I, K) := 0.0;
            for J in K + 1 .. N loop
               M (I, J) := M (I, J) - Factor * M (K, J);
            end loop;
            Rhs (I) := Rhs (I) - Factor * Rhs (K);
         end loop;
      end loop;

      --  Back substitution.
      for I in reverse 1 .. N loop
         declare
            S : Real := Rhs (I);
         begin
            for J in I + 1 .. N loop
               S := S - M (I, J) * X (J);
            end loop;
            if abs (M (I, I)) < 1.0E-18 then
               raise Singular_System;
            end if;
            X (I) := S / M (I, I);
         end;
      end loop;

      return X;
   end Solve_SPD;

   function Finite_Difference_Jacobian
     (Model : Model_Fn;
      Beta  : Parameter_Vector;
      Eps   : Positive_Real := 1.0E-7) return Jacobian
   is
      N : constant Param_Count := Beta'Length;
      R0 : constant Residual_Vector := Model (Beta);
      M  : constant Residual_Count := R0'Length;
      J  : Jacobian (1 .. M, 1 .. N) := [others => [others => 0.0]];
      Beta_Pert : Parameter_Vector (Beta'Range);
      R1 : Residual_Vector (R0'Range);
      H  : Real;
      Col : Param_Index;
   begin
      for Pj in 1 .. N loop
         Col := Beta'First + (Pj - 1);
         Beta_Pert := Beta;
         H := Eps * (1.0 + abs (Beta (Col)));
         Beta_Pert (Col) := Beta (Col) + H;
         R1 := Model (Beta_Pert);
         for Ri in 1 .. M loop
            J (Ri, Pj) :=
              (R1 (R1'First + (Ri - 1)) - R0 (R0'First + (Ri - 1))) / H;
         end loop;
      end loop;
      return J;
   end Finite_Difference_Jacobian;

   function Damped_Normal_Matrix
     (A : Square_Matrix; Lambda : Non_Negative) return Square_Matrix
   is
      N : constant Param_Count := A'Length (1);
      D : Square_Matrix (1 .. N, 1 .. N);
      Diag : Real;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            D (I, J) :=
              A (A'First (1) + (I - 1), A'First (2) + (J - 1));
         end loop;
      end loop;
      for I in 1 .. N loop
         Diag := D (I, I);
         if abs (Diag) < 1.0E-12 then
            Diag := 1.0;
         end if;
         D (I, I) := D (I, I) + Lambda * Diag;
      end loop;
      return D;
   end Damped_Normal_Matrix;

   function Adjust_Lambda
     (Lambda      : Positive_Real;
      Improved    : Boolean;
      Lambda_Up   : Positive_Real;
      Lambda_Down : Positive_Real) return Positive_Real
   is
      L : Real;
   begin
      if Improved then
         L := Lambda / Lambda_Down;
      else
         L := Lambda * Lambda_Up;
      end if;
      if L < 1.0E-16 then
         L := 1.0E-16;
      elsif L > 1.0E16 then
         L := 1.0E16;
      end if;
      return Positive_Real (L);
   end Adjust_Lambda;

   ---------------------------------------------------------------------------
   -- Built-in models
   ---------------------------------------------------------------------------

   function Linear_Residuals (Beta : Parameter_Vector) return Residual_Vector is
      R : Residual_Vector (1 .. Sample_N);
      A, B : Real;
   begin
      if Beta'Length < 2 then
         raise Invalid_Argument;
      end if;
      A := Beta (Beta'First);
      B := Beta (Beta'First + 1);
      for I in 1 .. Sample_N loop
         R (I) := Linear_Y (I) - (A + B * Sample_X (I));
      end loop;
      return R;
   end Linear_Residuals;

   function Linear_Jacobian (Beta : Parameter_Vector) return Jacobian is
      J : Jacobian (1 .. Sample_N, 1 .. 2);
   begin
      if Beta'Length < 2 then
         raise Invalid_Argument;
      end if;
      for I in 1 .. Sample_N loop
         --  r = y − (a + b x)  ⇒  ∂r/∂a = −1,  ∂r/∂b = −x
         J (I, 1) := -1.0;
         J (I, 2) := -Sample_X (I);
      end loop;
      return J;
   end Linear_Jacobian;

   function Quadratic_Residuals
     (Beta : Parameter_Vector) return Residual_Vector
   is
      R : Residual_Vector (1 .. Sample_N);
      A, B, C : Real;
      X : Real;
   begin
      if Beta'Length < 3 then
         raise Invalid_Argument;
      end if;
      A := Beta (Beta'First);
      B := Beta (Beta'First + 1);
      C := Beta (Beta'First + 2);
      for I in 1 .. Sample_N loop
         X := Sample_X (I);
         R (I) := Quadratic_Y (I) - (A + B * X + C * X * X);
      end loop;
      return R;
   end Quadratic_Residuals;

   function Quadratic_Jacobian (Beta : Parameter_Vector) return Jacobian is
      J : Jacobian (1 .. Sample_N, 1 .. 3);
      X : Real;
   begin
      if Beta'Length < 3 then
         raise Invalid_Argument;
      end if;
      for I in 1 .. Sample_N loop
         X := Sample_X (I);
         J (I, 1) := -1.0;
         J (I, 2) := -X;
         J (I, 3) := -X * X;
      end loop;
      return J;
   end Quadratic_Jacobian;

   function Exp_Decay_Residuals
     (Beta : Parameter_Vector) return Residual_Vector
   is
      R : Residual_Vector (1 .. Sample_N);
      A, B : Real;
   begin
      if Beta'Length < 2 then
         raise Invalid_Argument;
      end if;
      A := Beta (Beta'First);
      B := Beta (Beta'First + 1);
      for I in 1 .. Sample_N loop
         R (I) := Exp_Y (I) - A * Exp (-B * Sample_X (I));
      end loop;
      return R;
   end Exp_Decay_Residuals;

   function Exp_Decay_Jacobian (Beta : Parameter_Vector) return Jacobian is
      J : Jacobian (1 .. Sample_N, 1 .. 2);
      A, B, E : Real;
   begin
      if Beta'Length < 2 then
         raise Invalid_Argument;
      end if;
      A := Beta (Beta'First);
      B := Beta (Beta'First + 1);
      for I in 1 .. Sample_N loop
         E := Exp (-B * Sample_X (I));
         --  r = y − a e^(−b x)  ⇒  ∂r/∂a = −e^(−b x),
         --  ∂r/∂b = a x e^(−b x)
         J (I, 1) := -E;
         J (I, 2) := A * Sample_X (I) * E;
      end loop;
      return J;
   end Exp_Decay_Jacobian;

   function Rosenbrock_Residuals
     (Beta : Parameter_Vector) return Residual_Vector
   is
      R : Residual_Vector (1 .. 2);
      X, Y : Real;
   begin
      if Beta'Length < 2 then
         raise Invalid_Argument;
      end if;
      X := Beta (Beta'First);
      Y := Beta (Beta'First + 1);
      R (1) := 1.0 - X;
      R (2) := 10.0 * (Y - X * X);
      return R;
   end Rosenbrock_Residuals;

   function Rosenbrock_Jacobian (Beta : Parameter_Vector) return Jacobian is
      J : Jacobian (1 .. 2, 1 .. 2);
      X : Real;
   begin
      if Beta'Length < 2 then
         raise Invalid_Argument;
      end if;
      X := Beta (Beta'First);
      --  r1 = 1−x, r2 = 10(y−x²)
      J (1, 1) := -1.0;
      J (1, 2) := 0.0;
      J (2, 1) := -20.0 * X;
      J (2, 2) := 10.0;
      return J;
   end Rosenbrock_Jacobian;

   function Sphere_Residuals (Beta : Parameter_Vector) return Residual_Vector is
      R : Residual_Vector (1 .. Beta'Length);
      K : Residual_Index := 1;
   begin
      for I in Beta'Range loop
         R (K) := Beta (I);
         if K < R'Last then
            K := K + 1;
         end if;
      end loop;
      return R;
   end Sphere_Residuals;

   ---------------------------------------------------------------------------
   -- Driver
   ---------------------------------------------------------------------------

   function Fit
     (Model : Model_Fn;
      Beta0 : Parameter_Vector;
      Jac   : Jacobian_Fn := null;
      Cfg   : Config := (others => <>)) return Result
   is
      N : constant Param_Count := Beta0'Length;
      Beta : Parameter_Vector (1 .. N);
      R : Residual_Vector (1 .. Max_Residuals);
      M : Residual_Count;
      J_Mat : Jacobian (1 .. Max_Residuals, 1 .. N);
      A : Square_Matrix (1 .. N, 1 .. N);
      Damped : Square_Matrix (1 .. N, 1 .. N);
      Grad : Parameter_Vector (1 .. N);
      Step_Vec : Parameter_Vector (1 .. N);
      Trial : Parameter_Vector (1 .. N);
      R_Trial : Residual_Vector (1 .. Max_Residuals);
      Lambda : Positive_Real := Cfg.Lambda_Init;
      Cur_Cost : Non_Negative;
      New_Cost : Non_Negative;
      Rel_Imp  : Real;
      Res : Result;
      Improved : Boolean;
      Step_Norm : Non_Negative;
      Accepted_Once : Boolean := False;
      Solved : Boolean;
      Done : Boolean := False;
   begin
      for I in 1 .. N loop
         Beta (I) := Beta0 (Beta0'First + (I - 1));
      end loop;

      declare
         R0 : constant Residual_Vector := Model (Beta);
      begin
         if R0'Length < 1 or else R0'Length > Max_Residuals then
            raise Invalid_Argument;
         end if;
         M := R0'Length;
         for I in 1 .. M loop
            R (I) := R0 (R0'First + (I - 1));
         end loop;
      end;

      Cur_Cost := Cost (R (1 .. M));
      Res.N_Params := N;
      Res.N_Residuals := M;
      Res.Final_Cost := Cur_Cost;
      Res.Final_Lambda := Non_Negative (Lambda);

      for Iter in 1 .. Cfg.Max_Iterations loop
         exit when Done;
         Res.Iterations := Iter;

         if Jac /= null then
            declare
               Ja : constant Jacobian := Jac (Beta);
            begin
               if Ja'Length (1) /= M or else Ja'Length (2) /= N then
                  raise Invalid_Argument;
               end if;
               for Ri in 1 .. M loop
                  for Pj in 1 .. N loop
                     J_Mat (Ri, Pj) :=
                       Ja (Ja'First (1) + (Ri - 1),
                           Ja'First (2) + (Pj - 1));
                  end loop;
               end loop;
            end;
         else
            declare
               Ja : constant Jacobian :=
                 Finite_Difference_Jacobian (Model, Beta, Cfg.Fd_Eps);
            begin
               for Ri in 1 .. M loop
                  for Pj in 1 .. N loop
                     J_Mat (Ri, Pj) := Ja (Ri, Pj);
                  end loop;
               end loop;
            end;
         end if;

         declare
            J_Work : Jacobian (1 .. M, 1 .. N);
         begin
            for Ri in 1 .. M loop
               for Pj in 1 .. N loop
                  J_Work (Ri, Pj) := J_Mat (Ri, Pj);
               end loop;
            end loop;
            A := JTJ (J_Work);
            Grad := JTr (J_Work, R (1 .. M));
         end;

         Improved := False;
         for Attempt in 1 .. 20 loop
            Damped := Damped_Normal_Matrix (A, Non_Negative (Lambda));
            Solved := True;
            begin
               Step_Vec := Solve_SPD (Damped, Scale (-1.0, Grad));
            exception
               when Singular_System =>
                  Solved := False;
                  Lambda := Adjust_Lambda
                    (Lambda, False, Cfg.Lambda_Up, Cfg.Lambda_Down);
            end;

            if Solved then
               Trial := Add (Beta, Step_Vec);
               declare
                  Rt : constant Residual_Vector := Model (Trial);
               begin
                  for I in 1 .. M loop
                     R_Trial (I) := Rt (Rt'First + (I - 1));
                  end loop;
               end;
               New_Cost := Cost (R_Trial (1 .. M));

               if New_Cost < Cur_Cost then
                  Improved := True;
                  Accepted_Once := True;
                  Step_Norm := Norm2 (Step_Vec);
                  Rel_Imp :=
                    (Real (Cur_Cost) - Real (New_Cost))
                    / (1.0 + Real (Cur_Cost));

                  Beta := Trial;
                  for I in 1 .. M loop
                     R (I) := R_Trial (I);
                  end loop;
                  Cur_Cost := New_Cost;
                  Lambda := Adjust_Lambda
                    (Lambda, True, Cfg.Lambda_Up, Cfg.Lambda_Down);

                  if Step_Norm <= Cfg.Step_Tol
                    or else Rel_Imp <= Real (Cfg.Cost_Tol)
                  then
                     Res.Success := True;
                     Done := True;
                  end if;
                  exit;
               else
                  Lambda := Adjust_Lambda
                    (Lambda, False, Cfg.Lambda_Up, Cfg.Lambda_Down);
               end if;
            end if;
         end loop;

         if not Improved then
            if Accepted_Once and then Cur_Cost <= Cfg.Cost_Tol then
               Res.Success := True;
            end if;
            exit;
         end if;
      end loop;

      for I in 1 .. N loop
         Res.Final_Params (I) := Beta (I);
      end loop;
      Res.Final_Cost := Cur_Cost;
      Res.Final_Lambda := Non_Negative (Lambda);
      if not Res.Success and then Cur_Cost <= Cfg.Cost_Tol then
         Res.Success := True;
      end if;
      return Res;
   end Fit;

end Levenberg_Marquardt;
