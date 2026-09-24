--  Gauss_Jordan body — educational Float Gauss–Jordan (RREF / inverse).

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Gauss_Jordan
  with SPARK_Mode => Off
is

   package EF renames Ada.Numerics.Elementary_Functions;

   --  Working augmented matrix: up to N rows × (N + N) cols for Invert,
   --  or N × (N+1) for Solve. Stored densely Max_N × (2*Max_N).
   subtype Aug_Col is Positive range 1 .. 2 * Max_N;
   type Aug_Matrix is array (Dim_Index, Aug_Col) of Float;

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

   procedure Swap_Aug_Rows
     (W : in out Aug_Matrix;
      R1, R2 : Positive;
      N_Cols : Positive)
   is
      Tmp : Float;
   begin
      if R1 = R2 then
         return;
      end if;
      for J in 1 .. N_Cols loop
         Tmp := W (R1, J);
         W (R1, J) := W (R2, J);
         W (R2, J) := Tmp;
      end loop;
   end Swap_Aug_Rows;

   --  Copy square A into leading N×N of Aug_Matrix.
   procedure Copy_A_Into
     (A : Matrix;
      N : Dimension;
      W : out Aug_Matrix)
   is
   begin
      W := [others => [others => 0.0]];
      for I in 1 .. N loop
         for J in 1 .. N loop
            W (I, J) := A (A'First (1) + (I - 1), A'First (2) + (J - 1));
         end loop;
      end loop;
   end Copy_A_Into;

   --  Core Gauss–Jordan on leading N×N of W with Extra_Cols extra
   --  right-hand columns (1 for Solve, N for Invert, 0 for RREF/det).
   --  For full-rank Solve/Invert: require a pivot in every column k=1..N
   --  (Strict mode). For Rank/RREF: Allow_Skip continues past zero cols.
   --  Records Det_Sign and Pivot_Product (product of pivots before scale).
   procedure Gauss_Jordan_Augmented
     (W             : in out Aug_Matrix;
      N             : Dimension;
      Extra_Cols    : Natural;
      Allow_Skip    : Boolean;
      Tol           : Float;
      Swap_Count    : in out Natural;
      Det_Sign      : in out Integer;
      Pivot_Product : in out Float;
      Rank_Out      : out Natural;
      Stat          : out Status)
   is
      N_Cols    : constant Positive := N + Extra_Cols;
      Pivot_Row : Positive;
      Best, Cand, Pivot, Factor : Float;
      Row : Natural := 1;
      Col : Natural := 1;
   begin
      Rank_Out := 0;
      Stat := Ok;

      if Allow_Skip then
         while Row <= N and then Col <= N loop
            Pivot_Row := Row;
            Best := Abs_F (W (Row, Col));
            for I in Row + 1 .. N loop
               Cand := Abs_F (W (I, Col));
               if Cand > Best then
                  Best := Cand;
                  Pivot_Row := I;
               end if;
            end loop;

            if Best <= Tol then
               Col := Col + 1;
            else
               if Pivot_Row /= Row then
                  Swap_Aug_Rows (W, Row, Pivot_Row, N_Cols);
                  Swap_Count := Swap_Count + 1;
                  Det_Sign := -Det_Sign;
               end if;

               Pivot := W (Row, Col);
               Pivot_Product := Pivot_Product * Pivot;

               --  Scale pivot row so pivot = 1.
               for J in Col .. N_Cols loop
                  W (Row, J) := W (Row, J) / Pivot;
               end loop;
               W (Row, Col) := 1.0;

               --  Eliminate above and below.
               for I in 1 .. N loop
                  if I /= Row then
                     Factor := W (I, Col);
                     if Abs_F (Factor) > 0.0 then
                        for J in Col .. N_Cols loop
                           W (I, J) := W (I, J) - Factor * W (Row, J);
                        end loop;
                        W (I, Col) := 0.0;
                     end if;
                  end if;
               end loop;

               Rank_Out := Rank_Out + 1;
               Row := Row + 1;
               Col := Col + 1;
            end if;
         end loop;

         if Rank_Out < N then
            Stat := Singular;
         else
            Stat := Ok;
         end if;
      else
         --  Strict: one pivot per diagonal column (Solve / Invert / Det).
         for K in 1 .. N loop
            Pivot_Row := K;
            Best := Abs_F (W (K, K));
            for I in K + 1 .. N loop
               Cand := Abs_F (W (I, K));
               if Cand > Best then
                  Best := Cand;
                  Pivot_Row := I;
               end if;
            end loop;

            if Best <= Tol then
               Stat := Singular;
               Rank_Out := K - 1;
               return;
            end if;

            if Pivot_Row /= K then
               Swap_Aug_Rows (W, K, Pivot_Row, N_Cols);
               Swap_Count := Swap_Count + 1;
               Det_Sign := -Det_Sign;
            end if;

            Pivot := W (K, K);
            if Abs_F (Pivot) <= Tol then
               Stat := Zero_Pivot;
               Rank_Out := K - 1;
               return;
            end if;

            Pivot_Product := Pivot_Product * Pivot;

            for J in K .. N_Cols loop
               W (K, J) := W (K, J) / Pivot;
            end loop;
            W (K, K) := 1.0;

            for I in 1 .. N loop
               if I /= K then
                  Factor := W (I, K);
                  if Abs_F (Factor) > 0.0 then
                     for J in K .. N_Cols loop
                        W (I, J) := W (I, J) - Factor * W (K, J);
                     end loop;
                     W (I, K) := 0.0;
                  end if;
               end if;
            end loop;

            Rank_Out := Rank_Out + 1;
         end loop;
         Stat := Ok;
      end if;
   end Gauss_Jordan_Augmented;

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

   function Mat_Near
     (A, B : Matrix; Tol : Float := Epsilon_Tol) return Boolean
   is
      Nr : constant Natural := A'Length (1);
      Nc : constant Natural := A'Length (2);
   begin
      for I in 0 .. Nr - 1 loop
         for J in 0 .. Nc - 1 loop
            if Abs_F
                 (A (A'First (1) + I, A'First (2) + J)
                  - B (B'First (1) + I, B'First (2) + J)) > Tol
            then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Mat_Near;

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

   function Mat_Mul (A, B : Matrix) return Matrix is
      N : constant Dimension := A'Length (1);
      C : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      S : Float;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            S := 0.0;
            for K in 1 .. N loop
               S := S
                 + A (A'First (1) + (I - 1), A'First (2) + (K - 1))
                 * B (B'First (1) + (K - 1), B'First (2) + (J - 1));
            end loop;
            C (I, J) := S;
         end loop;
      end loop;
      return C;
   end Mat_Mul;

   function Is_Square (A : Matrix) return Boolean is
   begin
      return A'Length (1) = A'Length (2);
   end Is_Square;

   function Is_Diagonally_Dominant (A : Matrix) return Boolean is
      N    : constant Dimension := A'Length (1);
      Off  : Float;
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
      N    : constant Dimension := A'Length (1);
      Off  : Float;
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

   function Inverse_Residual_Max_Abs
     (A, Inv : Matrix) return Float
   is
      N    : constant Dimension := A'Length (1);
      InvN : constant Matrix := Leading_Square (Inv, N);
      Prod : constant Matrix := Mat_Mul (A, InvN);
      M    : Float := 0.0;
      Diff : Float;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I = J then
               Diff := Abs_F (Prod (I, J) - 1.0);
            else
               Diff := Abs_F (Prod (I, J));
            end if;
            if Diff > M then
               M := Diff;
            end if;
         end loop;
      end loop;
      return M;
   end Inverse_Residual_Max_Abs;

   function Leading_Square (A : Matrix; N : Dimension) return Matrix is
      R : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) := A (A'First (1) + (I - 1), A'First (2) + (J - 1));
         end loop;
      end loop;
      return R;
   end Leading_Square;

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
      A   : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      Off : Float;
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
            declare
               A : constant Matrix (1 .. 2, 1 .. 2) :=
                 [[2.0, 1.0], [1.0, 2.0]];
            begin
               return A;
            end;
         when Example_3x3 =>
            declare
               A : constant Matrix (1 .. 3, 1 .. 3) :=
                 [[2.0, 1.0, 0.0],
                  [1.0, 4.0, 1.0],
                  [0.0, 1.0, 2.0]];
            begin
               return A;
            end;
         when Needs_Pivot =>
            declare
               A : constant Matrix (1 .. 2, 1 .. 2) :=
                 [[0.0, 1.0], [1.0, 0.0]];
            begin
               return A;
            end;
         when Singular_2x2 =>
            declare
               A : constant Matrix (1 .. 2, 1 .. 2) :=
                 [[1.0, 2.0], [2.0, 4.0]];
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
   -- Solve / Invert / RREF
   -------------------------------------------------------------------------

   function Solve (A : Matrix; B : Vector) return Result is
      N             : constant Dimension := B'Length;
      W             : Aug_Matrix;
      R             : Result;
      Swap_Count    : Natural := 0;
      Det_Sign      : Integer := 1;
      Pivot_Product : Float := 1.0;
      Rank_Out      : Natural;
      Stat          : Status;
   begin
      R.N := N;
      Copy_A_Into (A, N, W);
      for I in 1 .. N loop
         W (I, N + 1) := B (B'First + (I - 1));
      end loop;

      Gauss_Jordan_Augmented
        (W, N, Extra_Cols => 1, Allow_Skip => False, Tol => Pivot_Tol,
         Swap_Count => Swap_Count, Det_Sign => Det_Sign,
         Pivot_Product => Pivot_Product, Rank_Out => Rank_Out, Stat => Stat);

      R.Swap_Count := Swap_Count;
      R.Stat := Stat;
      if Stat = Ok then
         for I in 1 .. N loop
            R.X (I) := W (I, N + 1);
         end loop;
         R.Success := True;
      else
         R.Success := False;
      end if;
      return R;
   end Solve;

   function Invert (A : Matrix) return Invert_Result is
      N             : constant Dimension := A'Length (1);
      W             : Aug_Matrix;
      R             : Invert_Result;
      Swap_Count    : Natural := 0;
      Det_Sign      : Integer := 1;
      Pivot_Product : Float := 1.0;
      Rank_Out      : Natural;
      Stat          : Status;
   begin
      R.N := N;
      Copy_A_Into (A, N, W);
      --  Augment with identity on the right.
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I = J then
               W (I, N + J) := 1.0;
            else
               W (I, N + J) := 0.0;
            end if;
         end loop;
      end loop;

      Gauss_Jordan_Augmented
        (W, N, Extra_Cols => N, Allow_Skip => False, Tol => Pivot_Tol,
         Swap_Count => Swap_Count, Det_Sign => Det_Sign,
         Pivot_Product => Pivot_Product, Rank_Out => Rank_Out, Stat => Stat);

      R.Swap_Count := Swap_Count;
      R.Stat := Stat;
      if Stat = Ok then
         for I in 1 .. N loop
            for J in 1 .. N loop
               R.Inv (I, J) := W (I, N + J);
            end loop;
         end loop;
         R.Success := True;
      else
         R.Success := False;
      end if;
      return R;
   end Invert;

   function Reduce_To_RREF (A : Matrix) return RREF_Result is
      N             : constant Dimension := A'Length (1);
      W             : Aug_Matrix;
      R             : RREF_Result;
      Swap_Count    : Natural := 0;
      Det_Sign      : Integer := 1;
      Pivot_Product : Float := 1.0;
      Rank_Out      : Natural;
      Stat          : Status;
   begin
      R.N := N;
      Copy_A_Into (A, N, W);

      Gauss_Jordan_Augmented
        (W, N, Extra_Cols => 0, Allow_Skip => True, Tol => Pivot_Tol,
         Swap_Count => Swap_Count, Det_Sign => Det_Sign,
         Pivot_Product => Pivot_Product, Rank_Out => Rank_Out, Stat => Stat);

      R.Swap_Count := Swap_Count;
      R.Rank_Value := Rank_Out;
      R.Stat := Stat;
      --  Reduction always "succeeds" as a process; Success marks completion.
      R.Success := True;
      for I in 1 .. N loop
         for J in 1 .. N loop
            R.R (I, J) := W (I, J);
         end loop;
      end loop;
      return R;
   end Reduce_To_RREF;

   -------------------------------------------------------------------------
   -- Determinant and rank
   -------------------------------------------------------------------------

   procedure Determinant
     (A    : Matrix;
      Det  : out Float;
      Stat : out Status)
   is
      N             : constant Dimension := A'Length (1);
      W             : Aug_Matrix;
      Swap_Count    : Natural := 0;
      Det_Sign      : Integer := 1;
      Pivot_Product : Float := 1.0;
      Rank_Out      : Natural;
   begin
      Copy_A_Into (A, N, W);
      Gauss_Jordan_Augmented
        (W, N, Extra_Cols => 0, Allow_Skip => False, Tol => Pivot_Tol,
         Swap_Count => Swap_Count, Det_Sign => Det_Sign,
         Pivot_Product => Pivot_Product, Rank_Out => Rank_Out, Stat => Stat);
      if Stat /= Ok then
         Det := 0.0;
         return;
      end if;
      Det := Float (Det_Sign) * Pivot_Product;
      Stat := Ok;
   end Determinant;

   function Determinant (A : Matrix) return Float is
      Det  : Float;
      Stat : Status;
   begin
      Determinant (A, Det, Stat);
      return Det;
   end Determinant;

   function Rank
     (A : Matrix; Tol : Float := Pivot_Tol) return Natural
   is
      N             : constant Dimension := A'Length (1);
      W             : Aug_Matrix;
      Swap_Count    : Natural := 0;
      Det_Sign      : Integer := 1;
      Pivot_Product : Float := 1.0;
      Rank_Out      : Natural;
      Stat          : Status;
   begin
      Copy_A_Into (A, N, W);
      Gauss_Jordan_Augmented
        (W, N, Extra_Cols => 0, Allow_Skip => True, Tol => Tol,
         Swap_Count => Swap_Count, Det_Sign => Det_Sign,
         Pivot_Product => Pivot_Product, Rank_Out => Rank_Out, Stat => Stat);
      return Rank_Out;
   end Rank;

end Gauss_Jordan;
