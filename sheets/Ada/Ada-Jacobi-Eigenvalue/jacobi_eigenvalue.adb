--  Jacobi_Eigenvalue body — cyclic / classical plane-rotation
--  diagonalization of real symmetric matrices (educational Float).

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Jacobi_Eigenvalue
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
     (A : Matrix; Tol : Float := Sym_Tol) return Boolean
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
      S   : Float := 0.0;
      N   : constant Dimension := A'Length (1);
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
     (V : Matrix; N : Dimension) return Float
   is
      Max_Dev : Float := 0.0;
      S, Target, Dev : Float;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            S := 0.0;
            for K in 1 .. N loop
               S := S
                 + V (V'First (1) + (K - 1), V'First (2) + (I - 1))
                 * V (V'First (1) + (K - 1), V'First (2) + (J - 1));
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

   function Mat_Eigen_Residual
     (A    : Matrix;
      V    : Matrix;
      Eigs : Vector;
      N    : Dimension) return Float
   is
      Col : Vector (1 .. N);
      R   : Vector (1 .. N);
      Acc : Float := 0.0;
      Lam : Float;
   begin
      for J in 1 .. N loop
         for I in 1 .. N loop
            Col (I) :=
              V (V'First (1) + (I - 1), V'First (2) + (J - 1));
         end loop;
         Lam := Eigs (Eigs'First + (J - 1));
         R := Eigen_Residual (A, Col, Lam);
         Acc := Acc + Dot (R, R);
      end loop;
      return Math.Sqrt (Acc);
   end Mat_Eigen_Residual;

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

   function Make_Symmetric_Known (Eigs : Vector) return Matrix is
      N   : constant Dimension := Eigs'Length;
      Q   : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      A   : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      Col : Vector (1 .. N);
      Proj, Nrm, S : Float;
   begin
      --  Deterministic full-rank seed columns.
      for J in 1 .. N loop
         for I in 1 .. N loop
            Q (I, J) :=
              Float ((I * 11 + J * 19 + I * J) mod 89) / 89.0
              + Float (I + J) * 0.01;
         end loop;
         Q (J, J) := Q (J, J) + Float (N);
      end loop;

      --  Modified Gram–Schmidt.
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

      --  A = Q D Qᵀ
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
               V := V + Float (N);
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
      Arg : constant Float :=
        Float (K) * Ada.Numerics.Pi / Float (N + 1);
   begin
      return 2.0 - 2.0 * Math.Cos (Arg);
   end Poisson_Eigenvalue;

   -------------------------------------------------------------------------
   -- Plane rotation and sorting
   -------------------------------------------------------------------------

   function Apply_Rotation
     (S      : in out Matrix;
      V      : in out Matrix;
      P, Q   : Dim_Index;
      N      : Dimension) return Boolean
   is
      App : constant Float := S (P, P);
      Aqq : constant Float := S (Q, Q);
      Apq : constant Float := S (P, Q);
      Tau, T_Rot, C, Ss : Float;
   begin
      if Abs_F (Apq) <= Norm_Tol then
         return False;
      end if;

      --  τ = (a_qq − a_pp) / (2 a_pq); t = tan θ = sign(τ) / (|τ|+√(1+τ²))
      Tau := (Aqq - App) / (2.0 * Apq);
      if Tau >= 0.0 then
         T_Rot := 1.0 / (Tau + Math.Sqrt (1.0 + Tau * Tau));
      else
         T_Rot := -1.0 / (-Tau + Math.Sqrt (1.0 + Tau * Tau));
      end if;
      C  := 1.0 / Math.Sqrt (1.0 + T_Rot * T_Rot);
      Ss := T_Rot * C;

      S (P, P) := App - T_Rot * Apq;
      S (Q, Q) := Aqq + T_Rot * Apq;
      S (P, Q) := 0.0;
      S (Q, P) := 0.0;

      for R in 1 .. N loop
         if R /= P and then R /= Q then
            declare
               Trp : constant Float := S (R, P);
               Trq : constant Float := S (R, Q);
            begin
               S (R, P) := C * Trp - Ss * Trq;
               S (P, R) := S (R, P);
               S (R, Q) := Ss * Trp + C * Trq;
               S (Q, R) := S (R, Q);
            end;
         end if;
      end loop;

      --  V ← V G  (rotate columns P and Q)
      for R in 1 .. N loop
         declare
            Vrp : constant Float := V (R, P);
            Vrq : constant Float := V (R, Q);
         begin
            V (R, P) := C * Vrp - Ss * Vrq;
            V (R, Q) := Ss * Vrp + C * Vrq;
         end;
      end loop;

      return True;
   end Apply_Rotation;

   procedure Sort_Ascending
     (Eigs : in out Vector;
      V    : in out Matrix;
      N    : Dimension)
   is
   begin
      for I in 1 .. N - 1 loop
         for J in I + 1 .. N loop
            if Eigs (J) < Eigs (I) then
               declare
                  Tmp : constant Float := Eigs (I);
               begin
                  Eigs (I) := Eigs (J);
                  Eigs (J) := Tmp;
               end;
               for R in 1 .. N loop
                  declare
                     U : constant Float := V (R, I);
                  begin
                     V (R, I) := V (R, J);
                     V (R, J) := U;
                  end;
               end loop;
            end if;
         end loop;
      end loop;
   end Sort_Ascending;

   procedure Find_Largest_Off_Diag
     (S       : Matrix;
      N       : Dimension;
      P, Q    : out Dim_Index;
      Max_Abs : out Float)
   is
      AIJ : Float;
   begin
      P := 1;
      Q := 2;
      Max_Abs := 0.0;
      if N < 2 then
         return;
      end if;
      for I in 1 .. N - 1 loop
         for J in I + 1 .. N loop
            AIJ := Abs_F (S (I, J));
            if AIJ > Max_Abs then
               Max_Abs := AIJ;
               P := I;
               Q := J;
            end if;
         end loop;
      end loop;
   end Find_Largest_Off_Diag;

   -------------------------------------------------------------------------
   -- Diagonalize / Eigenpairs
   -------------------------------------------------------------------------

   function Diagonalize
     (S      : Matrix;
      Params : Parameters := Default_Parameters) return Result
   is
      N   : constant Dimension := S'Length (1);
      Res : Result;
      Work : Matrix (1 .. N, 1 .. N);
      Vmat : Matrix (1 .. N, 1 .. N);
      Off  : Float;
      Did  : Boolean;
      P, Q : Dim_Index;
      Max_Abs : Float;
      Rot_Budget : constant Natural :=
        (if Params.Mode = Classical then
            Natural'Max (1, Params.Max_Sweeps * N * N)
         else
            0);
      --  Classical counts rotations; Cyclic counts sweeps.
   begin
      Res.N := N;
      Res.Stat := Ill_Started;
      Res.Success := False;
      Res.Sweeps := 0;
      Res.Rotations := 0;
      Res.Eigenvalues := [others => 0.0];
      Res.Eigenvectors := [others => [others => 0.0]];
      Res.Final_S := [others => [others => 0.0]];

      --  Dimension is constrained by Pre (1 .. Max_N); Dimension_Error
      --  remains in Status for API completeness / future callers.

      Work := Copy_Square (S, N);

      if not Is_Symmetric (Work, Sym_Tol) then
         Res.Stat := Not_Symmetric;
         Res.Off_Diag_Norm := Off_Diag_Norm (Work);
         return Res;
      end if;

      --  V := I
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I = J then
               Vmat (I, J) := 1.0;
            else
               Vmat (I, J) := 0.0;
            end if;
         end loop;
      end loop;

      if N = 1 then
         Res.Eigenvalues (1) := Work (1, 1);
         Res.Eigenvectors (1, 1) := 1.0;
         Res.Final_S (1, 1) := Work (1, 1);
         Res.Off_Diag_Norm := 0.0;
         Res.Stat := Converged;
         Res.Success := True;
         return Res;
      end if;

      Off := Off_Diag_Norm (Work);
      if Off <= Params.Tol then
         --  Already diagonal (or nearly).
         for I in 1 .. N loop
            Res.Eigenvalues (I) := Work (I, I);
            for J in 1 .. N loop
               Res.Eigenvectors (I, J) := Vmat (I, J);
               Res.Final_S (I, J) := Work (I, J);
            end loop;
         end loop;
         if Params.Sort_Eigs then
            declare
               E : Vector (1 .. N);
               VV : Matrix (1 .. N, 1 .. N) := Vmat;
            begin
               for I in 1 .. N loop
                  E (I) := Res.Eigenvalues (I);
               end loop;
               Sort_Ascending (E, VV, N);
               for I in 1 .. N loop
                  Res.Eigenvalues (I) := E (I);
                  for J in 1 .. N loop
                     Res.Eigenvectors (I, J) := VV (I, J);
                  end loop;
               end loop;
            end;
         end if;
         Res.Off_Diag_Norm := Off;
         Res.Stat := Converged;
         Res.Success := True;
         return Res;
      end if;

      case Params.Mode is
         when Cyclic =>
            for Sweep in 1 .. Params.Max_Sweeps loop
               Res.Sweeps := Sweep;
               for I in 1 .. N - 1 loop
                  for J in I + 1 .. N loop
                     Did := Apply_Rotation (Work, Vmat, I, J, N);
                     if Did then
                        Res.Rotations := Res.Rotations + 1;
                     end if;
                  end loop;
               end loop;
               Off := Off_Diag_Norm (Work);
               exit when Off <= Params.Tol;
            end loop;

         when Classical =>
            declare
               Limit : Natural := Rot_Budget;
               Sweeps_Est : Natural := 0;
               Pairs_Per_Sweep : constant Natural :=
                 (N * (N - 1)) / 2;
               Done_Pairs : Natural := 0;
            begin
               while Limit > 0 loop
                  Find_Largest_Off_Diag (Work, N, P, Q, Max_Abs);
                  if Max_Abs <= Params.Tol then
                     exit;
                  end if;
                  Did := Apply_Rotation (Work, Vmat, P, Q, N);
                  if Did then
                     Res.Rotations := Res.Rotations + 1;
                  end if;
                  Done_Pairs := Done_Pairs + 1;
                  if Done_Pairs >= Pairs_Per_Sweep then
                     Sweeps_Est := Sweeps_Est + 1;
                     Done_Pairs := 0;
                  end if;
                  Limit := Limit - 1;
                  Off := Off_Diag_Norm (Work);
                  exit when Off <= Params.Tol;
               end loop;
               Res.Sweeps := Sweeps_Est;
               if Done_Pairs > 0 then
                  Res.Sweeps := Res.Sweeps + 1;
               end if;
            end;
      end case;

      Off := Off_Diag_Norm (Work);
      Res.Off_Diag_Norm := Off;

      for I in 1 .. N loop
         Res.Eigenvalues (I) := Work (I, I);
         for J in 1 .. N loop
            Res.Eigenvectors (I, J) := Vmat (I, J);
            Res.Final_S (I, J) := Work (I, J);
         end loop;
      end loop;

      if Params.Sort_Eigs then
         declare
            E  : Vector (1 .. N);
            VV : Matrix (1 .. N, 1 .. N);
         begin
            for I in 1 .. N loop
               E (I) := Res.Eigenvalues (I);
               for J in 1 .. N loop
                  VV (I, J) := Vmat (I, J);
               end loop;
            end loop;
            Sort_Ascending (E, VV, N);
            for I in 1 .. N loop
               Res.Eigenvalues (I) := E (I);
               for J in 1 .. N loop
                  Res.Eigenvectors (I, J) := VV (I, J);
               end loop;
            end loop;
         end;
      end if;

      if Off <= Params.Tol then
         Res.Stat := Converged;
         Res.Success := True;
      else
         Res.Stat := Iteration_Limit;
         Res.Success := False;
      end if;
      return Res;
   end Diagonalize;

   function Eigenpairs
     (S      : Matrix;
      Params : Parameters := Default_Parameters) return Result
   is
   begin
      return Diagonalize (S, Params);
   end Eigenpairs;

end Jacobi_Eigenvalue;
