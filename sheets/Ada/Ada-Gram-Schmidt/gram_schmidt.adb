--  Gram_Schmidt body — classical and modified orthonormalization.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Gram_Schmidt
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

   function Hash_IJ (I, J : Positive) return Float is
      --  Deterministic pseudo-random in roughly (−0.5, 0.5) from indices.
      R : constant Integer :=
        Integer ((I * 17 + J * 31) mod 97) - 48;
   begin
      return Float (R) / 100.0;
   end Hash_IJ;

   procedure Copy_Leading
     (Src    : Matrix;
      Dst    : in out Matrix;
      N, K   : Dimension)
   is
   begin
      for I in 1 .. N loop
         for J in 1 .. K loop
            Dst (I, J) := Src (Src'First (1) + I - 1,
                               Src'First (2) + J - 1);
         end loop;
      end loop;
   end Copy_Leading;

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
      AI : Positive := A'First;
      BI : Positive := B'First;
   begin
      for K in 1 .. A'Length loop
         if Abs_F (A (AI) - B (BI)) > Tol then
            return False;
         end if;
         AI := AI + 1;
         BI := BI + 1;
      end loop;
      return True;
   end Vec_Near;

   function Dot (U, V : Vector) return Float is
      S  : Float := 0.0;
      UI : Positive := U'First;
      VI : Positive := V'First;
   begin
      for K in 1 .. U'Length loop
         S := S + U (UI) * V (VI);
         UI := UI + 1;
         VI := VI + 1;
      end loop;
      return S;
   end Dot;

   function Norm2 (V : Vector) return Float is
   begin
      return EF.Sqrt (Dot (V, V));
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
      R  : Vector (1 .. U'Length);
      UI : Positive := U'First;
      VI : Positive := V'First;
   begin
      for K in 1 .. U'Length loop
         R (K) := U (UI) + V (VI);
         UI := UI + 1;
         VI := VI + 1;
      end loop;
      return R;
   end Add;

   function Sub (U, V : Vector) return Vector is
      R  : Vector (1 .. U'Length);
      UI : Positive := U'First;
      VI : Positive := V'First;
   begin
      for K in 1 .. U'Length loop
         R (K) := U (UI) - V (VI);
         UI := UI + 1;
         VI := VI + 1;
      end loop;
      return R;
   end Sub;

   function Proj (U, V : Vector) return Vector is
      Den : constant Float := Dot (U, U);
   begin
      if Den <= Epsilon_Tol then
         return Zero_Vector (U'Length);
      end if;
      return Scale (V => U, S => Dot (U, V) / Den);
   end Proj;

   function Column (A : Matrix; J : Positive) return Vector is
      R  : Vector (1 .. A'Length (1));
      RI : Positive := 1;
   begin
      for I in A'Range (1) loop
         R (RI) := A (I, J);
         RI := RI + 1;
      end loop;
      return R;
   end Column;

   procedure Set_Column
     (A : in out Matrix; J : Positive; V : Vector)
   is
      VI : Positive := V'First;
   begin
      for I in A'Range (1) loop
         A (I, J) := V (VI);
         VI := VI + 1;
      end loop;
   end Set_Column;

   function Orthonormality_Residual
     (Q : Matrix; N, Rank : Dimension; Tol : Float := Epsilon_Tol)
      return Float
   is
      pragma Unreferenced (Tol);
      Worst  : Float := 0.0;
      Acc    : Float;
      Diff   : Float;
      Target : Float;
      QI, QJ : Positive;
   begin
      if Rank = 0 then
         return 0.0;
      end if;
      for I in 1 .. Rank loop
         for J in 1 .. Rank loop
            Acc := 0.0;
            QI := Q'First (2) + I - 1;
            QJ := Q'First (2) + J - 1;
            for Row in 0 .. N - 1 loop
               Acc := Acc
                 + Q (Q'First (1) + Row, QI)
                 * Q (Q'First (1) + Row, QJ);
            end loop;
            if I = J then
               Target := 1.0;
            else
               Target := 0.0;
            end if;
            Diff := Abs_F (Acc - Target);
            if Diff > Worst then
               Worst := Diff;
            end if;
         end loop;
      end loop;
      return Worst;
   end Orthonormality_Residual;

   function Is_Orthonormal
     (Q : Matrix; N, Rank : Dimension; Tol : Float := 1.0E-5)
      return Boolean
   is
   begin
      return Orthonormality_Residual (Q, N, Rank) <= Tol;
   end Is_Orthonormal;

   -------------------------------------------------------------------------
   -- Builders
   -------------------------------------------------------------------------

   function Zero_Vector (N : Dimension) return Vector is
      R : constant Vector (1 .. N) := [others => 0.0];
   begin
      return R;
   end Zero_Vector;

   function Ones_Vector (N : Dimension; Value : Float := 1.0) return Vector is
      R : constant Vector (1 .. N) := [others => Value];
   begin
      return R;
   end Ones_Vector;

   function Standard_Basis (N : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         A (I, I) := 1.0;
      end loop;
      return A;
   end Standard_Basis;

   function Make_Independent (N, K : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. K) := [others => [others => 0.0]];
   begin
      for J in 1 .. K loop
         for I in 1 .. N loop
            if I = J then
               A (I, J) := Float (J) + 1.0;
            elsif I > J then
               A (I, J) := 0.2 * Float (I - J) + Hash_IJ (I, J);
            else
               A (I, J) := 0.05 * Hash_IJ (I, J);
            end if;
         end loop;
      end loop;
      return A;
   end Make_Independent;

   function Make_Dependent (N, K : Dimension) return Matrix is
      A : Matrix := Make_Independent (N, K);
   begin
      for I in 1 .. N loop
         A (I, K) := 0.0;
         for J in 1 .. K - 1 loop
            A (I, K) := A (I, K) + A (I, J);
         end loop;
      end loop;
      return A;
   end Make_Dependent;

   function Make_Hilbert_Columns (N, K : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. K);
   begin
      for I in 1 .. N loop
         for J in 1 .. K loop
            A (I, J) := 1.0 / Float (I + J - 1);
         end loop;
      end loop;
      return A;
   end Make_Hilbert_Columns;

   function Make_Orthogonal_Already (N, K : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. K) := [others => [others => 0.0]];
   begin
      for J in 1 .. K loop
         A (J, J) := 1.0;
      end loop;
      return A;
   end Make_Orthogonal_Already;

   function Make_Nearly_Dependent (N, K : Dimension) return Matrix is
      A : Matrix := Make_Independent (N, K);
   begin
      for I in 1 .. N loop
         A (I, K) := A (I, K - 1) + 1.0E-4 * (0.5 + Hash_IJ (I, K));
      end loop;
      return A;
   end Make_Nearly_Dependent;

   function Make_Example
     (Kind : Example_Kind; N : Dimension; K : Dimension := 0) return Matrix
   is
      KK : Dimension;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if K = 0 then
         KK := N;
      else
         KK := K;
      end if;
      if KK < 1 or else KK > N then
         raise Invalid_Argument;
      end if;

      case Kind is
         when Identity_Basis =>
            return Make_Orthogonal_Already (N, KK);
         when Independent_Set =>
            return Make_Independent (N, KK);
         when Dependent_Set =>
            if KK < 2 then
               raise Invalid_Argument;
            end if;
            return Make_Dependent (N, KK);
         when Hilbert_Columns =>
            return Make_Hilbert_Columns (N, KK);
         when Orthogonal_Already =>
            return Make_Orthogonal_Already (N, KK);
         when Nearly_Dependent =>
            if KK < 2 then
               raise Invalid_Argument;
            end if;
            return Make_Nearly_Dependent (N, KK);
      end case;
   end Make_Example;

   -------------------------------------------------------------------------
   -- Core orthonormalization
   -------------------------------------------------------------------------

   function Run_GS
     (V      : Matrix;
      Method : Method_Kind;
      Tol    : Float) return Result
   is
      N       : constant Dimension := V'Length (1);
      K       : constant Dimension := V'Length (2);
      R       : Result;
      Work    : Matrix (1 .. Max_N, 1 .. Max_N) :=
                  [others => [others => 0.0]];
      U       : Vector (1 .. N);
      Vj      : Vector (1 .. N);
      Coeff   : Float;
      Nv      : Float;
      Out_Col : Natural := 0;
   begin
      R.N := N;
      R.K := K;
      R.Method := Method;
      R.Rank := 0;
      R.Stat := Ill_Started;
      R.Success := False;

      --  Dimension bounds are enforced by the public Pre conditions.
      Copy_Leading (V, Work, N, K);

      for J in 1 .. K loop
         for I in 1 .. N loop
            U (I) := Work (I, J);
            Vj (I) := Work (I, J);
         end loop;

         if Method = Classical then
            --  u := v_j − Σ_i <v_j, q_i> q_i  (projections of original v_j)
            for Prev in 1 .. Out_Col loop
               Coeff := 0.0;
               for I in 1 .. N loop
                  Coeff := Coeff + Vj (I) * R.Q (I, Prev);
               end loop;
               for I in 1 .. N loop
                  U (I) := U (I) - Coeff * R.Q (I, Prev);
               end loop;
            end loop;
         else
            --  Modified: u := u − <u, q_i> q_i one-by-one (updated residual)
            for Prev in 1 .. Out_Col loop
               Coeff := 0.0;
               for I in 1 .. N loop
                  Coeff := Coeff + U (I) * R.Q (I, Prev);
               end loop;
               for I in 1 .. N loop
                  U (I) := U (I) - Coeff * R.Q (I, Prev);
               end loop;
            end loop;
         end if;

         Nv := Norm2 (U);
         declare
            Vnorm  : constant Float := Norm2 (Vj);
            Thresh : constant Float :=
              Tol * (if Vnorm > 1.0 then Vnorm else 1.0);
         begin
            if Nv > Thresh then
               Out_Col := Out_Col + 1;
               for I in 1 .. N loop
                  R.Q (I, Out_Col) := U (I) / Nv;
               end loop;
            end if;
         end;
      end loop;

      R.Rank := Out_Col;
      if Out_Col = 0 then
         R.Stat := Zero_Vector;
         R.Success := False;
      elsif Out_Col < K then
         R.Stat := Rank_Deficient;
         R.Success := True;
      else
         R.Stat := Ok;
         R.Success := True;
      end if;
      return R;
   end Run_GS;

   function Classical_GS
     (V : Matrix; Tol : Float := Rank_Tol) return Result
   is
   begin
      return Run_GS (V, Classical, Tol);
   end Classical_GS;

   function Modified_GS
     (V : Matrix; Tol : Float := Rank_Tol) return Result
   is
   begin
      return Run_GS (V, Modified, Tol);
   end Modified_GS;

   function Orthonormalize
     (V      : Matrix;
      Method : Method_Kind := Modified;
      Tol    : Float := Rank_Tol) return Result
   is
   begin
      return Run_GS (V, Method, Tol);
   end Orthonormalize;

end Gram_Schmidt;
