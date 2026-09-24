--  Inverse_Iteration body — dense Float inverse power method + GEPP.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Inverse_Iteration
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Elementary_Functions;

   function Abs_F (X : Float) return Float is
   begin
      if X < 0.0 then
         return -X;
      else
         return X;
      end if;
   end Abs_F;

   -------------------------------------------------------------------------
   -- Numeric helpers
   -------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Epsilon_Tol) return Boolean is
   begin
      return Abs_F (A - B) <= Tol;
   end Near;

   function Vec_Near
     (A, B : Vector; Tol : Float := Epsilon_Tol) return Boolean
   is
   begin
      for I in A'Range loop
         if Abs_F (A (I) - B (I - A'First + B'First)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Vec_Near;

   function Dot (U, V : Vector) return Float is
      S : Float := 0.0;
   begin
      for I in U'Range loop
         S := S + U (I) * V (I - U'First + V'First);
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
   begin
      for I in U'Range loop
         R (I) := U (I) + V (I - U'First + V'First);
      end loop;
      return R;
   end Add;

   function Sub (U, V : Vector) return Vector is
      R : Vector (U'Range);
   begin
      for I in U'Range loop
         R (I) := U (I) - V (I - U'First + V'First);
      end loop;
      return R;
   end Sub;

   function Mat_Vec (A : Matrix; X : Vector) return Vector is
      Y : Vector (X'Range) := [others => 0.0];
      S : Float;
   begin
      for I in A'Range (1) loop
         S := 0.0;
         for J in A'Range (2) loop
            S := S + A (I, J) * X (X'First + (J - A'First (2)));
         end loop;
         Y (X'First + (I - A'First (1))) := S;
      end loop;
      return Y;
   end Mat_Vec;

   function Is_Square (A : Matrix) return Boolean is
   begin
      return A'Length (1) = A'Length (2);
   end Is_Square;

   function Is_Symmetric
     (A : Matrix; Tol : Float := 1.0E-6) return Boolean
   is
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            if Abs_F (A (I, J) - A (J, I)) > Tol then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Symmetric;

   function Normalize (V : Vector) return Vector is
      Nrm : constant Float := Norm2 (V);
   begin
      if Nrm <= Norm_Tol then
         raise Invalid_Argument;
      end if;
      return Scale (V, 1.0 / Nrm);
   end Normalize;

   -------------------------------------------------------------------------
   -- Rayleigh quotient / residual
   -------------------------------------------------------------------------

   function Rayleigh_Quotient (A : Matrix; X : Vector) return Float is
      Ax  : constant Vector := Mat_Vec (A, X);
      Den : constant Float := Dot (X, X);
   begin
      if Den <= Norm_Tol then
         raise Invalid_Argument;
      end if;
      return Dot (X, Ax) / Den;
   end Rayleigh_Quotient;

   function Eigen_Residual
     (A : Matrix; X : Vector; Lambda : Float) return Vector
   is
      Ax : constant Vector := Mat_Vec (A, X);
   begin
      return Sub (Ax, Scale (X, Lambda));
   end Eigen_Residual;

   function Eigen_Residual_Norm
     (A : Matrix; X : Vector; Lambda : Float) return Float
   is
   begin
      return Norm2 (Eigen_Residual (A, X, Lambda));
   end Eigen_Residual_Norm;

   -------------------------------------------------------------------------
   -- Dense GEPP for (A − μ I) y = x
   -------------------------------------------------------------------------

   procedure Swap_Rows
     (U : in out Matrix;
      B : in out Vector;
      R1, R2 : Positive;
      N : Dimension)
   is
      Tmp : Float;
   begin
      if R1 = R2 then
         return;
      end if;
      for J in 1 .. N loop
         Tmp := U (R1, J);
         U (R1, J) := U (R2, J);
         U (R2, J) := Tmp;
      end loop;
      Tmp := B (R1);
      B (R1) := B (R2);
      B (R2) := Tmp;
   end Swap_Rows;

   function Solve_Shifted
     (A : Matrix; Mu : Float; X : Vector) return Linear_Result
   is
      N : constant Dimension := X'Length;
      U : Matrix (1 .. Max_N, 1 .. Max_N) := [others => [others => 0.0]];
      B : Vector (1 .. Max_N) := [others => 0.0];
      Y : Vector (1 .. Max_N) := [others => 0.0];
      Res : Linear_Result;
      Pivot_Row : Positive;
      Best, Cand, Mult, Pivot, S : Float;
   begin
      Res.N := N;
      Res.Stat := Ok;
      Res.Success := False;

      for I in 1 .. N loop
         for J in 1 .. N loop
            U (I, J) :=
              A (A'First (1) + (I - 1), A'First (2) + (J - 1));
         end loop;
         U (I, I) := U (I, I) - Mu;
         B (I) := X (X'First + (I - 1));
      end loop;

      for K in 1 .. N loop
         Pivot_Row := K;
         Best := Abs_F (U (K, K));
         for I in K + 1 .. N loop
            Cand := Abs_F (U (I, K));
            if Cand > Best then
               Best := Cand;
               Pivot_Row := I;
            end if;
         end loop;

         if Best <= Pivot_Tol then
            Res.Stat := Singular;
            return Res;
         end if;

         Swap_Rows (U, B, K, Pivot_Row, N);

         Pivot := U (K, K);
         if Abs_F (Pivot) <= Pivot_Tol then
            Res.Stat := Zero_Pivot;
            return Res;
         end if;

         if K < N then
            for I in K + 1 .. N loop
               Mult := U (I, K) / Pivot;
               U (I, K) := 0.0;
               for J in K + 1 .. N loop
                  U (I, J) := U (I, J) - Mult * U (K, J);
               end loop;
               B (I) := B (I) - Mult * B (K);
            end loop;
         end if;
      end loop;

      for I in reverse 1 .. N loop
         S := B (I);
         for J in I + 1 .. N loop
            S := S - U (I, J) * Y (J);
         end loop;
         if Abs_F (U (I, I)) <= Pivot_Tol then
            Res.Stat := Zero_Pivot;
            return Res;
         end if;
         Y (I) := S / U (I, I);
      end loop;

      Res.Y := Y;
      Res.Stat := Ok;
      Res.Success := True;
      return Res;
   end Solve_Shifted;

   -------------------------------------------------------------------------
   -- Builders
   -------------------------------------------------------------------------

   function Make_Diagonal (Eigs : Vector) return Matrix is
      N : constant Dimension := Eigs'Length;
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         A (I, I) := Eigs (Eigs'First + (I - 1));
      end loop;
      return A;
   end Make_Diagonal;

   function Make_Poisson_1D (N : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         A (I, I) := 2.0;
         if I > 1 then
            A (I, I - 1) := -1.0;
         end if;
         if I < N then
            A (I, I + 1) := -1.0;
         end if;
      end loop;
      return A;
   end Make_Poisson_1D;

   function Make_Known_Spectrum_Symmetric
     (Eigs : Vector) return Matrix
   is
      N : constant Dimension := Eigs'Length;
      Q : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      Col : Vector (1 .. N);
      Proj : Float;
      Nrm  : Float;
      S    : Float;
   begin
      for J in 1 .. N loop
         for I in 1 .. N loop
            Q (I, J) :=
              Float ((I * 11 + J * 19 + I * J) mod 89) / 89.0
              + Float (I + J) * 0.01;
         end loop;
         Q (J, J) := Q (J, J) + Float (N);
      end loop;

      for J in 1 .. N loop
         for I in 1 .. N loop
            Col (I) := Q (I, J);
         end loop;
         for K in 1 .. J - 1 loop
            Proj := 0.0;
            for I in 1 .. N loop
               Proj := Proj + Q (I, K) * Col (I);
            end loop;
            for I in 1 .. N loop
               Col (I) := Col (I) - Proj * Q (I, K);
            end loop;
         end loop;
         Nrm := Norm2 (Col);
         if Nrm <= Norm_Tol then
            for I in 1 .. N loop
               Col (I) := 0.0;
            end loop;
            Col (J) := 1.0;
            Nrm := 1.0;
         end if;
         for I in 1 .. N loop
            Q (I, J) := Col (I) / Nrm;
         end loop;
      end loop;

      for I in 1 .. N loop
         for J in 1 .. N loop
            S := 0.0;
            for K in 1 .. N loop
               S := S
                 + Q (I, K) * Eigs (Eigs'First + (K - 1)) * Q (J, K);
            end loop;
            A (I, J) := S;
         end loop;
      end loop;
      return A;
   end Make_Known_Spectrum_Symmetric;

   function Make_Example
     (Kind : Example_Kind; N : Dimension) return Matrix
   is
      Eigs : Vector (1 .. N);
   begin
      case Kind is
         when Diagonal_Known =>
            for I in 1 .. N loop
               Eigs (I) := Float (I);
            end loop;
            return Make_Diagonal (Eigs);

         when Poisson_1D =>
            return Make_Poisson_1D (N);

         when Known_Spectrum_Symmetric =>
            for I in 1 .. N loop
               Eigs (I) := Float (I);
            end loop;
            return Make_Known_Spectrum_Symmetric (Eigs);
      end case;
   end Make_Example;

   function Make_Ones_Vector (N : Dimension) return Vector is
      V : constant Vector (1 .. N) := [others => 1.0];
   begin
      return V;
   end Make_Ones_Vector;

   function Make_Unit_Vector
     (N : Dimension; K : Dim_Index) return Vector
   is
      V : Vector (1 .. N) := [others => 0.0];
   begin
      V (K) := 1.0;
      return V;
   end Make_Unit_Vector;

   function Make_Perturbed_Basis
     (N : Dimension; K : Dim_Index; Eps : Float := 0.1) return Vector
   is
      V : Vector (1 .. N);
   begin
      for I in 1 .. N loop
         V (I) := Eps;
      end loop;
      V (K) := V (K) + 1.0;
      return Normalize (V);
   end Make_Perturbed_Basis;

   -------------------------------------------------------------------------
   -- Iteration (fixed shift)
   -------------------------------------------------------------------------

   function Iterate
     (A      : Matrix;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Result
   is
      N   : constant Dimension := X0'Length;
      Mu  : constant Float := Params.Mu;
      Res : Result;
      X   : Vector (1 .. N);
      Y   : Vector (1 .. N);
      Lam : Float;
      Lin : Linear_Result;
      Nrm : Float;
      Max_It : Natural;
      Theta  : Float;
      Shift  : Float;

      function Residual_Of (Xv : Vector; Lv : Float) return Float is
      begin
         return Eigen_Residual_Norm (A, Xv, Lv);
      end Residual_Of;

      function Acceptable (R : Float; Lv : Float) return Boolean is
      begin
         return R <= Params.Tol
           or else R <= 1.0E-6 * (1.0 + Abs_F (Lv));
      end Acceptable;

      --  Classic inverse-iteration estimate λ ≈ μ + 1/(xᵀ y) when
      --  ‖x‖ = 1 and y = (A − μ I)⁻¹ x; fall back to Rayleigh.
      function Estimate_Lambda
        (Xv : Vector; Yv : Vector; Shift_Used : Float) return Float
      is
         Den : constant Float := Dot (Xv, Yv);
      begin
         if Abs_F (Den) > Norm_Tol then
            return Shift_Used + 1.0 / Den;
         else
            return Rayleigh_Quotient (A, Xv);
         end if;
      end Estimate_Lambda;
   begin
      Res.N := N;
      Res.Mu := Mu;
      Res.Success := False;

      if N = 0
        or else A'Length (1) /= N
        or else A'Length (2) /= N
      then
         Res.Stat := Dimension_Error;
         return Res;
      end if;

      if Params.Tol < 0.0 then
         Res.Stat := Ill_Started;
         return Res;
      end if;

      Nrm := Norm2 (X0);
      if Nrm <= Norm_Tol then
         Res.Stat := Ill_Started;
         return Res;
      end if;

      for I in 1 .. N loop
         X (I) := X0 (X0'First + (I - 1)) / Nrm;
      end loop;

      Lam := Rayleigh_Quotient (A, X);
      Res.Residual := Residual_Of (X, Lam);
      if Acceptable (Res.Residual, Lam) then
         Res.Eigenvalue := Lam;
         for I in 1 .. N loop
            Res.Eigenvector (I) := X (I);
         end loop;
         Res.Iterations := 0;
         Res.Stat := Converged;
         Res.Success := True;
         return Res;
      end if;

      if Params.Max_Iter = 0 then
         Max_It := 100;
      else
         Max_It := Params.Max_Iter;
      end if;

      for K in 1 .. Max_It loop
         Shift := Mu;
         Lin := Solve_Shifted (A, Shift, X);

         --  Exact eigenvalue shift ⇒ singular A−μI. Try a tiny
         --  perturbation of the *solve* shift only; report original Mu.
         if not Lin.Success then
            Shift := Mu + (1.0E-6 + 1.0E-6 * Abs_F (Mu));
            Lin := Solve_Shifted (A, Shift, X);
         end if;

         if not Lin.Success then
            Res.Eigenvalue := Lam;
            for I in 1 .. N loop
               Res.Eigenvector (I) := X (I);
            end loop;
            Res.Iterations := K - 1;
            Res.Residual := Residual_Of (X, Lam);
            if Acceptable (Res.Residual, Lam)
              or else Res.Residual <= 1.0E-3
            then
               Res.Stat := Converged;
               Res.Success := True;
            else
               Res.Stat := Singular_Shift;
               Res.Success := False;
            end if;
            return Res;
         end if;

         for I in 1 .. N loop
            Y (I) := Lin.Y (I);
         end loop;
         Nrm := Norm2 (Y);
         if Nrm <= Norm_Tol then
            Res.Eigenvalue := Lam;
            for I in 1 .. N loop
               Res.Eigenvector (I) := X (I);
            end loop;
            Res.Iterations := K;
            Res.Residual := Residual_Of (X, Lam);
            Res.Stat := Breakdown;
            return Res;
         end if;

         --  Estimate λ ≈ μ + 1/(xᵀ y) from unnormalized y, then
         --  normalize and pick Rayleigh vs that estimate by residual.
         Theta := Estimate_Lambda (X, Y, Shift);
         for I in 1 .. N loop
            X (I) := Y (I) / Nrm;
         end loop;
         declare
            Rq   : constant Float := Rayleigh_Quotient (A, X);
            R_Rq : constant Float := Residual_Of (X, Rq);
            R_Th : constant Float := Residual_Of (X, Theta);
         begin
            if R_Th < R_Rq then
               Lam := Theta;
               Res.Residual := R_Th;
            else
               Lam := Rq;
               Res.Residual := R_Rq;
            end if;
         end;
         Res.Iterations := K;
         Res.Eigenvalue := Lam;
         for I in 1 .. N loop
            Res.Eigenvector (I) := X (I);
         end loop;

         if Acceptable (Res.Residual, Lam) then
            Res.Stat := Converged;
            Res.Success := True;
            return Res;
         end if;
      end loop;

      Res.Stat := Iteration_Limit;
      Res.Success := False;
      return Res;
   end Iterate;

   function Eigenpair_Near
     (A      : Matrix;
      Mu     : Float;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Result
   is
      P : Parameters := Params;
   begin
      P.Mu := Mu;
      return Iterate (A, X0, P);
   end Eigenpair_Near;

   function Eigenpair_Near
     (A      : Matrix;
      Mu     : Float;
      Params : Parameters := Default_Parameters) return Result
   is
      Res : Result;
      N   : Dimension;
      X0  : Vector (1 .. Max_N);
   begin
      if A'Length (1) = 0
        or else A'Length (2) = 0
        or else A'Length (1) /= A'Length (2)
      then
         Res.Stat := Dimension_Error;
         Res.Success := False;
         Res.N := 0;
         Res.Mu := Mu;
         return Res;
      end if;

      N := A'Length (1);
      for I in 1 .. N loop
         X0 (I) := 1.0;
      end loop;
      return Eigenpair_Near (A, Mu, X0 (1 .. N), Params);
   end Eigenpair_Near;

   function Eigenpair_Near
     (A      : Matrix;
      Params : Parameters := Default_Parameters) return Result
   is
   begin
      return Eigenpair_Near (A, Params.Mu, Params);
   end Eigenpair_Near;

end Inverse_Iteration;
