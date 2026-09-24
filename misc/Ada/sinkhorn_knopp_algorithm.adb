--  Sinkhorn_Knopp_Algorithm body — alternate row/column scaling.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Sinkhorn_Knopp_Algorithm is

   package LEF renames Ada.Numerics.Long_Elementary_Functions;

   function Abs_R (X : Real) return Real is
   begin
      if X >= 0.0 then
         return X;
      else
         return -X;
      end if;
   end Abs_R;

   function Max_R (X, Y : Real) return Real is
   begin
      if X >= Y then
         return X;
      else
         return Y;
      end if;
   end Max_R;

   procedure Require_Nonempty (A : Matrix) is
   begin
      if A'Length (1) = 0 or else A'Length (2) = 0 then
         raise Invalid_Argument with "empty matrix";
      end if;
   end Require_Nonempty;

   procedure Require_Nonnegative (A : Matrix) is
   begin
      if not Is_Nonnegative (A) then
         raise Invalid_Argument with "matrix has negative entries";
      end if;
   end Require_Nonnegative;

   procedure Require_Positive_Targets (Targets : Vector) is
   begin
      for T of Targets loop
         if T <= Zero_Tol then
            raise Invalid_Argument with "nonpositive marginal target";
         end if;
      end loop;
   end Require_Positive_Targets;

   function Copy_Matrix (A : Matrix) return Matrix is
      R : Matrix (A'Range (1), A'Range (2));
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            R (I, J) := A (I, J);
         end loop;
      end loop;
      return R;
   end Copy_Matrix;

   ---------------------------------------------------------------------------
   -- Predicates / helpers
   ---------------------------------------------------------------------------

   function Is_Square (A : Matrix) return Boolean is
   begin
      return A'Length (1) = A'Length (2);
   end Is_Square;

   function Near (X, Y : Real; Tol : Real := Zero_Tol) return Boolean is
   begin
      return Abs_R (X - Y) <= Tol;
   end Near;

   function Is_Nonnegative
     (A : Matrix; Tol : Real := Zero_Tol) return Boolean
   is
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            if A (I, J) < -Tol then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Nonnegative;

   function Is_Strictly_Positive
     (A : Matrix; Tol : Real := Zero_Tol) return Boolean
   is
   begin
      if A'Length (1) = 0 or else A'Length (2) = 0 then
         return True;
      end if;
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            if A (I, J) <= Tol then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Strictly_Positive;

   function Has_Positive_Row_Sums
     (A : Matrix; Tol : Real := Zero_Tol) return Boolean
   is
   begin
      for I in A'Range (1) loop
         if Row_Sum (A, I) <= Tol then
            return False;
         end if;
      end loop;
      return True;
   end Has_Positive_Row_Sums;

   function Has_Positive_Col_Sums
     (A : Matrix; Tol : Real := Zero_Tol) return Boolean
   is
   begin
      for J in A'Range (2) loop
         if Col_Sum (A, J) <= Tol then
            return False;
         end if;
      end loop;
      return True;
   end Has_Positive_Col_Sums;

   function Row_Sum (A : Matrix; I : Positive) return Real is
      S : Real := 0.0;
   begin
      for J in A'Range (2) loop
         S := S + A (I, J);
      end loop;
      return S;
   end Row_Sum;

   function Col_Sum (A : Matrix; J : Positive) return Real is
      S : Real := 0.0;
   begin
      for I in A'Range (1) loop
         S := S + A (I, J);
      end loop;
      return S;
   end Col_Sum;

   function Row_Sums (A : Matrix) return Vector is
      R : Vector (1 .. A'Length (1));
      K : Positive := 1;
   begin
      for I in A'Range (1) loop
         R (K) := Row_Sum (A, I);
         K := K + 1;
      end loop;
      return R;
   end Row_Sums;

   function Col_Sums (A : Matrix) return Vector is
      C : Vector (1 .. A'Length (2));
      K : Positive := 1;
   begin
      for J in A'Range (2) loop
         C (K) := Col_Sum (A, J);
         K := K + 1;
      end loop;
      return C;
   end Col_Sums;

   function Max_Marginal_Residual
     (A           : Matrix;
      Row_Targets : Vector;
      Col_Targets : Vector) return Real
   is
      M : Real := 0.0;
      K : Positive;
   begin
      K := Row_Targets'First;
      for I in A'Range (1) loop
         M := Max_R (M, Abs_R (Row_Sum (A, I) - Row_Targets (K)));
         if K < Row_Targets'Last then
            K := K + 1;
         end if;
      end loop;
      K := Col_Targets'First;
      for J in A'Range (2) loop
         M := Max_R (M, Abs_R (Col_Sum (A, J) - Col_Targets (K)));
         if K < Col_Targets'Last then
            K := K + 1;
         end if;
      end loop;
      return M;
   end Max_Marginal_Residual;

   function Is_Nearly_Doubly_Stochastic
     (A : Matrix; Tol : Real := Sum_Tol) return Boolean
   is
   begin
      if A'Length (1) = 0 and then A'Length (2) = 0 then
         return True;
      end if;
      if not Is_Square (A) then
         return False;
      end if;
      if not Is_Nonnegative (A) then
         return False;
      end if;
      for I in A'Range (1) loop
         if Abs_R (Row_Sum (A, I) - 1.0) > Tol then
            return False;
         end if;
      end loop;
      for J in A'Range (2) loop
         if Abs_R (Col_Sum (A, J) - 1.0) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Is_Nearly_Doubly_Stochastic;

   function Matrices_Near
     (A, B : Matrix; Tol : Real := Sum_Tol) return Boolean
   is
   begin
      if A'Length (1) /= B'Length (1)
        or else A'Length (2) /= B'Length (2)
      then
         return False;
      end if;
      declare
         BI : Positive := B'First (1);
      begin
         for AI in A'Range (1) loop
            declare
               BJ : Positive := B'First (2);
            begin
               for AJ in A'Range (2) loop
                  if Abs_R (A (AI, AJ) - B (BI, BJ)) > Tol then
                     return False;
                  end if;
                  if BJ < B'Last (2) then
                     BJ := BJ + 1;
                  end if;
               end loop;
            end;
            if BI < B'Last (1) then
               BI := BI + 1;
            end if;
         end loop;
      end;
      return True;
   end Matrices_Near;

   function Frobenius_Distance (A, B : Matrix) return Real is
      S  : Real := 0.0;
      BI : Positive := B'First (1);
   begin
      for AI in A'Range (1) loop
         declare
            BJ : Positive := B'First (2);
            D  : Real;
         begin
            for AJ in A'Range (2) loop
               D := A (AI, AJ) - B (BI, BJ);
               S := S + D * D;
               if BJ < B'Last (2) then
                  BJ := BJ + 1;
               end if;
            end loop;
         end;
         if BI < B'Last (1) then
            BI := BI + 1;
         end if;
      end loop;
      return Real (LEF.Sqrt (Long_Float (S)));
   end Frobenius_Distance;

   function Ones_Vector
     (N : Dimension; Value : Real := 1.0) return Vector
   is
      R : Vector (1 .. N);
   begin
      for I in R'Range loop
         R (I) := Value;
      end loop;
      return R;
   end Ones_Vector;

   ---------------------------------------------------------------------------
   -- Constructors
   ---------------------------------------------------------------------------

   function Zero_Matrix (N : Dimension) return Matrix is
      R : constant Matrix (1 .. N, 1 .. N) :=
        [others => [others => 0.0]];
   begin
      return R;
   end Zero_Matrix;

   function Ones_Matrix (N : Dimension) return Matrix is
      R : constant Matrix (1 .. N, 1 .. N) :=
        [others => [others => 1.0]];
   begin
      return R;
   end Ones_Matrix;

   function Identity (N : Dimension) return Matrix is
      R : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         R (I, I) := 1.0;
      end loop;
      return R;
   end Identity;

   function Uniform (N : Dimension) return Matrix is
      V : constant Real := 1.0 / Real (N);
      R : constant Matrix (1 .. N, 1 .. N) :=
        [others => [others => V]];
   begin
      return R;
   end Uniform;

   function Positive_Toy (N : Dimension) return Matrix is
      R : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) :=
              1.0
              + Real ((I * 17 + J * 31) mod 97) / 100.0;
         end loop;
      end loop;
      return R;
   end Positive_Toy;

   function Hilbert_Like (N : Dimension) return Matrix is
      R : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) := 1.0 / Real (I + J - 1);
         end loop;
      end loop;
      return R;
   end Hilbert_Like;

   function Transportation_Kernel
     (N : Dimension; Eps : Real := 1.0) return Matrix
   is
      R    : Matrix (1 .. N, 1 .. N);
      Cost : Real;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            Cost := Real ((I - J) * (I - J));
            R (I, J) :=
              Real (LEF.Exp (Long_Float (-Cost / Eps)));
         end loop;
      end loop;
      return R;
   end Transportation_Kernel;

   function Example_2x2 return Matrix is
   begin
      return Matrix'([[1.0, 2.0], [3.0, 4.0]]);
   end Example_2x2;

   function Example_3x3 return Matrix is
   begin
      return Matrix'(
        [[1.0, 2.0, 3.0],
         [4.0, 5.0, 6.0],
         [7.0, 8.0, 9.0]]);
   end Example_3x3;

   function Scale (A : Matrix; S : Real) return Matrix is
      R : Matrix (A'Range (1), A'Range (2));
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            R (I, J) := A (I, J) * S;
         end loop;
      end loop;
      return R;
   end Scale;

   function Add (A, B : Matrix) return Matrix is
      R  : Matrix (A'Range (1), A'Range (2));
      BI : Positive := B'First (1);
   begin
      for AI in A'Range (1) loop
         declare
            BJ : Positive := B'First (2);
         begin
            for AJ in A'Range (2) loop
               R (AI, AJ) := A (AI, AJ) + B (BI, BJ);
               if BJ < B'Last (2) then
                  BJ := BJ + 1;
               end if;
            end loop;
         end;
         if BI < B'Last (1) then
            BI := BI + 1;
         end if;
      end loop;
      return R;
   end Add;

   ---------------------------------------------------------------------------
   -- Normalization
   ---------------------------------------------------------------------------

   function Normalize_Rows (A : Matrix) return Matrix is
   begin
      return Normalize_Rows (A, Ones_Vector (A'Length (1), 1.0));
   end Normalize_Rows;

   function Normalize_Rows (A : Matrix; Targets : Vector) return Matrix is
      R : Matrix (A'Range (1), A'Range (2));
      T : Positive := Targets'First;
   begin
      Require_Nonempty (A);
      Require_Nonnegative (A);
      Require_Positive_Targets (Targets);
      for I in A'Range (1) loop
         declare
            S : constant Real := Row_Sum (A, I);
            F : Real;
         begin
            if S <= Zero_Tol then
               raise Invalid_Argument with "zero row sum in Normalize_Rows";
            end if;
            F := Targets (T) / S;
            for J in A'Range (2) loop
               R (I, J) := A (I, J) * F;
            end loop;
         end;
         if T < Targets'Last then
            T := T + 1;
         end if;
      end loop;
      return R;
   end Normalize_Rows;

   function Normalize_Columns (A : Matrix) return Matrix is
   begin
      return Normalize_Columns (A, Ones_Vector (A'Length (2), 1.0));
   end Normalize_Columns;

   function Normalize_Columns (A : Matrix; Targets : Vector) return Matrix is
      R : Matrix (A'Range (1), A'Range (2));
      T : Positive := Targets'First;
   begin
      Require_Nonempty (A);
      Require_Nonnegative (A);
      Require_Positive_Targets (Targets);
      --  Copy first, then scale columns.
      R := Copy_Matrix (A);
      for J in A'Range (2) loop
         declare
            S : constant Real := Col_Sum (R, J);
            F : Real;
         begin
            if S <= Zero_Tol then
               raise Invalid_Argument
                 with "zero column sum in Normalize_Columns";
            end if;
            F := Targets (T) / S;
            for I in A'Range (1) loop
               R (I, J) := R (I, J) * F;
            end loop;
         end;
         if T < Targets'Last then
            T := T + 1;
         end if;
      end loop;
      return R;
   end Normalize_Columns;

   ---------------------------------------------------------------------------
   -- Iterate / Solve
   ---------------------------------------------------------------------------

   function Iterate
     (A : Matrix; Steps : Natural) return Matrix
   is
   begin
      return Iterate
        (A, Steps,
         Ones_Vector (A'Length (1), 1.0),
         Ones_Vector (A'Length (2), 1.0));
   end Iterate;

   function Iterate
     (A           : Matrix;
      Steps       : Natural;
      Row_Targets : Vector;
      Col_Targets : Vector) return Matrix
   is
      R : Matrix (A'Range (1), A'Range (2));
   begin
      Require_Nonempty (A);
      Require_Nonnegative (A);
      Require_Positive_Targets (Row_Targets);
      Require_Positive_Targets (Col_Targets);
      R := Copy_Matrix (A);
      for S in 1 .. Steps loop
         R := Normalize_Rows (R, Row_Targets);
         R := Normalize_Columns (R, Col_Targets);
      end loop;
      return R;
   end Iterate;

   procedure Pack_Into_Result
     (Work       : Matrix;
      Row_Sc     : Vector;
      Col_Sc     : Vector;
      Iters      : Natural;
      Resid      : Real;
      Conv       : Boolean;
      Result     : out Sinkhorn_Result)
   is
      RI : Positive := 1;
   begin
      if Work'Length (1) > Max_N or else Work'Length (2) > Max_N then
         raise Invalid_Argument with "dimension exceeds Max_N";
      end if;
      Result.Rows       := Work'Length (1);
      Result.Cols       := Work'Length (2);
      Result.Iterations := Iters;
      Result.Residual   := Resid;
      Result.Converged  := Conv;
      Result.Scaled     := [others => [others => 0.0]];
      Result.Row_Scale  := [others => 1.0];
      Result.Col_Scale  := [others => 1.0];
      RI := 1;
      for I in Work'Range (1) loop
         declare
            CJ : Positive := 1;
         begin
            for J in Work'Range (2) loop
               Result.Scaled (RI, CJ) := Work (I, J);
               CJ := CJ + 1;
            end loop;
         end;
         RI := RI + 1;
      end loop;
      for K in 1 .. Row_Sc'Length loop
         Result.Row_Scale (K) :=
           Row_Sc (Row_Sc'First + (K - 1));
      end loop;
      for K in 1 .. Col_Sc'Length loop
         Result.Col_Scale (K) :=
           Col_Sc (Col_Sc'First + (K - 1));
      end loop;
   end Pack_Into_Result;

   function Solve_Core
     (A           : Matrix;
      Row_Targets : Vector;
      Col_Targets : Vector;
      Epsilon     : Real;
      Max_Iter    : Natural) return Sinkhorn_Result
   is
      Work : Matrix (A'Range (1), A'Range (2));
      RSc  : Vector (1 .. A'Length (1)) := [others => 1.0];
      CSc  : Vector (1 .. A'Length (2)) := [others => 1.0];
      Res  : Real;
      Conv : Boolean := False;
      It   : Natural := 0;
      OutR : Sinkhorn_Result;
   begin
      Require_Nonempty (A);
      Require_Nonnegative (A);
      Require_Positive_Targets (Row_Targets);
      Require_Positive_Targets (Col_Targets);
      if A'Length (1) > Max_N or else A'Length (2) > Max_N then
         raise Invalid_Argument with "dimension exceeds Max_N";
      end if;
      if not Has_Positive_Row_Sums (A) then
         raise Invalid_Argument with "zero row prevents scaling";
      end if;
      if not Has_Positive_Col_Sums (A) then
         raise Invalid_Argument with "zero column prevents scaling";
      end if;

      Work := Copy_Matrix (A);
      Res  := Max_Marginal_Residual (Work, Row_Targets, Col_Targets);
      if Res <= Epsilon then
         Conv := True;
         Pack_Into_Result (Work, RSc, CSc, 0, Res, Conv, OutR);
         return OutR;
      end if;

      for Step in 1 .. Max_Iter loop
         --  Row scaling: accumulate into RSc, apply to Work.
         declare
            T : Positive := Row_Targets'First;
            K : Positive := 1;
         begin
            for I in Work'Range (1) loop
               declare
                  S : constant Real := Row_Sum (Work, I);
                  F : Real;
               begin
                  if S <= Zero_Tol then
                     raise Invalid_Argument with "zero row during Solve";
                  end if;
                  F := Row_Targets (T) / S;
                  RSc (K) := RSc (K) * F;
                  for J in Work'Range (2) loop
                     Work (I, J) := Work (I, J) * F;
                  end loop;
               end;
               K := K + 1;
               if T < Row_Targets'Last then
                  T := T + 1;
               end if;
            end loop;
         end;

         --  Column scaling: accumulate into CSc, apply to Work.
         declare
            T : Positive := Col_Targets'First;
            K : Positive := 1;
         begin
            for J in Work'Range (2) loop
               declare
                  S : constant Real := Col_Sum (Work, J);
                  F : Real;
               begin
                  if S <= Zero_Tol then
                     raise Invalid_Argument with "zero column during Solve";
                  end if;
                  F := Col_Targets (T) / S;
                  CSc (K) := CSc (K) * F;
                  for I in Work'Range (1) loop
                     Work (I, J) := Work (I, J) * F;
                  end loop;
               end;
               K := K + 1;
               if T < Col_Targets'Last then
                  T := T + 1;
               end if;
            end loop;
         end;

         It  := Step;
         Res := Max_Marginal_Residual (Work, Row_Targets, Col_Targets);
         if Res <= Epsilon then
            Conv := True;
            exit;
         end if;
      end loop;

      Pack_Into_Result (Work, RSc, CSc, It, Res, Conv, OutR);
      return OutR;
   end Solve_Core;

   function Solve
     (A        : Matrix;
      Epsilon  : Real := Default_Eps;
      Max_Iter : Natural := Default_Max_Iter) return Sinkhorn_Result
   is
   begin
      Require_Nonempty (A);
      if not Is_Square (A) then
         raise Invalid_Argument
           with "Solve toward DS requires a square matrix";
      end if;
      return Solve_Core
        (A,
         Ones_Vector (A'Length (1), 1.0),
         Ones_Vector (A'Length (2), 1.0),
         Epsilon,
         Max_Iter);
   end Solve;

   function Solve
     (A           : Matrix;
      Row_Targets : Vector;
      Col_Targets : Vector;
      Epsilon     : Real := Default_Eps;
      Max_Iter    : Natural := Default_Max_Iter) return Sinkhorn_Result
   is
   begin
      return Solve_Core (A, Row_Targets, Col_Targets, Epsilon, Max_Iter);
   end Solve;

   function Scaled_Matrix (R : Sinkhorn_Result) return Matrix is
      M : Matrix (1 .. R.Rows, 1 .. R.Cols);
   begin
      for I in 1 .. R.Rows loop
         for J in 1 .. R.Cols loop
            M (I, J) := R.Scaled (I, J);
         end loop;
      end loop;
      return M;
   end Scaled_Matrix;

begin
   null;
end Sinkhorn_Knopp_Algorithm;
