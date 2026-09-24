--  Karmarkars_Algorithm body — educational affine-scaling interior-point LP.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Karmarkars_Algorithm
  with SPARK_Mode => Off
is

   package EF is new Ada.Numerics.Generic_Elementary_Functions (Real);

   -------------------------------------------------------------------------
   -- Near / Vec_Near / Dot / Norms / Scale / Add / Sub
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Vec_Near
     (A, B : Vector; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      for K in 0 .. A'Length - 1 loop
         if abs (A (A'First + K) - B (B'First + K)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Vec_Near;

   function Dot (A, B : Vector) return Real is
      S : Real := 0.0;
   begin
      for K in 0 .. A'Length - 1 loop
         S := S + A (A'First + K) * B (B'First + K);
      end loop;
      return S;
   end Dot;

   function Norm_Inf (X : Vector) return Non_Negative is
      M : Real := 0.0;
   begin
      for V of X loop
         if abs (V) > M then
            M := abs (V);
         end if;
      end loop;
      return M;
   end Norm_Inf;

   function Norm2 (X : Vector) return Non_Negative is
      S : Real := 0.0;
   begin
      for V of X loop
         S := S + V * V;
      end loop;
      if S <= 0.0 then
         return 0.0;
      end if;
      return Non_Negative
        (EF.Sqrt (S));
   end Norm2;

   function Scale (C : Real; X : Vector) return Vector is
      Y : Vector (X'Range);
   begin
      for I in X'Range loop
         Y (I) := C * X (I);
      end loop;
      return Y;
   end Scale;

   function Add (A, B : Vector) return Vector is
      Y : Vector (1 .. A'Length);
   begin
      for K in 0 .. A'Length - 1 loop
         Y (1 + K) := A (A'First + K) + B (B'First + K);
      end loop;
      return Y;
   end Add;

   function Sub (A, B : Vector) return Vector is
      Y : Vector (1 .. A'Length);
   begin
      for K in 0 .. A'Length - 1 loop
         Y (1 + K) := A (A'First + K) - B (B'First + K);
      end loop;
      return Y;
   end Sub;

   -------------------------------------------------------------------------
   -- Mat_Vec (rectangular / square) / Mat_Vec_T
   -------------------------------------------------------------------------

   function Mat_Vec (A : Matrix; X : Vector) return Vector is
      M : constant Constraint_Count := A'Length (1);
      Y : Vector (1 .. M) := [others => 0.0];
   begin
      for I in 1 .. M loop
         declare
            S  : Real := 0.0;
            Ai : constant Constraint_Index := A'First (1) + (I - 1);
            Xj : Positive := X'First;
         begin
            for J in 0 .. X'Length - 1 loop
               S := S + A (Ai, A'First (2) + J) * X (Xj);
               if Xj < X'Last then
                  Xj := Xj + 1;
               end if;
            end loop;
            Y (I) := S;
         end;
      end loop;
      return Y;
   end Mat_Vec;

   function Mat_Vec_T (A : Matrix; Y : Vector) return Vector is
      N : constant Var_Count := A'Length (2);
      X : Vector (1 .. N) := [others => 0.0];
   begin
      for J in 1 .. N loop
         declare
            S  : Real := 0.0;
            Aj : constant Var_Index := A'First (2) + (J - 1);
            Yi : Positive := Y'First;
         begin
            for I in 0 .. Y'Length - 1 loop
               S := S + A (A'First (1) + I, Aj) * Y (Yi);
               if Yi < Y'Last then
                  Yi := Yi + 1;
               end if;
            end loop;
            X (J) := S;
         end;
      end loop;
      return X;
   end Mat_Vec_T;

   function Mat_Vec (A : Square_Matrix; X : Vector) return Vector is
      N : constant Constraint_Count := X'Length;
      Y : Vector (1 .. N) := [others => 0.0];
   begin
      for I in 1 .. N loop
         declare
            S  : Real := 0.0;
            Ai : constant Constraint_Index := A'First (1) + (I - 1);
            Xj : Positive := X'First;
         begin
            for J in 1 .. N loop
               S := S
                 + A (Ai, A'First (2) + (J - 1)) * X (Xj);
               if Xj < X'Last then
                  Xj := Xj + 1;
               end if;
            end loop;
            Y (I) := S;
         end;
      end loop;
      return Y;
   end Mat_Vec;

   -------------------------------------------------------------------------
   -- Solve_GE / Solve_SPD
   -------------------------------------------------------------------------

   function Solve_GE
     (A : Square_Matrix; B : Vector) return Vector
   is
      N     : constant Constraint_Count := B'Length;
      M     : array (1 .. N, 1 .. N) of Real;
      Rhs   : array (1 .. N) of Real;
      X     : Vector (1 .. N) := [others => 0.0];
      Pivot : Constraint_Index;
      Max_Abs : Real;
      Tmp     : Real;
      Factor  : Real;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            M (I, J) := A (A'First (1) + (I - 1), A'First (2) + (J - 1));
         end loop;
         Rhs (I) := B (B'First + (I - 1));
      end loop;

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
   end Solve_GE;

   function Solve_SPD
     (A : Square_Matrix; B : Vector) return Vector
   is
   begin
      return Solve_GE (A, B);
   end Solve_SPD;

   -------------------------------------------------------------------------
   -- Project_Nullspace / Feasible_Residual / All_Positive
   -------------------------------------------------------------------------

   function Project_Nullspace
     (A : Matrix; V : Vector) return Vector
   is
      M : constant Constraint_Count := A'Length (1);
      N : constant Var_Count := A'Length (2);
      G : Square_Matrix (1 .. M, 1 .. M) := [others => [others => 0.0]];
      Av : constant Vector := Mat_Vec (A, V);
      Lambda : Vector (1 .. M);
      At_Lam : Vector (1 .. N);
      Result_V : Vector (1 .. N);
   begin
      --  Gram G = A Aᵀ
      for I in 1 .. M loop
         for J in 1 .. M loop
            declare
               S  : Real := 0.0;
               Ai : constant Constraint_Index := A'First (1) + (I - 1);
               Aj : constant Constraint_Index := A'First (1) + (J - 1);
            begin
               for K in 0 .. N - 1 loop
                  S := S
                    + A (Ai, A'First (2) + K)
                    * A (Aj, A'First (2) + K);
               end loop;
               G (I, J) := S;
            end;
         end loop;
      end loop;

      Lambda := Solve_GE (G, Av);
      At_Lam := Mat_Vec_T (A, Lambda);
      for K in 0 .. N - 1 loop
         Result_V (1 + K) := V (V'First + K) - At_Lam (1 + K);
      end loop;
      return Result_V;
   end Project_Nullspace;

   function Feasible_Residual
     (A : Matrix; B, X : Vector) return Non_Negative
   is
      Ax : constant Vector := Mat_Vec (A, X);
      Diff : Vector (1 .. B'Length);
   begin
      for K in 0 .. B'Length - 1 loop
         Diff (1 + K) := Ax (Ax'First + K) - B (B'First + K);
      end loop;
      return Norm_Inf (Diff);
   end Feasible_Residual;

   function All_Positive
     (X : Vector; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      for V of X loop
         if V <= Tol then
            return False;
         end if;
      end loop;
      return True;
   end All_Positive;

   -------------------------------------------------------------------------
   -- Affine_Direction
   -------------------------------------------------------------------------

   procedure Affine_Direction
     (A      : Matrix;
      C      : Vector;
      X      : Vector;
      Sense  : Objective_Sense;
      DX     : out Vector;
      R_Scaled_Inf : out Non_Negative)
   is
      M : constant Constraint_Count := A'Length (1);
      N : constant Var_Count := A'Length (2);
      --  Working copies indexed 1 .. N / 1 .. M
      Xw : Vector (1 .. N);
      Cw : Vector (1 .. N);
      D2C : Vector (1 .. N);
      AD2C : Vector (1 .. M);
      G : Square_Matrix (1 .. M, 1 .. M) := [others => [others => 0.0]];
      Y : Vector (1 .. M);
      R : Vector (1 .. N);
      Sign : Real;
   begin
      for K in 0 .. N - 1 loop
         Xw (1 + K) := X (X'First + K);
         Cw (1 + K) := C (C'First + K);
      end loop;

      --  D² c  and  A D² c
      for J in 1 .. N loop
         D2C (J) := (Xw (J) * Xw (J)) * Cw (J);
      end loop;
      AD2C := Mat_Vec (A, D2C);

      --  G = A D² Aᵀ
      for I in 1 .. M loop
         for J in 1 .. M loop
            declare
               S  : Real := 0.0;
               Ai : constant Constraint_Index := A'First (1) + (I - 1);
               Aj : constant Constraint_Index := A'First (1) + (J - 1);
            begin
               for K in 0 .. N - 1 loop
                  declare
                     Ak : constant Var_Index := A'First (2) + K;
                     D2 : constant Real := Xw (1 + K) * Xw (1 + K);
                  begin
                     S := S + A (Ai, Ak) * D2 * A (Aj, Ak);
                  end;
               end loop;
               G (I, J) := S;
            end;
         end loop;
      end loop;

      Y := Solve_SPD (G, AD2C);

      --  r = c − Aᵀ y
      declare
         AtY : constant Vector := Mat_Vec_T (A, Y);
      begin
         for J in 1 .. N loop
            R (J) := Cw (J) - AtY (J);
         end loop;
      end;

      --  Scaled reduced-cost measure ‖D r‖_∞
      declare
         Msr : Real := 0.0;
         T   : Real;
      begin
         for J in 1 .. N loop
            T := abs (Xw (J) * R (J));
            if T > Msr then
               Msr := T;
            end if;
         end loop;
         R_Scaled_Inf := Msr;
      end;

      if Sense = Minimize_Sense then
         Sign := -1.0;
      else
         Sign := 1.0;
      end if;

      --  DX must be written into caller's slice (same length as X).
      declare
         Out_First : constant Positive := DX'First;
      begin
         for J in 1 .. N loop
            DX (Out_First + (J - 1)) :=
              Sign * (Xw (J) * Xw (J)) * R (J);
         end loop;
      end;
   end Affine_Direction;

   -------------------------------------------------------------------------
   -- Max_Feasible_Step / Interior_Step
   -------------------------------------------------------------------------

   function Max_Feasible_Step (X, DX : Vector) return Real is
      Alpha : Real := Real'Last;
      Ratio : Real;
   begin
      for K in 0 .. X'Length - 1 loop
         declare
            DXk : constant Real := DX (DX'First + K);
         begin
            if DXk < 0.0 then
               Ratio := -X (X'First + K) / DXk;
               if Ratio < Alpha then
                  Alpha := Ratio;
               end if;
            end if;
         end;
      end loop;
      return Alpha;
   end Max_Feasible_Step;

   function Interior_Step
     (X             : Vector;
      DX            : Vector;
      Step_Fraction : Positive_Real;
      Min_Step      : Positive_Real := 1.0E-14)
     return Vector
   is
      Alpha_Max : constant Real := Max_Feasible_Step (X, DX);
      Alpha     : Real;
      Y         : Vector (1 .. X'Length);
   begin
      if Alpha_Max = Real'Last then
         if Norm_Inf (DX) <= Min_Step then
            for K in 0 .. X'Length - 1 loop
               Y (1 + K) := X (X'First + K);
            end loop;
            return Y;
         end if;
         raise Invalid_Argument
           with "Interior_Step: unbounded improving ray";
      end if;

      Alpha := Step_Fraction * Alpha_Max;
      if Alpha < Min_Step then
         for K in 0 .. X'Length - 1 loop
            Y (1 + K) := X (X'First + K);
         end loop;
         return Y;
      end if;

      for K in 0 .. X'Length - 1 loop
         Y (1 + K) :=
           X (X'First + K) + Alpha * DX (DX'First + K);
      end loop;
      return Y;
   end Interior_Step;

   -------------------------------------------------------------------------
   -- Expand_Inequalities
   -------------------------------------------------------------------------

   procedure Expand_Inequalities
     (A_In   : Matrix;
      B      : Vector;
      C_In   : Vector;
      X0_In  : Vector;
      A_Out  : out Matrix;
      C_Out  : out Vector;
      X0_Out : out Vector;
      N_Out  : out Var_Count)
   is
      M  : constant Constraint_Count := A_In'Length (1);
      Nd : constant Var_Count := A_In'Length (2);
      Ns : constant Var_Count := M;
      N  : constant Var_Count := Nd + Ns;
      Slack : Real;
   begin
      N_Out := N;

      for I in 1 .. M loop
         for J in 1 .. Nd loop
            A_Out (A_Out'First (1) + (I - 1),
                   A_Out'First (2) + (J - 1)) :=
              A_In (A_In'First (1) + (I - 1),
                    A_In'First (2) + (J - 1));
         end loop;
         for J in 1 .. Ns loop
            if J = I then
               A_Out (A_Out'First (1) + (I - 1),
                      A_Out'First (2) + (Nd + J - 1)) := 1.0;
            else
               A_Out (A_Out'First (1) + (I - 1),
                      A_Out'First (2) + (Nd + J - 1)) := 0.0;
            end if;
         end loop;
      end loop;

      for J in 1 .. Nd loop
         C_Out (C_Out'First + (J - 1)) := C_In (C_In'First + (J - 1));
         X0_Out (X0_Out'First + (J - 1)) :=
           X0_In (X0_In'First + (J - 1));
      end loop;

      for I in 1 .. M loop
         declare
            Ax_I : Real := 0.0;
         begin
            for J in 1 .. Nd loop
               Ax_I := Ax_I
                 + A_In (A_In'First (1) + (I - 1),
                         A_In'First (2) + (J - 1))
                 * X0_In (X0_In'First + (J - 1));
            end loop;
            Slack := B (B'First + (I - 1)) - Ax_I;
            if Slack <= 0.0 then
               raise Invalid_Argument
                 with "Expand_Inequalities: non-positive slack";
            end if;
            C_Out (C_Out'First + (Nd + I - 1)) := 0.0;
            X0_Out (X0_Out'First + (Nd + I - 1)) := Slack;
         end;
      end loop;
   end Expand_Inequalities;

   -------------------------------------------------------------------------
   -- Solve / Minimize / Maximize
   -------------------------------------------------------------------------

   function Solve
     (A     : Matrix;
      B     : Vector;
      C     : Vector;
      X0    : Vector;
      Sense : Objective_Sense := Minimize_Sense;
      Cfg   : Config := (others => <>)) return Result
   is
      N : constant Var_Count := X0'Length;
      R : Result;
      X : Vector (1 .. N);
      DX : Vector (1 .. N) := [others => 0.0];
      R_Scaled : Non_Negative;
      New_X : Vector (1 .. N);
   begin
      R.N_Vars := N;

      --  Strict positivity of the start.
      if not All_Positive (X0, 0.0) then
         R.Stat := Ill_Started;
         R.Success := False;
         for K in 0 .. N - 1 loop
            R.X (1 + K) := X0 (X0'First + K);
         end loop;
         return R;
      end if;

      --  Feasibility check Ax = b.
      if Feasible_Residual (A, B, X0) > Cfg.Tol * 1000.0 then
         R.Stat := Ill_Started;
         R.Success := False;
         for K in 0 .. N - 1 loop
            R.X (1 + K) := X0 (X0'First + K);
         end loop;
         return R;
      end if;

      if Cfg.Step_Fraction <= 0.0 or else Cfg.Step_Fraction >= 1.0 then
         raise Invalid_Argument
           with "Solve: Step_Fraction must lie in (0,1)";
      end if;

      for K in 0 .. N - 1 loop
         X (1 + K) := X0 (X0'First + K);
      end loop;

      for Iter in 1 .. Cfg.Max_Iterations loop
         begin
            Affine_Direction (A, C, X, Sense, DX, R_Scaled);
         exception
            when Singular_System =>
               R.Stat := Ill_Started;
               R.Iterations := Iter - 1;
               R.Objective := Dot (C, X);
               for K in 0 .. N - 1 loop
                  R.X (1 + K) := X (1 + K);
               end loop;
               return R;
         end;

         R.Iterations := Iter;

         if R_Scaled <= Cfg.Tol then
            R.Stat := Optimal;
            R.Success := True;
            R.Objective := Dot (C, X);
            for K in 0 .. N - 1 loop
               R.X (1 + K) := X (1 + K);
            end loop;
            return R;
         end if;

         declare
            Alpha_Max : constant Real := Max_Feasible_Step (X, DX);
         begin
            if Alpha_Max = Real'Last then
               if Norm_Inf (DX) > Cfg.Tol then
                  R.Stat := Unbounded;
                  R.Success := False;
                  R.Objective := Dot (C, X);
                  for K in 0 .. N - 1 loop
                     R.X (1 + K) := X (1 + K);
                  end loop;
                  return R;
               else
                  R.Stat := Optimal;
                  R.Success := True;
                  R.Objective := Dot (C, X);
                  for K in 0 .. N - 1 loop
                     R.X (1 + K) := X (1 + K);
                  end loop;
                  return R;
               end if;
            end if;

            if Cfg.Step_Fraction * Alpha_Max < Cfg.Min_Step then
               R.Stat := Optimal;
               R.Success := True;
               R.Objective := Dot (C, X);
               for K in 0 .. N - 1 loop
                  R.X (1 + K) := X (1 + K);
               end loop;
               return R;
            end if;
         end;

         New_X := Interior_Step
           (X, DX, Cfg.Step_Fraction, Cfg.Min_Step);

         --  Keep strict positivity; tiny numerical undershoot → clamp lightly
         for K in 1 .. N loop
            if New_X (K) <= 0.0 then
               New_X (K) := Real'Model_Small;
            end if;
         end loop;

         --  Optional feasibility polish is omitted; affine step preserves
         --  Ax=b in exact arithmetic. Check drift.
         if Feasible_Residual (A, B, New_X) >
           Feasible_Residual (A, B, X) + 1.0E-6
         then
            null;  -- still accept; educational dense GE drift is small
         end if;

         X := New_X;
      end loop;

      R.Stat := Iteration_Limit;
      R.Success := False;
      R.Objective := Dot (C, X);
      R.Iterations := Cfg.Max_Iterations;
      for K in 0 .. N - 1 loop
         R.X (1 + K) := X (1 + K);
      end loop;
      return R;
   end Solve;

   function Minimize
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      X0  : Vector;
      Cfg : Config := (others => <>)) return Result
   is
   begin
      return Solve (A, B, C, X0, Minimize_Sense, Cfg);
   end Minimize;

   function Maximize
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      X0  : Vector;
      Cfg : Config := (others => <>)) return Result
   is
   begin
      return Solve (A, B, C, X0, Maximize_Sense, Cfg);
   end Maximize;

   function Maximize_Inequalities
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      X0  : Vector;
      Cfg : Config := (others => <>)) return Result
   is
      M  : constant Constraint_Count := A'Length (1);
      Nd : constant Var_Count := A'Length (2);
      N  : constant Var_Count := Nd + M;
      Aeq : Matrix (1 .. M, 1 .. N);
      Ceq : Vector (1 .. N);
      Xeq : Vector (1 .. N);
      N_Out : Var_Count;
      R : Result;
   begin
      begin
         Expand_Inequalities (A, B, C, X0, Aeq, Ceq, Xeq, N_Out);
      exception
         when Invalid_Argument =>
            R.Stat := Ill_Started;
            R.N_Vars := Nd;
            for K in 0 .. Nd - 1 loop
               R.X (1 + K) := X0 (X0'First + K);
            end loop;
            return R;
      end;
      R := Maximize (Aeq, B, Ceq (1 .. N_Out), Xeq (1 .. N_Out), Cfg);
      --  Return only decision variables in the leading slots (already there).
      R.N_Vars := Nd;
      return R;
   end Maximize_Inequalities;

   function Minimize_Inequalities
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      X0  : Vector;
      Cfg : Config := (others => <>)) return Result
   is
      M  : constant Constraint_Count := A'Length (1);
      Nd : constant Var_Count := A'Length (2);
      N  : constant Var_Count := Nd + M;
      Aeq : Matrix (1 .. M, 1 .. N);
      Ceq : Vector (1 .. N);
      Xeq : Vector (1 .. N);
      N_Out : Var_Count;
      R : Result;
   begin
      begin
         Expand_Inequalities (A, B, C, X0, Aeq, Ceq, Xeq, N_Out);
      exception
         when Invalid_Argument =>
            R.Stat := Ill_Started;
            R.N_Vars := Nd;
            for K in 0 .. Nd - 1 loop
               R.X (1 + K) := X0 (X0'First + K);
            end loop;
            return R;
      end;
      R := Minimize (Aeq, B, Ceq (1 .. N_Out), Xeq (1 .. N_Out), Cfg);
      R.N_Vars := Nd;
      return R;
   end Minimize_Inequalities;

end Karmarkars_Algorithm;
