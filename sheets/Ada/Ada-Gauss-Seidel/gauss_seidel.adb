--  Gauss_Seidel body — classical Gauss–Seidel (SOR with ω = 1).

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Gauss_Seidel is

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
      N   : constant Positive := X'Length;
      Y   : Vector (1 .. N) := [others => 0.0];
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
            RI   : constant Positive := A'First (1) + I;
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

   function Is_Strictly_Diagonally_Dominant (A : Matrix) return Boolean is
      N : constant Natural := A'Length (1);
   begin
      for I in 0 .. N - 1 loop
         declare
            RI   : constant Positive := A'First (1) + I;
            Diag : constant Float := abs (A (RI, A'First (2) + I));
            Off  : Float := 0.0;
         begin
            for J in 0 .. N - 1 loop
               if J /= I then
                  Off := Off + abs (A (RI, A'First (2) + J));
               end if;
            end loop;
            if Diag <= Off then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Strictly_Diagonally_Dominant;

   function Residual (A : Matrix; X, B : Vector) return Vector is
   begin
      return Sub (B, Mat_Vec (A, X));
   end Residual;

   function Residual_Norm (A : Matrix; X, B : Vector) return Float is
   begin
      return Norm2 (Residual (A, X, B));
   end Residual_Norm;

   -------------------------------------------------------------------------
   -- Example builders
   -------------------------------------------------------------------------

   function Make_Example
     (Kind : Example_Kind; N : Dimension) return Matrix
   is
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      case Kind is
         when Diagonally_Dominant =>
            for I in 1 .. N loop
               for J in 1 .. N loop
                  if I = J then
                     A (I, J) := Float (N);
                  else
                     A (I, J) := 1.0;
                  end if;
               end loop;
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

         when Diagonal_Plus_Ones =>
            for I in 1 .. N loop
               for J in 1 .. N loop
                  A (I, J) := 1.0;
               end loop;
               A (I, I) := Float (N + 1);
            end loop;

         when Non_Convergent =>
            --  Classic educational matrix that often fails Gauss–Seidel:
            --  [[1, 2], [3, 1]] scaled / extended — not DD, spectral radius
            --  of the GS iteration matrix can exceed 1. For N=2 use that
            --  pair; for N>2 pad with a DD block so only the leading 2×2
            --  is hostile (tests use N=2 primarily).
            if N = 1 then
               A (1, 1) := 1.0;
            else
               A (1, 1) := 1.0;
               A (1, 2) := 2.0;
               A (2, 1) := 3.0;
               A (2, 2) := 1.0;
               for I in 3 .. N loop
                  A (I, I) := Float (N);
                  for J in 1 .. N loop
                     if J /= I then
                        A (I, J) := 0.1;
                     end if;
                  end loop;
               end loop;
            end if;
      end case;
      return A;
   end Make_Example;

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

   function Make_RHS_From_Solution
     (A : Matrix; X_Star : Vector) return Vector
   is
   begin
      return Mat_Vec (A, X_Star);
   end Make_RHS_From_Solution;

   -------------------------------------------------------------------------
   -- Core Gauss–Seidel iteration
   -------------------------------------------------------------------------

   function Effective_Max_Iter (Params : Parameters) return Natural is
   begin
      if Params.Max_Iter = 0 then
         return Default_Max_Iter;
      else
         return Params.Max_Iter;
      end if;
   end Effective_Max_Iter;

   function Has_Zero_Diagonal (A : Matrix) return Boolean is
      N : constant Natural := A'Length (1);
   begin
      for I in 0 .. N - 1 loop
         if abs (A (A'First (1) + I, A'First (2) + I)) <= Diagonal_Tol then
            return True;
         end if;
      end loop;
      return False;
   end Has_Zero_Diagonal;

   function Solve
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
   is
      N      : constant Dimension := B'Length;
      Res    : Result;
      X      : Vector (1 .. N);
      Budget : constant Natural := Effective_Max_Iter (Params);
      Sigma  : Float;
      Aii    : Float;
      Rnorm  : Float;
   begin
      Res.N := N;

      if A'Length (1) /= A'Length (2)
        or else A'Length (2) /= B'Length
        or else (X0'Length /= 0 and then X0'Length /= B'Length)
      then
         Res.Stat := Dimension_Error;
         Res.Success := False;
         Res.Residual := Float'Last;
         return Res;
      end if;

      if Has_Zero_Diagonal (A) then
         Res.Stat := Zero_Diagonal;
         Res.Success := False;
         Res.Residual := Float'Last;
         return Res;
      end if;

      --  Initial guess
      if X0'Length = 0 then
         X := [others => 0.0];
      else
         for I in 1 .. N loop
            X (I) := X0 (X0'First + I - 1);
         end loop;
      end if;

      Rnorm := Residual_Norm (A, X, B);
      if Rnorm <= Params.Tol then
         for I in 1 .. N loop
            Res.X (I) := X (I);
         end loop;
         Res.Iterations := 0;
         Res.Residual := Rnorm;
         Res.Stat := Converged;
         Res.Success := True;
         return Res;
      end if;

      for Iter in 1 .. Budget loop
         for I in 1 .. N loop
            declare
               Row  : constant Positive := A'First (1) + I - 1;
               Col0 : constant Positive := A'First (2);
            begin
               Sigma := 0.0;
               --  j < i : use already-updated (new) values
               --  j > i : use previous-iterate (old) values
               --  both live in the same in-place X vector
               for J in 1 .. N loop
                  if J /= I then
                     Sigma := Sigma + A (Row, Col0 + J - 1) * X (J);
                  end if;
               end loop;
               Aii := A (Row, Col0 + I - 1);
               X (I) := (B (B'First + I - 1) - Sigma) / Aii;
            end;
         end loop;

         Rnorm := Residual_Norm (A, X, B);
         if Rnorm <= Params.Tol then
            for I in 1 .. N loop
               Res.X (I) := X (I);
            end loop;
            Res.Iterations := Iter;
            Res.Residual := Rnorm;
            Res.Stat := Converged;
            Res.Success := True;
            return Res;
         end if;
      end loop;

      for I in 1 .. N loop
         Res.X (I) := X (I);
      end loop;
      Res.Iterations := Budget;
      Res.Residual := Rnorm;
      Res.Stat := Iteration_Limit;
      Res.Success := False;
      return Res;
   end Solve;

end Gauss_Seidel;
