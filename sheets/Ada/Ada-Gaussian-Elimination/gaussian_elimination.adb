--  Gaussian_Elimination body — GEPP educational Float implementation.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Gaussian_Elimination
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

   --  Core GEPP on working copies U, B of size N. Updates Swap_Count / Det_Sign.
   procedure Forward_Eliminate
     (U          : in out Matrix;
      B          : in out Vector;
      N          : Dimension;
      Swap_Count : in out Natural;
      Det_Sign   : in out Integer;
      Stat       : out Status)
   is
      Pivot_Row : Positive;
      Best      : Float;
      Cand      : Float;
      Mult      : Float;
      Pivot     : Float;
   begin
      Stat := Ok;
      for K in 1 .. N loop
         --  Partial pivoting: largest |entry| in column K from rows K..N.
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
            Stat := Singular;
            return;
         end if;

         if Pivot_Row /= K then
            Swap_Rows (U, B, K, Pivot_Row, N);
            Swap_Count := Swap_Count + 1;
            Det_Sign := -Det_Sign;
         end if;

         Pivot := U (K, K);
         if Abs_F (Pivot) <= Pivot_Tol then
            Stat := Zero_Pivot;
            return;
         end if;

         --  Eliminate below pivot (skip when K = N).
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
   end Forward_Eliminate;

   function Copy_Matrix (A : Matrix; N : Dimension) return Matrix is
      U : Matrix (1 .. Max_N, 1 .. Max_N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            U (I, J) := A (A'First (1) + (I - 1), A'First (2) + (J - 1));
         end loop;
      end loop;
      return U;
   end Copy_Matrix;

   function Copy_Vector (V : Vector; N : Dimension) return Vector is
      B : Vector (1 .. Max_N) := [others => 0.0];
   begin
      for I in 1 .. N loop
         B (I) := V (V'First + (I - 1));
      end loop;
      return B;
   end Copy_Vector;

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

   function Norm2 (V : Vector) return Float is
      S : Float := 0.0;
   begin
      for X of V loop
         S := S + X * X;
      end loop;
      return EF.Sqrt (S);
   end Norm2;

   function Max_Abs (V : Vector) return Float is
      M : Float := 0.0;
   begin
      for X of V loop
         if Abs_F (X) > M then
            M := Abs_F (X);
         end if;
      end loop;
      return M;
   end Max_Abs;

   function Dot (U, V : Vector) return Float is
      S : Float := 0.0;
   begin
      for I in U'Range loop
         S := S + U (I) * V (V'First + (I - U'First));
      end loop;
      return S;
   end Dot;

   function Mat_Vec (A : Matrix; X : Vector) return Vector is
      N : constant Dimension := A'Length (1);
      Y : Vector (1 .. N) := [others => 0.0];
      S : Float;
   begin
      for I in 1 .. N loop
         S := 0.0;
         for J in 1 .. N loop
            S := S
              + A (A'First (1) + (I - 1), A'First (2) + (J - 1))
              * X (X'First + (J - 1));
         end loop;
         Y (I) := S;
      end loop;
      return Y;
   end Mat_Vec;

   function Is_Square (A : Matrix) return Boolean is
   begin
      return A'Length (1) = A'Length (2);
   end Is_Square;

   function Is_Diagonally_Dominant (A : Matrix) return Boolean is
      N : constant Dimension := A'Length (1);
      Off : Float;
      Diag : Float;
   begin
      for I in 1 .. N loop
         Off := 0.0;
         Diag := Abs_F
           (A (A'First (1) + (I - 1), A'First (2) + (I - 1)));
         for J in 1 .. N loop
            if J /= I then
               Off := Off
                 + Abs_F
                     (A (A'First (1) + (I - 1), A'First (2) + (J - 1)));
            end if;
         end loop;
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
         Diag := Abs_F
           (A (A'First (1) + (I - 1), A'First (2) + (I - 1)));
         for J in 1 .. N loop
            if J /= I then
               Off := Off
                 + Abs_F
                     (A (A'First (1) + (I - 1), A'First (2) + (J - 1)));
            end if;
         end loop;
         if Diag <= Off then
            return False;
         end if;
      end loop;
      return True;
   end Is_Strictly_Diagonally_Dominant;

   -------------------------------------------------------------------------
   -- Residual
   -------------------------------------------------------------------------

   function Residual (A : Matrix; X, B : Vector) return Vector is
      Ax : constant Vector := Mat_Vec (A, X);
      N  : constant Dimension := X'Length;
      R  : Vector (1 .. N);
   begin
      for I in 1 .. N loop
         R (I) := B (B'First + (I - 1)) - Ax (I);
      end loop;
      return R;
   end Residual;

   function Residual_Norm (A : Matrix; X, B : Vector) return Float is
   begin
      return Norm2 (Residual (A, X, B));
   end Residual_Norm;

   function Residual_Max_Abs (A : Matrix; X, B : Vector) return Float is
   begin
      return Max_Abs (Residual (A, X, B));
   end Residual_Max_Abs;

   -------------------------------------------------------------------------
   -- Builders
   -------------------------------------------------------------------------

   function Zero_Vector (N : Dimension) return Vector is
      V : constant Vector (1 .. N) := [others => 0.0];
   begin
      return V;
   end Zero_Vector;

   function Ones_Vector (N : Dimension; Value : Float := 1.0) return Vector is
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

   function Make_Diagonally_Dominant
     (N : Dimension; Extra : Float := 1.0) return Matrix
   is
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      Off : Float;
      --  Deterministic pseudo-random-ish off-diagonals in (−1,1).
      function Hash (I, J : Positive) return Float is
         K : constant Integer := (37 * I + 17 * J + 11) mod 200 - 100;
      begin
         return Float (K) / 100.0;
      end Hash;
   begin
      for I in 1 .. N loop
         Off := 0.0;
         for J in 1 .. N loop
            if I /= J then
               A (I, J) := Hash (I, J);
               Off := Off + Abs_F (A (I, J));
            end if;
         end loop;
         A (I, I) := Off + Extra;
      end loop;
      return A;
   end Make_Diagonally_Dominant;

   function Make_Hilbert (N : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            A (I, J) := 1.0 / Float (I + J - 1);
         end loop;
      end loop;
      return A;
   end Make_Hilbert;

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

   function Make_Example (Kind : Example_Kind; N : Dimension := 0)
     return Matrix
   is
   begin
      case Kind is
         when Identity =>
            if N < 1 then
               raise Invalid_Argument;
            end if;
            return Identity (N);
         when Diag_Dominant =>
            if N < 1 then
               raise Invalid_Argument;
            end if;
            return Make_Diagonally_Dominant (N);
         when Hilbert_Tiny =>
            if N < 1 then
               raise Invalid_Argument;
            end if;
            return Make_Hilbert (N);
         when Poisson_1D =>
            if N < 1 then
               raise Invalid_Argument;
            end if;
            return Make_Poisson_1D (N);
         when Example_2x2 =>
            --  [2 1; 1 2]
            declare
               A : constant Matrix (1 .. 2, 1 .. 2) :=
                 [[2.0, 1.0], [1.0, 2.0]];
            begin
               return A;
            end;
         when Example_3x3 =>
            --  [2 1 0; 1 4 1; 0 1 2]  SPD / DD
            declare
               A : constant Matrix (1 .. 3, 1 .. 3) :=
                 [[2.0, 1.0, 0.0],
                  [1.0, 4.0, 1.0],
                  [0.0, 1.0, 2.0]];
            begin
               return A;
            end;
         when Needs_Pivot =>
            --  First pivot zero without swap: [0 1; 1 0]
            declare
               A : constant Matrix (1 .. 2, 1 .. 2) :=
                 [[0.0, 1.0], [1.0, 0.0]];
            begin
               return A;
            end;
      end case;
   end Make_Example;

   function Make_RHS_Ones
     (N : Dimension; Value : Float := 1.0) return Vector
   is
   begin
      return Ones_Vector (N, Value);
   end Make_RHS_Ones;

   function Make_RHS_From_Solution
     (A : Matrix; X : Vector) return Vector
   is
   begin
      return Mat_Vec (A, X);
   end Make_RHS_From_Solution;

   -------------------------------------------------------------------------
   -- Factor / Eliminate
   -------------------------------------------------------------------------

   function Factor (A : Matrix; B : Vector) return Factor_Result is
      N : constant Dimension := B'Length;
      F : Factor_Result;
   begin
      --  Preconditions already enforce square A, matching lengths, 1..Max_N.
      F.U := Copy_Matrix (A, N);
      F.B := Copy_Vector (B, N);
      F.N := N;
      F.Swap_Count := 0;
      F.Det_Sign := 1;
      Forward_Eliminate
        (F.U, F.B, N, F.Swap_Count, F.Det_Sign, F.Stat);
      F.Success := F.Stat = Ok;
      return F;
   end Factor;

   function Eliminate (A : Matrix; B : Vector) return Factor_Result is
   begin
      return Factor (A, B);
   end Eliminate;

   function Factor_Matrix (A : Matrix) return Factor_Result is
      N : constant Dimension := A'Length (1);
      Z : constant Vector := Zero_Vector (N);
   begin
      return Factor (A, Z);
   end Factor_Matrix;

   -------------------------------------------------------------------------
   -- Back substitution and solve
   -------------------------------------------------------------------------

   function Back_Substitute (F : Factor_Result) return Result is
      R : Result;
      N : constant Dimension := F.N;
      S : Float;
      Pivot : Float;
   begin
      R.N := N;
      R.Swap_Count := F.Swap_Count;
      if not F.Success or else F.Stat /= Ok then
         R.Stat := F.Stat;
         if R.Stat = Ill_Started then
            R.Stat := Singular;
         end if;
         R.Success := False;
         return R;
      end if;

      for I in reverse 1 .. N loop
         S := F.B (I);
         for J in I + 1 .. N loop
            S := S - F.U (I, J) * R.X (J);
         end loop;
         Pivot := F.U (I, I);
         if Abs_F (Pivot) <= Pivot_Tol then
            R.Stat := Zero_Pivot;
            R.Success := False;
            return R;
         end if;
         R.X (I) := S / Pivot;
      end loop;

      R.Stat := Ok;
      R.Success := True;
      return R;
   end Back_Substitute;

   function Solve (A : Matrix; B : Vector) return Result is
      F : constant Factor_Result := Factor (A, B);
   begin
      return Back_Substitute (F);
   end Solve;

   -------------------------------------------------------------------------
   -- Determinant and rank
   -------------------------------------------------------------------------

   procedure Determinant
     (A    : Matrix;
      Det  : out Float;
      Stat : out Status)
   is
      F : Factor_Result;
      Prod : Float;
   begin
      F := Factor_Matrix (A);
      Stat := F.Stat;
      if not F.Success then
         Det := 0.0;
         return;
      end if;
      Prod := Float (F.Det_Sign);
      for I in 1 .. F.N loop
         Prod := Prod * F.U (I, I);
      end loop;
      Det := Prod;
      Stat := Ok;
   end Determinant;

   function Determinant (A : Matrix) return Float is
      Det : Float;
      Stat : Status;
   begin
      Determinant (A, Det, Stat);
      return Det;
   end Determinant;

   function Rank
     (A : Matrix; Tol : Float := Pivot_Tol) return Natural
   is
      Count : Natural := 0;
      N : constant Dimension := A'Length (1);
      U : Matrix (1 .. Max_N, 1 .. Max_N) := [others => [others => 0.0]];
      Dummy_B : Vector (1 .. Max_N) := [others => 0.0];
      Pivot_Row : Positive;
      Best, Cand, Mult, Pivot : Float;
      Row : Natural := 1;
      Col : Natural := 1;
   begin
      --  Rank via GEPP that continues past tiny pivots (skip column).
      for I in 1 .. N loop
         for J in 1 .. N loop
            U (I, J) := A (A'First (1) + (I - 1), A'First (2) + (J - 1));
         end loop;
      end loop;

      while Row <= N and then Col <= N loop
         Pivot_Row := Row;
         Best := Abs_F (U (Row, Col));
         for I in Row + 1 .. N loop
            Cand := Abs_F (U (I, Col));
            if Cand > Best then
               Best := Cand;
               Pivot_Row := I;
            end if;
         end loop;

         if Best <= Tol then
            --  No pivot in this column; move to next column.
            Col := Col + 1;
         else
            if Pivot_Row /= Row then
               Swap_Rows (U, Dummy_B, Row, Pivot_Row, N);
            end if;
            Pivot := U (Row, Col);
            for I in Row + 1 .. N loop
               Mult := U (I, Col) / Pivot;
               U (I, Col) := 0.0;
               for J in Col + 1 .. N loop
                  U (I, J) := U (I, J) - Mult * U (Row, J);
               end loop;
            end loop;
            Count := Count + 1;
            Row := Row + 1;
            Col := Col + 1;
         end if;
      end loop;

      return Count;
   end Rank;

end Gaussian_Elimination;
