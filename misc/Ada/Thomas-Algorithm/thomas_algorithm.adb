--  Thomas_Algorithm body — O(n) TDMA forward sweep + back substitution.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Thomas_Algorithm
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Elementary_Functions;

   -------------------------------------------------------------------------
   -- Helpers
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

   function Norm2 (V : Vector) return Float is
      S : Float := 0.0;
   begin
      for X of V loop
         S := S + X * X;
      end loop;
      return Math.Sqrt (S);
   end Norm2;

   function Max_Abs (V : Vector) return Float is
      M : Float := 0.0;
   begin
      for X of V loop
         if abs (X) > M then
            M := abs (X);
         end if;
      end loop;
      return M;
   end Max_Abs;

   -------------------------------------------------------------------------
   -- Diagonal dominance
   -------------------------------------------------------------------------

   function Is_Diagonally_Dominant
     (A, B, C : Vector) return Boolean
   is
      N : constant Positive := B'Length;
      Lo : constant Positive := B'First;
   begin
      for K in 0 .. N - 1 loop
         declare
            I : constant Positive := Lo + K;
            Ai : constant Float :=
              (if K = 0 then 0.0 else A (A'First + K));
            Ci : constant Float :=
              (if K = N - 1 then 0.0 else C (C'First + K));
         begin
            if abs (B (I)) < abs (Ai) + abs (Ci) then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Diagonally_Dominant;

   function Is_Strictly_Diagonally_Dominant
     (A, B, C : Vector) return Boolean
   is
      N : constant Positive := B'Length;
      Lo : constant Positive := B'First;
   begin
      for K in 0 .. N - 1 loop
         declare
            I : constant Positive := Lo + K;
            Ai : constant Float :=
              (if K = 0 then 0.0 else A (A'First + K));
            Ci : constant Float :=
              (if K = N - 1 then 0.0 else C (C'First + K));
         begin
            if abs (B (I)) <= abs (Ai) + abs (Ci) then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Strictly_Diagonally_Dominant;

   -------------------------------------------------------------------------
   -- Residual
   -------------------------------------------------------------------------

   function Residual
     (A, B, C, D, X : Vector) return Vector
   is
      N  : constant Positive := X'Length;
      R  : Vector (1 .. N);
      Lo : constant Positive := X'First;
      --  Align A,B,C,D to the same offset indexing via Length.
      function At_A (K : Natural) return Float is
        (A (A'First + K));
      function At_B (K : Natural) return Float is
        (B (B'First + K));
      function At_C (K : Natural) return Float is
        (C (C'First + K));
      function At_D (K : Natural) return Float is
        (D (D'First + K));
      function At_X (K : Natural) return Float is
        (X (Lo + K));
   begin
      for K in 0 .. N - 1 loop
         declare
            S : Float := At_B (K) * At_X (K);
         begin
            if K > 0 then
               S := S + At_A (K) * At_X (K - 1);
            end if;
            if K < N - 1 then
               S := S + At_C (K) * At_X (K + 1);
            end if;
            R (K + 1) := At_D (K) - S;
         end;
      end loop;
      return R;
   end Residual;

   function Residual_Norm
     (A, B, C, D, X : Vector) return Float
   is
   begin
      return Norm2 (Residual (A, B, C, D, X));
   end Residual_Norm;

   function Residual_Max_Abs
     (A, B, C, D, X : Vector) return Float
   is
   begin
      return Max_Abs (Residual (A, B, C, D, X));
   end Residual_Max_Abs;

   -------------------------------------------------------------------------
   -- Builders
   -------------------------------------------------------------------------

   procedure Make_Poisson_1D
     (N : Dimension;
      A, B, C : out Vector)
   is
   begin
      for I in 1 .. N loop
         B (I) := 2.0;
         if I = 1 then
            A (I) := 0.0;
         else
            A (I) := -1.0;
         end if;
         if I = N then
            C (I) := 0.0;
         else
            C (I) := -1.0;
         end if;
      end loop;
   end Make_Poisson_1D;

   procedure Make_Poisson_1D_System
     (N : Dimension;
      A, B, C, D : out Vector;
      RHS_Value  : Float := 1.0)
   is
   begin
      Make_Poisson_1D (N, A, B, C);
      for I in 1 .. N loop
         D (I) := RHS_Value;
      end loop;
   end Make_Poisson_1D_System;

   procedure Make_Constant_Tridiagonal
     (N              : Dimension;
      Sub, Diag, Super : Float;
      A, B, C        : out Vector)
   is
   begin
      for I in 1 .. N loop
         B (I) := Diag;
         if I = 1 then
            A (I) := 0.0;
         else
            A (I) := Sub;
         end if;
         if I = N then
            C (I) := 0.0;
         else
            C (I) := Super;
         end if;
      end loop;
   end Make_Constant_Tridiagonal;

   function Zero_Vector (N : Dimension) return Vector is
      Z : constant Vector (1 .. N) := [others => 0.0];
   begin
      return Z;
   end Zero_Vector;

   function Ones_Vector (N : Dimension; Value : Float := 1.0) return Vector is
      O : constant Vector (1 .. N) := [others => Value];
   begin
      return O;
   end Ones_Vector;

   -------------------------------------------------------------------------
   -- Core TDMA
   -------------------------------------------------------------------------

   procedure Thomas_In_Place
     (A, B     : Vector;
      C, D     : in out Vector;
      X        : out Vector;
      Stat     : out Status;
      Pivot_At : out Dim_Index)
   is
      N  : constant Positive := X'Length;
      Lo : constant Positive := X'First;
      --  All vectors share First = Lo by precondition.
      Denom : Float;
   begin
      Stat     := Ok;
      Pivot_At := Dim_Index'First;
      X        := [others => 0.0];

      --  First row: c'_1 = c_1 / b_1, d'_1 = d_1 / b_1
      if abs (B (Lo)) <= Pivot_Tol then
         Stat     := Degenerate;
         Pivot_At := 1;
         return;
      end if;

      if N = 1 then
         X (Lo) := D (Lo) / B (Lo);
         return;
      end if;

      C (Lo) := C (Lo) / B (Lo);
      D (Lo) := D (Lo) / B (Lo);

      --  Forward sweep i = 2 .. n
      for I in Lo + 1 .. Lo + N - 1 loop
         Denom := B (I) - A (I) * C (I - 1);
         if abs (Denom) <= Pivot_Tol then
            Stat     := Degenerate;
            Pivot_At := I - Lo + 1;
            return;
         end if;
         if I < Lo + N - 1 then
            C (I) := C (I) / Denom;
         else
            C (I) := 0.0;  --  c_n unused
         end if;
         D (I) := (D (I) - A (I) * D (I - 1)) / Denom;
      end loop;

      --  Back substitution
      X (Lo + N - 1) := D (Lo + N - 1);
      for I in reverse Lo .. Lo + N - 2 loop
         X (I) := D (I) - C (I) * X (I + 1);
      end loop;
   end Thomas_In_Place;

   function Thomas
     (A, B, C, D : Vector) return Result
   is
      N : constant Positive := D'Length;
      --  Working copies aligned to 1 .. N
      Cw : Vector (1 .. N);
      Dw : Vector (1 .. N);
      Xw : Vector (1 .. N);
      R  : Result;
      St : Status;
      Pv : Dim_Index;
   begin
      if N > Max_N then
         R.Stat    := Size_Mismatch;
         R.Success := False;
         return R;
      end if;

      for K in 0 .. N - 1 loop
         Cw (K + 1) := C (C'First + K);
         Dw (K + 1) := D (D'First + K);
      end loop;

      --  Local A,B also 1 .. N for the in-place call
      declare
         Aw : Vector (1 .. N);
         Bw : Vector (1 .. N);
      begin
         for K in 0 .. N - 1 loop
            Aw (K + 1) := A (A'First + K);
            Bw (K + 1) := B (B'First + K);
         end loop;

         Thomas_In_Place (Aw, Bw, Cw, Dw, Xw, St, Pv);
      end;

      R.N       := N;
      R.Stat    := St;
      R.Pivot   := Pv;
      R.Success := St = Ok;
      if St = Ok then
         for I in 1 .. N loop
            R.X (I) := Xw (I);
         end loop;
      end if;
      return R;
   end Thomas;

   function Solve
     (A, B, C, D : Vector) return Result
   is
   begin
      return Thomas (A, B, C, D);
   end Solve;

end Thomas_Algorithm;
