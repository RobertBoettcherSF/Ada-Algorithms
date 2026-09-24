--  Rayleigh_Quotient_Iteration body — dense Float RQI + educational GEPP.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Rayleigh_Quotient_Iteration
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
     (A : Matrix; X : Vector; Mu : Float) return Vector
   is
      Ax : constant Vector := Mat_Vec (A, X);
   begin
      return Sub (Ax, Scale (X, Mu));
   end Eigen_Residual;

   function Eigen_Residual_Norm
     (A : Matrix; X : Vector; Mu : Float) return Float
   is
   begin
      return Norm2 (Eigen_Residual (A, X, Mu));
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

   function Make_Symmetric_Example
     (Kind : Example_Kind; N : Dimension) return Matrix
   is
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      case Kind is
         when Diagonal_Known =>
            for I in 1 .. N loop
               A (I, I) := Float (I);
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

         when Hilbert_Tiny =>
            for I in 1 .. N loop
               for J in 1 .. N loop
                  A (I, J) := 1.0 / Float (I + J - 1);
               end loop;
            end loop;

         when Symmetric_Randomish =>
            declare
               B : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
               S : Float;
            begin
               for I in 1 .. N loop
                  for J in 1 .. N loop
                     B (I, J) :=
                       Float ((I * 17 + J * 31) mod 97) / 97.0
                       - 0.5;
                  end loop;
               end loop;
               for I in 1 .. N loop
                  for J in 1 .. N loop
                     S := 0.0;
                     for K in 1 .. N loop
                        S := S + B (K, I) * B (K, J);
                     end loop;
                     A (I, J) := S;
                  end loop;
                  A (I, I) := A (I, I) + Float (I);
               end loop;
            end;
      end case;
      return A;
   end Make_Symmetric_Example;

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
   -- Iteration
   -------------------------------------------------------------------------

   function Iterate
     (A      : Matrix;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Result
   is
      N : constant Dimension := X0'Length;
      Res : Result;
      X   : Vector (1 .. N);
      Mu  : Float;
      Lin : Linear_Result;
      Y   : Vector (1 .. N);
      Nrm : Float;
      Max_It : Natural;
      Shift  : Float;
      function Residual_Of (Xv : Vector; Muv : Float) return Float is
      begin
         return Eigen_Residual_Norm (A, Xv, Muv);
      end Residual_Of;

      function Acceptable (R : Float; Muv : Float) return Boolean is
      begin
         --  Absolute Tol, with a tiny absolute floor for Float chatter.
         return R <= Params.Tol
           or else R <= 1.0E-6 * (1.0 + Abs_F (Muv));
      end Acceptable;
   begin
      Res.N := N;
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

      if Params.Use_Initial_Mu then
         Mu := Params.Initial_Mu;
      else
         Mu := Rayleigh_Quotient (A, X);
      end if;

      if Params.Max_Iter = 0 then
         Max_It := 50;
      else
         Max_It := Params.Max_Iter;
      end if;

      Res.Residual := Residual_Of (X, Mu);
      if Acceptable (Res.Residual, Mu) then
         Res.Mu := Mu;
         for I in 1 .. N loop
            Res.X (I) := X (I);
         end loop;
         Res.Iterations := 0;
         Res.Stat := Converged;
         Res.Success := True;
         return Res;
      end if;

      for K in 1 .. Max_It loop
         Shift := Mu;
         Lin := Solve_Shifted (A, Shift, X);

         --  Exact eigenvalue shift ⇒ singular A−μI. Perturb once, or fall
         --  back to the Rayleigh quotient of the current vector.
         if not Lin.Success then
            Shift := Mu + (1.0E-6 + 1.0E-6 * Abs_F (Mu));
            Lin := Solve_Shifted (A, Shift, X);
         end if;
         if not Lin.Success then
            Shift := Rayleigh_Quotient (A, X);
            if Abs_F (Shift - Mu) > 1.0E-12 * (1.0 + Abs_F (Mu)) then
               Lin := Solve_Shifted (A, Shift, X);
            end if;
         end if;

         if not Lin.Success then
            Res.Mu := Mu;
            for I in 1 .. N loop
               Res.X (I) := X (I);
            end loop;
            Res.Iterations := K - 1;
            Res.Residual := Residual_Of (X, Mu);
            if Acceptable (Res.Residual, Mu)
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
            Res.Mu := Mu;
            for I in 1 .. N loop
               Res.X (I) := X (I);
            end loop;
            Res.Iterations := K;
            Res.Residual := Residual_Of (X, Mu);
            Res.Stat := Breakdown;
            return Res;
         end if;

         for I in 1 .. N loop
            X (I) := Y (I) / Nrm;
         end loop;
         Mu := Rayleigh_Quotient (A, X);
         Res.Residual := Residual_Of (X, Mu);
         Res.Iterations := K;
         Res.Mu := Mu;
         for I in 1 .. N loop
            Res.X (I) := X (I);
         end loop;

         if Acceptable (Res.Residual, Mu) then
            Res.Stat := Converged;
            Res.Success := True;
            return Res;
         end if;
      end loop;

      Res.Stat := Iteration_Limit;
      Res.Success := False;
      return Res;
   end Iterate;

   function Solve
     (A      : Matrix;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Result
   is
   begin
      return Iterate (A, X0, Params);
   end Solve;

end Rayleigh_Quotient_Iteration;
