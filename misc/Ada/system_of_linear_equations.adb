--  System_Of_Linear_Equations body — educational Float survey sketches.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body System_Of_Linear_Equations
  with SPARK_Mode => Off
is

   package EF renames Ada.Numerics.Elementary_Functions;

   -------------------------------------------------------------------------
   -- Internal helpers
   -------------------------------------------------------------------------

   function Abs_F (X : Float) return Float is
   begin
      if X < 0.0 then
         return -X;
      else
         return X;
      end if;
   end Abs_F;

   function Pack
     (X      : Vector;
      N      : Dimension;
      Iters  : Natural;
      Rnorm  : Float;
      Stat   : Status;
      Swaps  : Natural := 0) return Result
   is
      R : Result;
   begin
      R.N := N;
      R.Iterations := Iters;
      R.Residual := Rnorm;
      R.Stat := Stat;
      R.Success := Stat = Ok or else Stat = Converged;
      R.Swap_Count := Swaps;
      for I in 1 .. N loop
         R.X (I) := X (X'First + I - 1);
      end loop;
      return R;
   end Pack;

   function Copy_To_Work
     (A : Matrix; N : Dimension) return Matrix
   is
      U : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            U (I, J) :=
              A (A'First (1) + I - 1, A'First (2) + J - 1);
         end loop;
      end loop;
      return U;
   end Copy_To_Work;

   function Copy_Vec_To_Work
     (V : Vector; N : Dimension) return Vector
   is
      B : Vector (1 .. N);
   begin
      for I in 1 .. N loop
         B (I) := V (V'First + I - 1);
      end loop;
      return B;
   end Copy_Vec_To_Work;

   function Has_Zero_Diagonal (A : Matrix) return Boolean is
      N : constant Dimension := A'Length (1);
   begin
      for I in 1 .. N loop
         if Abs_F (A (A'First (1) + I - 1, A'First (2) + I - 1))
           <= Diagonal_Tol
         then
            return True;
         end if;
      end loop;
      return False;
   end Has_Zero_Diagonal;

   function Effective_Stationary_Budget (P : Parameters) return Natural is
   begin
      if P.Max_Iter = 0 then
         return Default_Max_Iter_Stationary;
      else
         return P.Max_Iter;
      end if;
   end Effective_Stationary_Budget;

   function Effective_CG_Budget
     (N : Dimension; P : Parameters) return Natural
   is
   begin
      if P.Max_Iter = 0 then
         return Natural (N);
      else
         return P.Max_Iter;
      end if;
   end Effective_CG_Budget;

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
         if Abs_F (A (I) - B (B'First + (I - A'First))) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Vec_Near;

   function Dot (U, V : Vector) return Float is
      S : Float := 0.0;
   begin
      for I in U'Range loop
         S := S + U (I) * V (V'First + (I - U'First));
      end loop;
      return S;
   end Dot;

   function Norm2 (V : Vector) return Float is
      S : Float := 0.0;
   begin
      for X of V loop
         S := S + X * X;
      end loop;
      return EF.Sqrt (S);
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
         R (I) := U (I) + V (V'First + (I - U'First));
      end loop;
      return R;
   end Add;

   function Sub (U, V : Vector) return Vector is
      R : Vector (U'Range);
   begin
      for I in U'Range loop
         R (I) := U (I) - V (V'First + (I - U'First));
      end loop;
      return R;
   end Sub;

   function Mat_Vec (A : Matrix; X : Vector) return Vector is
      N : constant Dimension := X'Length;
      Y : Vector (1 .. N) := [others => 0.0];
      S : Float;
   begin
      for I in 1 .. N loop
         S := 0.0;
         for J in 1 .. N loop
            S := S
              + A (A'First (1) + I - 1, A'First (2) + J - 1)
              * X (X'First + J - 1);
         end loop;
         Y (I) := S;
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
      N : constant Dimension := A'Length (1);
   begin
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            if Abs_F
                 (A (A'First (1) + I - 1, A'First (2) + J - 1)
                  - A (A'First (1) + J - 1, A'First (2) + I - 1))
              > Tol
            then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Symmetric;

   function Is_Diagonally_Dominant (A : Matrix) return Boolean is
      N : constant Dimension := A'Length (1);
      Off : Float;
      Diag : Float;
   begin
      for I in 1 .. N loop
         Off := 0.0;
         for J in 1 .. N loop
            if J /= I then
               Off := Off
                 + Abs_F (A (A'First (1) + I - 1, A'First (2) + J - 1));
            end if;
         end loop;
         Diag := Abs_F (A (A'First (1) + I - 1, A'First (2) + I - 1));
         if Diag < Off then
            return False;
         end if;
      end loop;
      return True;
   end Is_Diagonally_Dominant;

   function Is_Strictly_Diagonally_Dominant (A : Matrix) return Boolean is
      N : constant Dimension := A'Length (1);
      Off : Float;
      Diag : Float;
   begin
      for I in 1 .. N loop
         Off := 0.0;
         for J in 1 .. N loop
            if J /= I then
               Off := Off
                 + Abs_F (A (A'First (1) + I - 1, A'First (2) + J - 1));
            end if;
         end loop;
         Diag := Abs_F (A (A'First (1) + I - 1, A'First (2) + I - 1));
         if Diag <= Off then
            return False;
         end if;
      end loop;
      return True;
   end Is_Strictly_Diagonally_Dominant;

   function Is_Tridiagonal
     (A : Matrix; Tol : Float := Epsilon_Tol) return Boolean
   is
      N : constant Dimension := A'Length (1);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            if Abs_F (Float (I - J)) > 1.0 then
               if Abs_F
                    (A (A'First (1) + I - 1, A'First (2) + J - 1))
                 > Tol
               then
                  return False;
               end if;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Tridiagonal;

   function Has_Positive_Diagonal
     (A : Matrix; Tol : Float := Diagonal_Tol) return Boolean
   is
      N : constant Dimension := A'Length (1);
   begin
      for I in 1 .. N loop
         if A (A'First (1) + I - 1, A'First (2) + I - 1) <= Tol then
            return False;
         end if;
      end loop;
      return True;
   end Has_Positive_Diagonal;

   -------------------------------------------------------------------------
   -- Residuals
   -------------------------------------------------------------------------

   function Residual (A : Matrix; X, B : Vector) return Vector is
      Ax : constant Vector := Mat_Vec (A, X);
   begin
      return Sub (B, Ax);
   end Residual;

   function Residual_Norm (A : Matrix; X, B : Vector) return Float is
   begin
      return Norm2 (Residual (A, X, B));
   end Residual_Norm;

   -------------------------------------------------------------------------
   -- Builders
   -------------------------------------------------------------------------

   function Zero_Vector (N : Dimension) return Vector is
      V : constant Vector (1 .. N) := [others => 0.0];
   begin
      return V;
   end Zero_Vector;

   function Ones_Vector
     (N : Dimension; Value : Float := 1.0) return Vector
   is
      V : constant Vector (1 .. N) := [others => Value];
   begin
      return V;
   end Ones_Vector;

   function Identity (N : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         A (I, I) := 1.0;
      end loop;
      return A;
   end Identity;

   function Make_Diagonally_Dominant (N : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I = J then
               A (I, J) := Float (N);
            else
               A (I, J) := 1.0;
            end if;
         end loop;
      end loop;
      return A;
   end Make_Diagonally_Dominant;

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

   function Make_Nonsymmetric_DD (N : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I = J then
               A (I, J) := Float (N);
            elsif J > I then
               A (I, J) := 1.0;
            else
               A (I, J) := 0.5;
            end if;
         end loop;
      end loop;
      return A;
   end Make_Nonsymmetric_DD;

   function Make_Singular (N : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      --  Row 1 = Row 2 = (1,1,…,1); remaining rows identity-ish.
      for J in 1 .. N loop
         A (1, J) := 1.0;
         A (2, J) := 1.0;
      end loop;
      for I in 3 .. N loop
         A (I, I) := 1.0;
      end loop;
      return A;
   end Make_Singular;

   function Make_Diagonal_Plus_Ones (N : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I = J then
               A (I, J) := Float (N + 1);
            else
               A (I, J) := 1.0;
            end if;
         end loop;
      end loop;
      return A;
   end Make_Diagonal_Plus_Ones;

   function Make_RHS_Ones
     (N : Dimension; Value : Float := 1.0) return Vector
   is
   begin
      return Ones_Vector (N, Value);
   end Make_RHS_Ones;

   function Make_RHS_From_Solution
     (A : Matrix; X_Star : Vector) return Vector
   is
   begin
      return Mat_Vec (A, X_Star);
   end Make_RHS_From_Solution;

   -------------------------------------------------------------------------
   -- Taxonomy
   -------------------------------------------------------------------------

   function Classify_Matrix
     (A : Matrix; Tol : Float := 1.0E-6) return Matrix_Properties
   is
      P : Matrix_Properties;
      N : constant Dimension := A'Length (1);
      Row_Abs : Float;
      Sing : Boolean := False;
   begin
      P.N := N;
      P.Symmetric := Is_Symmetric (A, Tol);
      P.Diagonally_Dominant := Is_Diagonally_Dominant (A);
      P.Strictly_DD := Is_Strictly_Diagonally_Dominant (A);
      P.Positive_Diagonal := Has_Positive_Diagonal (A);
      P.Tridiagonal := Is_Tridiagonal (A, Tol);
      P.SPD_Heuristic :=
        P.Symmetric and then P.Positive_Diagonal
        and then P.Diagonally_Dominant;

      for I in 1 .. N loop
         Row_Abs := 0.0;
         for J in 1 .. N loop
            Row_Abs := Row_Abs
              + Abs_F (A (A'First (1) + I - 1, A'First (2) + J - 1));
         end loop;
         if Row_Abs <= Tol then
            Sing := True;
         end if;
         if Abs_F (A (A'First (1) + I - 1, A'First (2) + I - 1))
           <= Diagonal_Tol
         then
            Sing := True;
         end if;
      end loop;
      --  Duplicate-row heuristic for Make_Singular (first two rows equal).
      if N >= 2 then
         declare
            Diff : Float := 0.0;
         begin
            for J in 1 .. N loop
               Diff := Diff
                 + Abs_F
                     (A (A'First (1), A'First (2) + J - 1)
                      - A (A'First (1) + 1, A'First (2) + J - 1));
            end loop;
            if Diff <= Tol then
               Sing := True;
            end if;
         end;
      end if;
      P.Singular_Heuristic := Sing;
      return P;
   end Classify_Matrix;

   function Recommend_Method (P : Matrix_Properties) return Method_Kind is
   begin
      if P.Singular_Heuristic then
         return Gaussian_Elimination;
      elsif P.Tridiagonal and then P.N >= 2 then
         return Thomas;
      elsif P.SPD_Heuristic and then P.N >= 4 then
         return Conjugate_Gradient;
      elsif P.Strictly_DD then
         return Gauss_Seidel;
      else
         return Gaussian_Elimination;
      end if;
   end Recommend_Method;

   function Classify_Method (K : Method_Kind) return Method_Info is
   begin
      case K is
         when Gaussian_Elimination =>
            return
              (Kind => Gaussian_Elimination,
               Is_Direct => True,
               Is_Iterative => False,
               Needs_SPD => False,
               Needs_DD => False,
               Structured_Only => False);
         when Thomas =>
            return
              (Kind => Thomas,
               Is_Direct => True,
               Is_Iterative => False,
               Needs_SPD => False,
               Needs_DD => False,
               Structured_Only => True);
         when Jacobi =>
            return
              (Kind => Jacobi,
               Is_Direct => False,
               Is_Iterative => True,
               Needs_SPD => False,
               Needs_DD => True,
               Structured_Only => False);
         when Gauss_Seidel =>
            return
              (Kind => Gauss_Seidel,
               Is_Direct => False,
               Is_Iterative => True,
               Needs_SPD => False,
               Needs_DD => True,
               Structured_Only => False);
         when Conjugate_Gradient =>
            return
              (Kind => Conjugate_Gradient,
               Is_Direct => False,
               Is_Iterative => True,
               Needs_SPD => True,
               Needs_DD => False,
               Structured_Only => False);
         when BiCG =>
            return
              (Kind => BiCG,
               Is_Direct => False,
               Is_Iterative => True,
               Needs_SPD => False,
               Needs_DD => False,
               Structured_Only => False);
      end case;
   end Classify_Method;

   function Method_Name (K : Method_Kind) return String is
   begin
      case K is
         when Gaussian_Elimination => return "Gaussian elimination (GEPP)";
         when Thomas               => return "Thomas (tridiagonal)";
         when Jacobi               => return "Jacobi";
         when Gauss_Seidel         => return "Gauss-Seidel";
         when Conjugate_Gradient   => return "Conjugate gradient (CG)";
         when BiCG                 => return "BiCG (catalogued)";
      end case;
   end Method_Name;

   function Method_Count return Positive is
   begin
      return Method_Kind'Pos (Method_Kind'Last)
           - Method_Kind'Pos (Method_Kind'First) + 1;
   end Method_Count;

   -------------------------------------------------------------------------
   -- Solve_GE — GEPP + back substitution
   -------------------------------------------------------------------------

   function Solve_GE (A : Matrix; B : Vector) return Result is
      N : constant Dimension := B'Length;
      U : Matrix (1 .. N, 1 .. N) := Copy_To_Work (A, N);
      Rhs : Vector (1 .. N) := Copy_Vec_To_Work (B, N);
      X : Vector (1 .. N) := [others => 0.0];
      Pivot_Row : Positive;
      Best, Cand, Mult, Pivot, S : Float;
      Swaps : Natural := 0;
      Tmp : Float;
   begin
      --  Forward elimination with partial pivoting.
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
            return Pack (X, N, 0, Float'Last, Singular, Swaps);
         end if;

         if Pivot_Row /= K then
            for J in 1 .. N loop
               Tmp := U (K, J);
               U (K, J) := U (Pivot_Row, J);
               U (Pivot_Row, J) := Tmp;
            end loop;
            Tmp := Rhs (K);
            Rhs (K) := Rhs (Pivot_Row);
            Rhs (Pivot_Row) := Tmp;
            Swaps := Swaps + 1;
         end if;

         Pivot := U (K, K);
         if Abs_F (Pivot) <= Pivot_Tol then
            return Pack (X, N, 0, Float'Last, Zero_Pivot, Swaps);
         end if;

         if K < N then
            for I in K + 1 .. N loop
               Mult := U (I, K) / Pivot;
               U (I, K) := 0.0;
               for J in K + 1 .. N loop
                  U (I, J) := U (I, J) - Mult * U (K, J);
               end loop;
               Rhs (I) := Rhs (I) - Mult * Rhs (K);
            end loop;
         end if;
      end loop;

      --  Back substitution.
      for I in reverse 1 .. N loop
         S := Rhs (I);
         for J in I + 1 .. N loop
            S := S - U (I, J) * X (J);
         end loop;
         Pivot := U (I, I);
         if Abs_F (Pivot) <= Pivot_Tol then
            return Pack (X, N, 0, Float'Last, Zero_Pivot, Swaps);
         end if;
         X (I) := S / Pivot;
      end loop;

      declare
         Rnorm : constant Float := Residual_Norm (A, X, B);
      begin
         return Pack (X, N, 0, Rnorm, Ok, Swaps);
      end;
   end Solve_GE;

   -------------------------------------------------------------------------
   -- Solve_Thomas — tridiagonal Thomas algorithm
   -------------------------------------------------------------------------

   function Solve_Thomas (A : Matrix; B : Vector) return Result is
      N : constant Dimension := B'Length;
      X : Vector (1 .. N) := [others => 0.0];
      --  a = sub, b = diag, c = super, d = RHS (mutated in place).
      Sub : Vector (1 .. N) := [others => 0.0];
      Diag : Vector (1 .. N);
      Super : Vector (1 .. N) := [others => 0.0];
      Rhs : Vector (1 .. N);
      W : Float;
   begin
      if not Is_Tridiagonal (A) then
         return Pack (X, N, 0, Float'Last, Not_Tridiagonal);
      end if;

      for I in 1 .. N loop
         Diag (I) := A (A'First (1) + I - 1, A'First (2) + I - 1);
         Rhs (I) := B (B'First + I - 1);
         if I > 1 then
            Sub (I) :=
              A (A'First (1) + I - 1, A'First (2) + I - 2);
         end if;
         if I < N then
            Super (I) :=
              A (A'First (1) + I - 1, A'First (2) + I);
         end if;
      end loop;

      if Abs_F (Diag (1)) <= Pivot_Tol then
         return Pack (X, N, 0, Float'Last, Zero_Pivot);
      end if;

      --  Forward sweep.
      for I in 2 .. N loop
         W := Sub (I) / Diag (I - 1);
         Diag (I) := Diag (I) - W * Super (I - 1);
         Rhs (I) := Rhs (I) - W * Rhs (I - 1);
         if Abs_F (Diag (I)) <= Pivot_Tol then
            return Pack (X, N, 0, Float'Last, Singular);
         end if;
      end loop;

      --  Back substitution.
      X (N) := Rhs (N) / Diag (N);
      for I in reverse 1 .. N - 1 loop
         X (I) := (Rhs (I) - Super (I) * X (I + 1)) / Diag (I);
      end loop;

      declare
         Rnorm : constant Float := Residual_Norm (A, X, B);
      begin
         return Pack (X, N, 0, Rnorm, Ok);
      end;
   end Solve_Thomas;

   -------------------------------------------------------------------------
   -- Solve_Jacobi
   -------------------------------------------------------------------------

   function Solve_Jacobi
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
   is
      N : constant Dimension := B'Length;
      X : Vector (1 .. N);
      X_New : Vector (1 .. N);
      Budget : constant Natural := Effective_Stationary_Budget (Params);
      Sigma, Aii, Rnorm : Float;
   begin
      if Has_Zero_Diagonal (A) then
         return Pack
           (Zero_Vector (N), N, 0, Float'Last, Zero_Diagonal);
      end if;

      if X0'Length = 0 then
         X := [others => 0.0];
      else
         X := Copy_Vec_To_Work (X0, N);
      end if;

      Rnorm := Residual_Norm (A, X, B);
      declare
         Abs_Tol : constant Float :=
           Float'Max (Params.Tol, Params.Tol * (1.0 + Norm2 (B)));
      begin
         if Rnorm <= Abs_Tol then
            return Pack (X, N, 0, Rnorm, Converged);
         end if;

         for Iter in 1 .. Budget loop
            for I in 1 .. N loop
               Sigma := 0.0;
               for J in 1 .. N loop
                  if J /= I then
                     Sigma := Sigma
                       + A (A'First (1) + I - 1, A'First (2) + J - 1)
                       * X (J);
                  end if;
               end loop;
               Aii := A (A'First (1) + I - 1, A'First (2) + I - 1);
               X_New (I) := (B (B'First + I - 1) - Sigma) / Aii;
            end loop;
            X := X_New;
            Rnorm := Residual_Norm (A, X, B);
            if Rnorm <= Abs_Tol then
               return Pack (X, N, Iter, Rnorm, Converged);
            end if;
         end loop;
      end;

      return Pack (X, N, Budget, Rnorm, Iteration_Limit);
   end Solve_Jacobi;

   -------------------------------------------------------------------------
   -- Solve_Gauss_Seidel
   -------------------------------------------------------------------------

   function Solve_Gauss_Seidel
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
   is
      N : constant Dimension := B'Length;
      X : Vector (1 .. N);
      Budget : constant Natural := Effective_Stationary_Budget (Params);
      Sigma, Aii, Rnorm : Float;
   begin
      if Has_Zero_Diagonal (A) then
         return Pack
           (Zero_Vector (N), N, 0, Float'Last, Zero_Diagonal);
      end if;

      if X0'Length = 0 then
         X := [others => 0.0];
      else
         X := Copy_Vec_To_Work (X0, N);
      end if;

      Rnorm := Residual_Norm (A, X, B);
      declare
         Abs_Tol : constant Float :=
           Float'Max (Params.Tol, Params.Tol * (1.0 + Norm2 (B)));
      begin
         if Rnorm <= Abs_Tol then
            return Pack (X, N, 0, Rnorm, Converged);
         end if;

         for Iter in 1 .. Budget loop
            for I in 1 .. N loop
               Sigma := 0.0;
               for J in 1 .. N loop
                  if J /= I then
                     Sigma := Sigma
                       + A (A'First (1) + I - 1, A'First (2) + J - 1)
                       * X (J);
                  end if;
               end loop;
               Aii := A (A'First (1) + I - 1, A'First (2) + I - 1);
               X (I) := (B (B'First + I - 1) - Sigma) / Aii;
            end loop;
            Rnorm := Residual_Norm (A, X, B);
            if Rnorm <= Abs_Tol then
               return Pack (X, N, Iter, Rnorm, Converged);
            end if;
         end loop;
      end;

      return Pack (X, N, Budget, Rnorm, Iteration_Limit);
   end Solve_Gauss_Seidel;

   -------------------------------------------------------------------------
   -- Solve_CG — Hestenes–Stiefel for SPD
   -------------------------------------------------------------------------

   function Solve_CG
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
   is
      N : constant Dimension := B'Length;
      X : Vector (1 .. N);
      R, P, Ap : Vector (1 .. N);
      RR_Old, RR_New, Alpha, Beta, PAp, R_Norm0, Abs_Tol : Float;
      Limit : constant Natural := Effective_CG_Budget (N, Params);
   begin
      if X0'Length = 0 then
         X := [others => 0.0];
      else
         X := Copy_Vec_To_Work (X0, N);
      end if;

      R := Residual (A, X, B);
      RR_Old := Dot (R, R);
      R_Norm0 := EF.Sqrt (RR_Old);
      Abs_Tol := Float'Max (Params.Tol, Params.Tol * (1.0 + R_Norm0));

      if R_Norm0 <= Abs_Tol then
         return Pack (X, N, 0, R_Norm0, Converged);
      end if;

      P := R;

      for K in 1 .. Limit loop
         Ap := Mat_Vec (A, P);
         PAp := Dot (P, Ap);

         if Abs_F (PAp) <= Epsilon_Tol * (1.0 + RR_Old) then
            return Pack (X, N, K - 1, EF.Sqrt (RR_Old), Breakdown);
         end if;

         Alpha := RR_Old / PAp;
         X := Add (X, Scale (P, Alpha));
         R := Sub (R, Scale (Ap, Alpha));
         RR_New := Dot (R, R);

         if EF.Sqrt (RR_New) <= Abs_Tol then
            return Pack (X, N, K, EF.Sqrt (RR_New), Converged);
         end if;

         if Abs_F (RR_Old) <= Epsilon_Tol then
            return Pack (X, N, K, EF.Sqrt (RR_New), Breakdown);
         end if;

         Beta := RR_New / RR_Old;
         P := Add (R, Scale (P, Beta));
         RR_Old := RR_New;
      end loop;

      declare
         R_Final : constant Float := EF.Sqrt (RR_Old);
      begin
         if R_Final <= Abs_Tol
           or else
             (Limit >= Natural (N)
              and then R_Final <= 1.0E-5 * (1.0 + R_Norm0))
         then
            return Pack (X, N, Limit, R_Final, Converged);
         else
            return Pack (X, N, Limit, R_Final, Iteration_Limit);
         end if;
      end;
   end Solve_CG;

   -------------------------------------------------------------------------
   -- Dispatcher / auto
   -------------------------------------------------------------------------

   function Solve
     (A      : Matrix;
      B      : Vector;
      Kind   : Method_Kind := Gaussian_Elimination;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
   is
   begin
      case Kind is
         when Gaussian_Elimination =>
            return Solve_GE (A, B);
         when Thomas =>
            return Solve_Thomas (A, B);
         when Jacobi =>
            return Solve_Jacobi (A, B, X0, Params);
         when Gauss_Seidel =>
            return Solve_Gauss_Seidel (A, B, X0, Params);
         when Conjugate_Gradient =>
            return Solve_CG (A, B, X0, Params);
         when BiCG =>
            declare
               R : Result;
            begin
               R.N := B'Length;
               R.Stat := Ill_Started;
               R.Success := False;
               R.Residual := Float'Last;
               return R;
            end;
      end case;
   end Solve;

   function Solve_Auto
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
   is
      Props : constant Matrix_Properties := Classify_Matrix (A);
      Kind  : constant Method_Kind := Recommend_Method (Props);
   begin
      return Solve (A, B, Kind, X0, Params);
   end Solve_Auto;

end System_Of_Linear_Equations;
