--  QR_Algorithm body — MGS QR + unshifted (optional Wilkinson) QR iteration.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body QR_Algorithm
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

   function Copy_Square (A : Matrix; N : Dimension) return Matrix is
      B : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            B (I, J) :=
              A (A'First (1) + (I - 1), A'First (2) + (J - 1));
         end loop;
      end loop;
      return B;
   end Copy_Square;

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

   function Mat_Mul (A, B : Matrix) return Matrix is
      N_Rows : constant Natural := A'Length (1);
      N_Cols : constant Natural := B'Length (2);
      K_Len  : constant Natural := A'Length (2);
      C      : Matrix (1 .. N_Rows, 1 .. N_Cols) :=
                 [others => [others => 0.0]];
      S      : Float;
   begin
      for I in 1 .. N_Rows loop
         for J in 1 .. N_Cols loop
            S := 0.0;
            for K in 1 .. K_Len loop
               S := S
                 + A (A'First (1) + (I - 1), A'First (2) + (K - 1))
                 * B (B'First (1) + (K - 1), B'First (2) + (J - 1));
            end loop;
            C (I, J) := S;
         end loop;
      end loop;
      return C;
   end Mat_Mul;

   function Mat_Transpose (A : Matrix) return Matrix is
      N_Rows : constant Natural := A'Length (1);
      N_Cols : constant Natural := A'Length (2);
      T      : Matrix (1 .. N_Cols, 1 .. N_Rows);
   begin
      for I in 1 .. N_Rows loop
         for J in 1 .. N_Cols loop
            T (J, I) :=
              A (A'First (1) + (I - 1), A'First (2) + (J - 1));
         end loop;
      end loop;
      return T;
   end Mat_Transpose;

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

   function Identity (N : Dimension) return Matrix is
      Iden : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         Iden (I, I) := 1.0;
      end loop;
      return Iden;
   end Identity;

   function Column (A : Matrix; J : Positive) return Vector is
      V : Vector (A'Range (1));
   begin
      for I in A'Range (1) loop
         V (I) := A (I, J);
      end loop;
      return V;
   end Column;

   procedure Set_Column
     (A : in out Matrix; J : Positive; V : Vector)
   is
   begin
      for I in A'Range (1) loop
         A (I, J) := V (V'First + (I - A'First (1)));
      end loop;
   end Set_Column;

   function Off_Diag_Norm (A : Matrix) return Float is
      S : Float := 0.0;
      N : constant Dimension := A'Length (1);
      AIJ : Float;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I /= J then
               AIJ :=
                 A (A'First (1) + (I - 1), A'First (2) + (J - 1));
               S := S + AIJ * AIJ;
            end if;
         end loop;
      end loop;
      return Math.Sqrt (S);
   end Off_Diag_Norm;

   function Trace (A : Matrix) return Float is
      S : Float := 0.0;
      N : constant Dimension := A'Length (1);
   begin
      for I in 1 .. N loop
         S := S
           + A (A'First (1) + (I - 1), A'First (2) + (I - 1));
      end loop;
      return S;
   end Trace;

   function Frobenius_Norm (A : Matrix) return Float is
      S : Float := 0.0;
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            S := S + A (I, J) * A (I, J);
         end loop;
      end loop;
      return Math.Sqrt (S);
   end Frobenius_Norm;

   function Orthogonality_Residual
     (Q : Matrix; N : Dimension) return Float
   is
      Max_Dev : Float := 0.0;
      S, Target, Dev : Float;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            S := 0.0;
            for K in 1 .. N loop
               S := S
                 + Q (Q'First (1) + (K - 1), Q'First (2) + (I - 1))
                 * Q (Q'First (1) + (K - 1), Q'First (2) + (J - 1));
            end loop;
            if I = J then
               Target := 1.0;
            else
               Target := 0.0;
            end if;
            Dev := Abs_F (S - Target);
            if Dev > Max_Dev then
               Max_Dev := Dev;
            end if;
         end loop;
      end loop;
      return Max_Dev;
   end Orthogonality_Residual;

   -------------------------------------------------------------------------
   -- Builders
   -------------------------------------------------------------------------

   function Hash_IJ (I, J : Natural) return Float is
      X : constant Natural := (I * 17 + J * 31) mod 1000;
   begin
      return Float (X) / 1000.0;
   end Hash_IJ;

   function Make_Diagonal (Eigs : Vector) return Matrix is
      N : constant Dimension := Eigs'Length;
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         A (I, I) := Eigs (Eigs'First + (I - 1));
      end loop;
      return A;
   end Make_Diagonal;

   --  Deterministic full-rank matrix for MGS → orthonormal Q.
   function Make_Independent (N : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I = J then
               A (I, J) := 1.0 + 0.1 * Float (I);
            elsif I > J then
               A (I, J) := 0.2 + Hash_IJ (I, J);
            else
               A (I, J) := 0.05 * Hash_IJ (I, J);
            end if;
         end loop;
      end loop;
      return A;
   end Make_Independent;

   function Make_Symmetric_Known (Eigs : Vector) return Matrix is
      N   : constant Dimension := Eigs'Length;
      D   : constant Matrix := Make_Diagonal (Eigs);
      Raw : constant Matrix := Make_Independent (N);
      Fac : constant QR_Result := QR_Factor (Raw);
      Q   : Matrix (1 .. N, 1 .. N);
      Qt  : Matrix (1 .. N, 1 .. N);
      Tmp : Matrix (1 .. N, 1 .. N);
   begin
      if not Fac.Success then
         --  Fallback: return diagonal (still correct spectrum).
         return D;
      end if;
      for I in 1 .. N loop
         for J in 1 .. N loop
            Q (I, J) := Fac.Q (I, J);
         end loop;
      end loop;
      Qt := Mat_Transpose (Q);
      Tmp := Mat_Mul (Q, D);
      return Mat_Mul (Tmp, Qt);
   end Make_Symmetric_Known;

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

   function Make_Symmetric_Randomish (N : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. N);
      V : Float;
   begin
      for I in 1 .. N loop
         for J in I .. N loop
            V := 0.3 + Hash_IJ (I, J);
            if I = J then
               V := V + Float (N);  -- diagonally dominant → SPD-ish
            end if;
            A (I, J) := V;
            A (J, I) := V;
         end loop;
      end loop;
      return A;
   end Make_Symmetric_Randomish;

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
         when Hilbert_Tiny =>
            return Make_Hilbert (N);
         when Symmetric_Known =>
            for I in 1 .. N loop
               Eigs (I) := Float (I);
            end loop;
            return Make_Symmetric_Known (Eigs);
         when Symmetric_Randomish =>
            return Make_Symmetric_Randomish (N);
      end case;
   end Make_Example;

   function Poisson_Eigenvalue
     (N : Dimension; K : Dim_Index) return Float
   is
      --  λ_k = 2 − 2 cos(k π / (N+1))
      Arg : constant Float :=
        Float (K) * Ada.Numerics.Pi / Float (N + 1);
   begin
      return 2.0 - 2.0 * Math.Cos (Arg);
   end Poisson_Eigenvalue;

   -------------------------------------------------------------------------
   -- QR factorization via Modified Gram–Schmidt
   -------------------------------------------------------------------------

   function QR_Factor (A : Matrix) return QR_Result is
      N   : constant Dimension := A'Length (1);
      Res : QR_Result;
      Work : Matrix (1 .. N, 1 .. N);
      U    : Vector (1 .. N);
      Coeff, Nv : Float;
   begin
      Res.N := N;
      Res.Stat := Ill_Started;
      Res.Success := False;
      Res.Q := [others => [others => 0.0]];
      Res.R := [others => [others => 0.0]];

      Work := Copy_Square (A, N);

      for J in 1 .. N loop
         for I in 1 .. N loop
            U (I) := Work (I, J);
         end loop;

         --  Modified GS: subtract projections against prior q_i
         for Prev in 1 .. J - 1 loop
            Coeff := 0.0;
            for I in 1 .. N loop
               Coeff := Coeff + U (I) * Res.Q (I, Prev);
            end loop;
            Res.R (Prev, J) := Coeff;
            for I in 1 .. N loop
               U (I) := U (I) - Coeff * Res.Q (I, Prev);
            end loop;
         end loop;

         Nv := Norm2 (U);
         Res.R (J, J) := Nv;
         if Nv <= Rank_Tol then
            Res.Stat := Rank_Deficient;
            Res.Success := False;
            return Res;
         end if;

         for I in 1 .. N loop
            Res.Q (I, J) := U (I) / Nv;
         end loop;
      end loop;

      Res.Stat := Ok;
      Res.Success := True;
      return Res;
   end QR_Factor;

   -------------------------------------------------------------------------
   -- Wilkinson shift (trailing 2×2)
   -------------------------------------------------------------------------

   function Wilkinson_Shift (A : Matrix) return Float is
      N : constant Dimension := A'Length (1);
      A_NN, A_NM, A_MM, B, C, Disc, Root1, Root2, Mu : Float;
      R1, C1, R2, C2 : Positive;
   begin
      --  Trailing block [[a_mm, a_mn],[a_nm, a_nn]] with m=N-1, n=N
      R1 := A'First (1) + (N - 2);
      C1 := A'First (2) + (N - 2);
      R2 := A'First (1) + (N - 1);
      C2 := A'First (2) + (N - 1);

      A_MM := A (R1, C1);
      A_NM := A (R2, C1);  -- = A (R1, C2) if symmetric
      A_NN := A (R2, C2);
      --  Use b from (N-1,N) entry for the off-diagonal
      declare
         B_Off : constant Float := A (R1, C2);
      begin
         --  Prefer the stored (m,n) entry; fall back to (n,m)
         if Abs_F (B_Off) >= Abs_F (A_NM) then
            B := B_Off;
         else
            B := A_NM;
         end if;
      end;

      --  Eigenvalues of [[a,b],[b,c]]: roots of λ² − (a+c)λ + (ac−b²)=0
      C := A_MM + A_NN;
      Disc := (A_MM - A_NN) * (A_MM - A_NN) + 4.0 * B * B;
      if Disc < 0.0 then
         Disc := 0.0;
      end if;
      Disc := Math.Sqrt (Disc);
      Root1 := 0.5 * (C + Disc);
      Root2 := 0.5 * (C - Disc);

      --  Choose eigenvalue closer to A_NN
      if Abs_F (Root1 - A_NN) <= Abs_F (Root2 - A_NN) then
         Mu := Root1;
      else
         Mu := Root2;
      end if;
      return Mu;
   end Wilkinson_Shift;

   -------------------------------------------------------------------------
   -- One QR step (optional explicit shift)
   -------------------------------------------------------------------------

   function QR_Step (A : Matrix; Shift : Float := 0.0) return Step_Result is
      N   : constant Dimension := A'Length (1);
      Res : Step_Result;
      Work : Matrix (1 .. N, 1 .. N);
      Fac  : QR_Result;
      RQ   : Matrix (1 .. N, 1 .. N);
   begin
      Res.N := N;
      Res.Stat := Ill_Started;
      Res.Success := False;
      Res.Next := [others => [others => 0.0]];
      Res.Q := [others => [others => 0.0]];
      Res.R := [others => [others => 0.0]];

      Work := Copy_Square (A, N);
      if Shift /= 0.0 then
         for I in 1 .. N loop
            Work (I, I) := Work (I, I) - Shift;
         end loop;
      end if;

      Fac := QR_Factor (Work);
      if not Fac.Success then
         Res.Stat := Rank_Issue;
         return Res;
      end if;

      for I in 1 .. N loop
         for J in 1 .. N loop
            Res.Q (I, J) := Fac.Q (I, J);
            Res.R (I, J) := Fac.R (I, J);
         end loop;
      end loop;

      --  A' = R Q (+ σ I)
      declare
         Q_Lead : Matrix (1 .. N, 1 .. N);
         R_Lead : Matrix (1 .. N, 1 .. N);
      begin
         for I in 1 .. N loop
            for J in 1 .. N loop
               Q_Lead (I, J) := Fac.Q (I, J);
               R_Lead (I, J) := Fac.R (I, J);
            end loop;
         end loop;
         RQ := Mat_Mul (R_Lead, Q_Lead);
      end;

      for I in 1 .. N loop
         for J in 1 .. N loop
            Res.Next (I, J) := RQ (I, J);
         end loop;
         if Shift /= 0.0 then
            Res.Next (I, I) := Res.Next (I, I) + Shift;
         end if;
      end loop;

      --  Step succeeded; Converged here means the factorisation/step ran.
      Res.Stat := Converged;
      Res.Success := True;
      return Res;
   end QR_Step;

   -------------------------------------------------------------------------
   -- Main QR iteration
   -------------------------------------------------------------------------

   function Iterate
     (A      : Matrix;
      Params : Parameters := Default_Parameters) return Result
   is
      N   : constant Dimension := A'Length (1);
      Res : Result;
      Curr : Matrix (1 .. N, 1 .. N);
      Step : Step_Result;
      Off   : Float;
      V_Acc : Matrix (1 .. N, 1 .. N);
   begin
      Res.N := N;
      Res.Iterations := 0;
      Res.Stat := Ill_Started;
      Res.Success := False;
      Res.Has_V := False;
      Res.Eigenvalues := [others => 0.0];
      Res.V := [others => [others => 0.0]];
      Res.Final_A := [others => [others => 0.0]];
      Res.Off_Diag := 0.0;

      if N = 0 then
         Res.Stat := Dimension_Error;
         return Res;
      end if;

      Curr := Copy_Square (A, N);

      if Params.Accumulate_Q then
         V_Acc := Identity (N);
         Res.Has_V := True;
      end if;

      --  Already diagonal?
      Off := Off_Diag_Norm (Curr);
      Res.Off_Diag := Off;
      if Off <= Params.Tol then
         for I in 1 .. N loop
            Res.Eigenvalues (I) := Curr (I, I);
            for J in 1 .. N loop
               Res.Final_A (I, J) := Curr (I, J);
            end loop;
         end loop;
         if Params.Accumulate_Q then
            for I in 1 .. N loop
               for J in 1 .. N loop
                  Res.V (I, J) := V_Acc (I, J);
               end loop;
            end loop;
         end if;
         Res.Stat := Converged;
         Res.Success := True;
         return Res;
      end if;

      for Iter in 1 .. Params.Max_Iter loop
         --  Iterate stays unshifted for reliability on dense Float + MGS.
         --  Params.Use_Shift still exercises Wilkinson_Shift (sketch); the
         --  actual step uses σ = 0. Explicit shifts: QR_Step (A, σ).
         if Params.Use_Shift and then N >= 2 then
            declare
               Sketch_Sigma : constant Float := Wilkinson_Shift (Curr);
            begin
               pragma Unreferenced (Sketch_Sigma);
            end;
         end if;

         Step := QR_Step (Curr, 0.0);
         if not Step.Success then
            Res.Stat := Rank_Issue;
            Res.Iterations := Iter;
            for I in 1 .. N loop
               Res.Eigenvalues (I) := Curr (I, I);
               for J in 1 .. N loop
                  Res.Final_A (I, J) := Curr (I, J);
               end loop;
            end loop;
            Res.Off_Diag := Off_Diag_Norm (Curr);
            return Res;
         end if;

         for I in 1 .. N loop
            for J in 1 .. N loop
               Curr (I, J) := Step.Next (I, J);
            end loop;
         end loop;

         if Params.Accumulate_Q then
            declare
               Q_Lead : Matrix (1 .. N, 1 .. N);
               New_V  : Matrix (1 .. N, 1 .. N);
            begin
               for I in 1 .. N loop
                  for J in 1 .. N loop
                     Q_Lead (I, J) := Step.Q (I, J);
                  end loop;
               end loop;
               New_V := Mat_Mul (V_Acc, Q_Lead);
               V_Acc := New_V;
            end;
         end if;

         Off := Off_Diag_Norm (Curr);
         Res.Off_Diag := Off;
         Res.Iterations := Iter;

         if Off <= Params.Tol then
            for I in 1 .. N loop
               Res.Eigenvalues (I) := Curr (I, I);
               for J in 1 .. N loop
                  Res.Final_A (I, J) := Curr (I, J);
               end loop;
            end loop;
            if Params.Accumulate_Q then
               for I in 1 .. N loop
                  for J in 1 .. N loop
                     Res.V (I, J) := V_Acc (I, J);
                  end loop;
               end loop;
            end if;
            Res.Stat := Converged;
            Res.Success := True;
            return Res;
         end if;
      end loop;

      --  Budget exhausted
      for I in 1 .. N loop
         Res.Eigenvalues (I) := Curr (I, I);
         for J in 1 .. N loop
            Res.Final_A (I, J) := Curr (I, J);
         end loop;
      end loop;
      if Params.Accumulate_Q then
         for I in 1 .. N loop
            for J in 1 .. N loop
               Res.V (I, J) := V_Acc (I, J);
            end loop;
         end loop;
      end if;
      Res.Off_Diag := Off_Diag_Norm (Curr);
      Res.Stat := Iteration_Limit;
      Res.Success := False;
      return Res;
   end Iterate;

   function Eigenvalues
     (A      : Matrix;
      Params : Parameters := Default_Parameters) return Result
   is
   begin
      return Iterate (A, Params);
   end Eigenvalues;

end QR_Algorithm;
