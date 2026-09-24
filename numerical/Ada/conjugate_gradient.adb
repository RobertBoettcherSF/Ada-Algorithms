--  Conjugate_Gradient body — Hestenes–Stiefel CG + Fletcher–Reeves sketch.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Conjugate_Gradient is

   package Math renames Ada.Numerics.Elementary_Functions;

   -------------------------------------------------------------------------
   -- Numeric helpers
   -------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Vec_Near
     (A, B : Vector; Tol : Float := Epsilon_Tol) return Boolean
   is
   begin
      for I in A'Range loop
         if abs (A (I) - B (I - A'First + B'First)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Vec_Near;

   function Dot (U, V : Vector) return Float is
      S : Float := 0.0;
      J : Positive := V'First;
   begin
      for I in U'Range loop
         S := S + U (I) * V (J);
         if J < V'Last then
            J := J + 1;
         end if;
      end loop;
      return S;
   end Dot;

   function Norm2 (V : Vector) return Float is
   begin
      return Math.Sqrt (Dot (V, V));
   end Norm2;

   function Scale (V : Vector; S : Float) return Vector is
      R : Vector (V'Range);
   begin
      for I in V'Range loop
         R (I) := S * V (I);
      end loop;
      return R;
   end Scale;

   function Add (U, V : Vector) return Vector is
      R : Vector (U'Range);
      J : Positive := V'First;
   begin
      for I in U'Range loop
         R (I) := U (I) + V (J);
         if J < V'Last then
            J := J + 1;
         end if;
      end loop;
      return R;
   end Add;

   function Sub (U, V : Vector) return Vector is
      R : Vector (U'Range);
      J : Positive := V'First;
   begin
      for I in U'Range loop
         R (I) := U (I) - V (J);
         if J < V'Last then
            J := J + 1;
         end if;
      end loop;
      return R;
   end Sub;

   function Mat_Vec (A : Matrix; X : Vector) return Vector is
      N : constant Positive := X'Length;
      Y : Vector (1 .. N) := [others => 0.0];
      Col : Positive;
   begin
      for I in 1 .. N loop
         declare
            Row : constant Positive := A'First (1) + I - 1;
            Acc : Float := 0.0;
         begin
            Col := A'First (2);
            for J in X'Range loop
               Acc := Acc + A (Row, Col) * X (J);
               if Col < A'Last (2) then
                  Col := Col + 1;
               end if;
            end loop;
            Y (I) := Acc;
         end;
      end loop;
      return Y;
   end Mat_Vec;

   function Is_Symmetric
     (A : Matrix; Tol : Float := 1.0E-6) return Boolean
   is
      N : constant Natural := A'Length (1);
   begin
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            declare
               RI : constant Positive := A'First (1) + I;
               RJ : constant Positive := A'First (1) + J;
               CI : constant Positive := A'First (2) + I;
               CJ : constant Positive := A'First (2) + J;
            begin
               if abs (A (RI, CJ) - A (RJ, CI)) > Tol then
                  return False;
               end if;
            end;
         end loop;
      end loop;
      return True;
   end Is_Symmetric;

   function Is_Diagonally_Dominant (A : Matrix) return Boolean is
      N : constant Natural := A'Length (1);
   begin
      for I in 0 .. N - 1 loop
         declare
            RI  : constant Positive := A'First (1) + I;
            Diag : constant Float := abs (A (RI, A'First (2) + I));
            Off  : Float := 0.0;
         begin
            for J in 0 .. N - 1 loop
               if J /= I then
                  Off := Off + abs (A (RI, A'First (2) + J));
               end if;
            end loop;
            if Diag < Off then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Diagonally_Dominant;

   function Residual (A : Matrix; X, B : Vector) return Vector is
   begin
      return Sub (B, Mat_Vec (A, X));
   end Residual;

   function Residual_Norm (A : Matrix; X, B : Vector) return Float is
   begin
      return Norm2 (Residual (A, X, B));
   end Residual_Norm;

   -------------------------------------------------------------------------
   -- Example generators
   -------------------------------------------------------------------------

   function Make_SPD_Example
     (Kind : Example_Kind; N : Dimension) return Matrix
   is
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      case Kind is
         when Hilbert_Tiny =>
            for I in 1 .. N loop
               for J in 1 .. N loop
                  A (I, J) := 1.0 / Float (I + J - 1);
               end loop;
            end loop;

         when Diagonal_Plus_Ones =>
            for I in 1 .. N loop
               for J in 1 .. N loop
                  A (I, J) := 1.0;
               end loop;
               A (I, I) := Float (N + 1);
            end loop;

         when Poisson_1D =>
            for I in 1 .. N loop
               A (I, I) := 2.0;
               if I > 1 then
                  A (I, I - 1) := -1.0;
               end if;
               if I < N then
                  A (I, I + 1) := -1.0;
               end if;
            end loop;
      end case;
      return A;
   end Make_SPD_Example;

   function Make_RHS_Ones (N : Dimension) return Vector is
      B : constant Vector (1 .. N) := [others => 1.0];
   begin
      return B;
   end Make_RHS_Ones;

   function Zero_Vector (N : Dimension) return Vector is
      Z : constant Vector (1 .. N) := [others => 0.0];
   begin
      return Z;
   end Zero_Vector;

   -------------------------------------------------------------------------
   -- Pack result into fixed Max_N slots
   -------------------------------------------------------------------------

   function Pack
     (X_Sol : Vector;
      Iters : Natural;
      Res   : Float;
      St    : Status) return Result
   is
      R : Result;
      N : constant Dimension := X_Sol'Length;
   begin
      R.N := N;
      R.Iterations := Iters;
      R.Residual := Res;
      R.Stat := St;
      R.Success := St = Converged;
      for I in 1 .. N loop
         R.X (I) := X_Sol (X_Sol'First + I - 1);
      end loop;
      return R;
   end Pack;

   function Effective_Max_Iter (N : Dimension; Params : Parameters)
     return Natural
   is
   begin
      if Params.Max_Iter = 0 then
         return Natural (N);
      else
         return Params.Max_Iter;
      end if;
   end Effective_Max_Iter;

   -------------------------------------------------------------------------
   -- Classical Hestenes–Stiefel CG
   -------------------------------------------------------------------------

   function Conjugate_Gradient
     (A      : Matrix;
      B      : Vector;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Result
   is
      N : constant Positive := B'Length;
      X : Vector (1 .. N);
      R : Vector (1 .. N);
      P : Vector (1 .. N);
      Ap : Vector (1 .. N);
      RR_Old, RR_New, Alpha, Beta, PAp : Float;
      Limit : constant Natural := Effective_Max_Iter (N, Params);
   begin
      if N > Max_N or else A'Length (1) /= N or else A'Length (2) /= N
        or else X0'Length /= N
      then
         raise Invalid_Argument;
      end if;

      --  Copy start / right-hand side into 1-based working vectors.
      for I in 1 .. N loop
         X (I) := X0 (X0'First + I - 1);
      end loop;

      R := Residual (A, X, B);
      RR_Old := Dot (R, R);

      declare
         R_Norm0 : constant Float := Math.Sqrt (RR_Old);
         --  Absolute or mild relative tolerance (educational Float).
         Abs_Tol : constant Float :=
           Float'Max (Params.Tol, Params.Tol * (1.0 + R_Norm0));
      begin
         if R_Norm0 <= Abs_Tol then
            return Pack (X, 0, R_Norm0, Converged);
         end if;

         P := R;

         for K in 1 .. Limit loop
            Ap := Mat_Vec (A, P);
            PAp := Dot (P, Ap);

            if abs (PAp) <= Epsilon_Tol * (1.0 + RR_Old) then
               return Pack (X, K - 1, Math.Sqrt (RR_Old), Breakdown);
            end if;

            Alpha := RR_Old / PAp;
            X := Add (X, Scale (P, Alpha));
            R := Sub (R, Scale (Ap, Alpha));
            RR_New := Dot (R, R);

            if Math.Sqrt (RR_New) <= Abs_Tol then
               return Pack (X, K, Math.Sqrt (RR_New), Converged);
            end if;

            if abs (RR_Old) <= Epsilon_Tol then
               return Pack (X, K, Math.Sqrt (RR_New), Breakdown);
            end if;

            Beta := RR_New / RR_Old;
            P := Add (R, Scale (P, Beta));
            RR_Old := RR_New;
         end loop;

         --  Finite-termination budget: after N SPD steps accept if residual
         --  collapsed relative to the start (Float conjugacy loss).
         declare
            R_Final : constant Float := Math.Sqrt (RR_Old);
         begin
            if R_Final <= Abs_Tol
              or else (Limit >= N and then R_Final <= 1.0E-5 * (1.0 + R_Norm0))
            then
               return Pack (X, Limit, R_Final, Converged);
            else
               return Pack (X, Limit, R_Final, Iteration_Limit);
            end if;
         end;
      end;
   end Conjugate_Gradient;

   function Solve_SPD
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
   is
      N : constant Positive := B'Length;
   begin
      if X0'Length = 0 then
         return Conjugate_Gradient (A, B, Zero_Vector (N), Params);
      elsif X0'Length /= N then
         raise Invalid_Argument;
      else
         return Conjugate_Gradient (A, B, X0, Params);
      end if;
   end Solve_SPD;

   -------------------------------------------------------------------------
   -- Nonlinear demos
   -------------------------------------------------------------------------

   function Sphere (X : Vector) return Float is
   begin
      return 0.5 * Dot (X, X);
   end Sphere;

   function Sphere_Grad (X : Vector) return Vector is
   begin
      return X;
   end Sphere_Grad;

   function Rosenbrock (X : Vector) return Float is
      U : constant Float := X (X'First);
      V : constant Float := X (X'First + 1);
   begin
      return (1.0 - U) ** 2 + 100.0 * (V - U ** 2) ** 2;
   end Rosenbrock;

   function Rosenbrock_Grad (X : Vector) return Vector is
      U : constant Float := X (X'First);
      V : constant Float := X (X'First + 1);
      G : Vector (1 .. 2);
   begin
      G (1) := -2.0 * (1.0 - U) - 400.0 * U * (V - U ** 2);
      G (2) := 200.0 * (V - U ** 2);
      return G;
   end Rosenbrock_Grad;

   function Armijo_Step
     (Objective : Objective_Fn;
      X         : Vector;
      P         : Vector;
      G_Dot_P   : Float;
      F0        : Float) return Float
   is
      Alpha : Float := 1.0;
      C1    : constant Float := 1.0E-4;
      Rho   : constant Float := 0.5;
   begin
      for Attempt in 1 .. 40 loop
         declare
            X_New : constant Vector := Add (X, Scale (P, Alpha));
            F_New : constant Float := Objective (X_New);
         begin
            if F_New <= F0 + C1 * Alpha * G_Dot_P then
               return Alpha;
            end if;
         end;
         Alpha := Rho * Alpha;
      end loop;
      return Alpha;
   end Armijo_Step;

   function Fletcher_Reeves
     (Objective : Objective_Fn;
      Grad      : Gradient_Fn;
      X0        : Vector;
      Params    : Parameters := Default_Parameters) return Result
   is
      N : constant Positive := X0'Length;
      X : Vector (1 .. N);
      G : Vector (1 .. N);
      P : Vector (1 .. N);
      G_New : Vector (1 .. N);
      GG_Old, GG_New, Alpha, Beta, G_Dot_P, F0 : Float;
      Limit : constant Natural :=
        (if Params.Max_Iter = 0 then 200 else Params.Max_Iter);
   begin
      if N > Max_N then
         raise Invalid_Argument;
      end if;

      for I in 1 .. N loop
         X (I) := X0 (X0'First + I - 1);
      end loop;

      G := Grad (X);
      GG_Old := Dot (G, G);
      if Math.Sqrt (GG_Old) <= Params.Tol then
         return Pack (X, 0, Math.Sqrt (GG_Old), Converged);
      end if;

      P := Scale (G, -1.0);

      for K in 1 .. Limit loop
         G_Dot_P := Dot (G, P);
         if G_Dot_P >= 0.0 then
            --  Not a descent direction — restart steepest descent.
            P := Scale (G, -1.0);
            G_Dot_P := Dot (G, P);
         end if;

         F0 := Objective (X);
         Alpha := Armijo_Step (Objective, X, P, G_Dot_P, F0);
         X := Add (X, Scale (P, Alpha));
         G_New := Grad (X);
         GG_New := Dot (G_New, G_New);

         if Math.Sqrt (GG_New) <= Params.Tol then
            return Pack (X, K, Math.Sqrt (GG_New), Converged);
         end if;

         if abs (GG_Old) <= Epsilon_Tol then
            return Pack (X, K, Math.Sqrt (GG_New), Breakdown);
         end if;

         Beta := GG_New / GG_Old;
         P := Add (Scale (G_New, -1.0), Scale (P, Beta));
         G := G_New;
         GG_Old := GG_New;
      end loop;

      return Pack (X, Limit, Math.Sqrt (GG_Old), Iteration_Limit);
   end Fletcher_Reeves;

end Conjugate_Gradient;
