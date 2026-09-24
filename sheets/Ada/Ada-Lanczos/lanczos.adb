--  Lanczos body — three-term Krylov recurrence + Jacobi Ritz extraction.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Lanczos
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

   function Normalize (V : Vector) return Vector is
      Nrm : constant Float := Norm2 (V);
   begin
      if Nrm <= Norm_Tol then
         raise Invalid_Argument;
      end if;
      return Scale (V, 1.0 / Nrm);
   end Normalize;

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

   function Orthogonality_Residual
     (V : Matrix; N, K : Dimension) return Float
   is
      Max_Dev : Float := 0.0;
      Acc     : Float;
      Target  : Float;
      Dev     : Float;
   begin
      for I in 1 .. K loop
         for J in 1 .. K loop
            Acc := 0.0;
            for R in 1 .. N loop
               Acc := Acc + V (R, I) * V (R, J);
            end loop;
            if I = J then
               Target := 1.0;
            else
               Target := 0.0;
            end if;
            Dev := Abs_F (Acc - Target);
            if Dev > Max_Dev then
               Max_Dev := Dev;
            end if;
         end loop;
      end loop;
      return Max_Dev;
   end Orthogonality_Residual;

   -------------------------------------------------------------------------
   -- Tridiagonal / residual helpers
   -------------------------------------------------------------------------

   function Make_Tridiagonal
     (Alphas : Vector; Betas : Vector; M : Dimension) return Matrix
   is
      T : Matrix (1 .. M, 1 .. M) := [others => [others => 0.0]];
   begin
      for J in 1 .. M loop
         T (J, J) := Alphas (Alphas'First + (J - 1));
      end loop;
      for J in 1 .. M - 1 loop
         declare
            B : constant Float := Betas (Betas'First + (J - 1));
         begin
            T (J, J + 1) := B;
            T (J + 1, J) := B;
         end;
      end loop;
      return T;
   end Make_Tridiagonal;

   function Ritz_Residual_Norm
     (A : Matrix; Y : Vector; Theta : Float) return Float
   is
      Ay : constant Vector := Mat_Vec (A, Y);
   begin
      return Norm2 (Sub (Ay, Scale (Y, Theta)));
   end Ritz_Residual_Norm;

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

   function Make_Known_Spectrum_Symmetric
     (Eigs : Vector) return Matrix
   is
      N    : constant Dimension := Eigs'Length;
      Q    : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      A    : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      Col  : Vector (1 .. N);
      Proj : Float;
      Nrm  : Float;
      S    : Float;
   begin
      for J in 1 .. N loop
         for I in 1 .. N loop
            Q (I, J) :=
              Float ((I * 11 + J * 19 + I * J) mod 89) / 89.0
              + Float (I + J) * 0.01;
         end loop;
         Q (J, J) := Q (J, J) + Float (N);
      end loop;

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
   end Make_Known_Spectrum_Symmetric;

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

         when Known_Spectrum_Symmetric =>
            for I in 1 .. N loop
               Eigs (I) := Float (I);
            end loop;
            return Make_Known_Spectrum_Symmetric (Eigs);
      end case;
   end Make_Example;

   function Poisson_Eigenvalue
     (N : Dimension; K : Dim_Index) return Float
   is
      Pi : constant Float := 3.14159_26535_89793;
      Arg : constant Float :=
        Float (K) * Pi / Float (N + 1);
   begin
      return 2.0 - 2.0 * Math.Cos (Arg);
   end Poisson_Eigenvalue;

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
   -- Inlined Jacobi diagonalization of small symmetric T (educational)
   -------------------------------------------------------------------------

   procedure Sort_Ascending
     (Eigs : in out Vector; Y : in out Matrix; M : Dimension)
   is
   begin
      for I in 1 .. M - 1 loop
         for J in I + 1 .. M loop
            if Eigs (J) < Eigs (I) then
               declare
                  Tmp : constant Float := Eigs (I);
               begin
                  Eigs (I) := Eigs (J);
                  Eigs (J) := Tmp;
               end;
               for R in 1 .. M loop
                  declare
                     U : constant Float := Y (R, I);
                  begin
                     Y (R, I) := Y (R, J);
                     Y (R, J) := U;
                  end;
               end loop;
            end if;
         end loop;
      end loop;
   end Sort_Ascending;

   --  Symmetric Jacobi on leading M×M of T; writes eigenvalues into Eigs
   --  (sorted ascending) and orthonormal eigenvectors into Y columns.
   --  Returns True if off-diagonal mass fell below Tol within Max_Sweeps.
   function Jacobi_Symmetric
     (T          : in out Matrix;
      Y          : out Matrix;
      Eigs       : out Vector;
      M          : Dimension;
      Tol        : Float;
      Max_Sweeps : Natural) return Boolean
   is
      Converged : Boolean := False;
   begin
      for I in 1 .. M loop
         for J in 1 .. M loop
            if I = J then
               Y (I, J) := 1.0;
            else
               Y (I, J) := 0.0;
            end if;
         end loop;
      end loop;

      if M = 1 then
         Eigs (1) := T (1, 1);
         return True;
      end if;

      for Sweep in 1 .. Max_Sweeps loop
         declare
            Off : Float := 0.0;
         begin
            for I in 1 .. M loop
               for J in I + 1 .. M loop
                  Off := Off + Abs_F (T (I, J));
               end loop;
            end loop;
            if Off < Tol * Float (M) then
               Converged := True;
               exit;
            end if;

            for P in 1 .. M - 1 loop
               for Q in P + 1 .. M loop
                  declare
                     App : constant Float := T (P, P);
                     Aqq : constant Float := T (Q, Q);
                     Apq : constant Float := T (P, Q);
                  begin
                     if Abs_F (Apq) > Tol then
                        declare
                           Tau   : constant Float :=
                             (Aqq - App) / (2.0 * Apq);
                           T_Rot : Float;
                           C, S  : Float;
                        begin
                           if Tau >= 0.0 then
                              T_Rot :=
                                1.0 /
                                (Tau + Math.Sqrt (1.0 + Tau * Tau));
                           else
                              T_Rot :=
                                -1.0 /
                                (-Tau + Math.Sqrt (1.0 + Tau * Tau));
                           end if;
                           C := 1.0 / Math.Sqrt (1.0 + T_Rot * T_Rot);
                           S := T_Rot * C;

                           T (P, P) := App - T_Rot * Apq;
                           T (Q, Q) := Aqq + T_Rot * Apq;
                           T (P, Q) := 0.0;
                           T (Q, P) := 0.0;

                           for R in 1 .. M loop
                              if R /= P and then R /= Q then
                                 declare
                                    Trp : constant Float := T (R, P);
                                    Trq : constant Float := T (R, Q);
                                 begin
                                    T (R, P) := C * Trp - S * Trq;
                                    T (P, R) := T (R, P);
                                    T (R, Q) := S * Trp + C * Trq;
                                    T (Q, R) := T (R, Q);
                                 end;
                              end if;
                           end loop;

                           for R in 1 .. M loop
                              declare
                                 Yrp : constant Float := Y (R, P);
                                 Yrq : constant Float := Y (R, Q);
                              begin
                                 Y (R, P) := C * Yrp - S * Yrq;
                                 Y (R, Q) := S * Yrp + C * Yrq;
                              end;
                           end loop;
                        end;
                     end if;
                  end;
               end loop;
            end loop;
         end;
      end loop;

      for I in 1 .. M loop
         Eigs (I) := T (I, I);
      end loop;
      Sort_Ascending (Eigs, Y, M);
      return Converged;
   end Jacobi_Symmetric;

   -------------------------------------------------------------------------
   -- Three-term Lanczos recurrence
   -------------------------------------------------------------------------

   function Build_Tridiagonal
     (A      : Matrix;
      V0     : Vector;
      Params : Parameters := Default_Parameters) return Result
   is
      N      : constant Dimension := V0'Length;
      Res    : Result;
      M_Want : Natural;
      Vj     : Vector (1 .. N);
      Vjm1   : Vector (1 .. N) := [others => 0.0];
      W      : Vector (1 .. N);
      Beta_J : Float := 0.0;
      Alpha  : Float;
      Nrm    : Float;
      Proj   : Float;
      Basis  : Matrix (1 .. N, 1 .. Max_N) :=
                 [others => [others => 0.0]];
   begin
      Res.N := N;
      Res.M_Requested := Params.M;
      Res.Success := False;
      Res.Has_V := False;
      Res.Steps := 0;

      if N = 0
        or else A'Length (1) /= N
        or else A'Length (2) /= N
      then
         Res.Stat := Dimension_Error;
         return Res;
      end if;

      if Params.Tol < 0.0 or else Params.M = 0 then
         Res.Stat := Ill_Started;
         return Res;
      end if;

      if not Is_Symmetric (A, Sym_Tol) then
         Res.Stat := Not_Symmetric;
         return Res;
      end if;

      Nrm := Norm2 (V0);
      if Nrm <= Norm_Tol then
         Res.Stat := Ill_Started;
         return Res;
      end if;

      M_Want := Params.M;
      if M_Want > N then
         M_Want := N;
      end if;
      if M_Want > Max_N then
         M_Want := Max_N;
      end if;

      for I in 1 .. N loop
         Vj (I) := V0 (V0'First + (I - 1)) / Nrm;
      end loop;
      Set_Column (Basis, 1, Vj);

      for J in 1 .. M_Want loop
         W := Mat_Vec (A, Vj);
         Alpha := Dot (Vj, W);
         Res.Alphas (J) := Alpha;

         --  w ← A v_j − α_j v_j − β_j v_{j−1}
         W := Sub (W, Scale (Vj, Alpha));
         if J > 1 then
            W := Sub (W, Scale (Vjm1, Beta_J));
         end if;

         if Params.Reorthogonalize then
            --  Full reorthogonalization against v_1 .. v_j
            for K in 1 .. J loop
               declare
                  Vk : constant Vector := Column (Basis, K);
               begin
                  Proj := Dot (W, Vk);
                  W := Sub (W, Scale (Vk, Proj));
               end;
            end loop;
         end if;

         Nrm := Norm2 (W);
         Res.Betas (J) := Nrm;
         Res.Beta_Next := Nrm;
         Res.Steps := J;

         if Nrm <= Params.Tol then
            --  Exact (or near) invariant subspace: stop early.
            Res.Stat := Breakdown;
            Res.Success := True;
            if Params.Keep_V then
               for Col in 1 .. J loop
                  for Row in 1 .. N loop
                     Res.V (Row, Col) := Basis (Row, Col);
                  end loop;
               end loop;
               Res.Has_V := True;
            end if;
            return Res;
         end if;

         if J = M_Want then
            --  Finished requested steps; β_{m+1} kept in Betas(M)/Beta_Next.
            exit;
         end if;

         --  Advance: v_{j+1} = w / β_{j+1}
         Vjm1 := Vj;
         Beta_J := Nrm;
         for I in 1 .. N loop
            Vj (I) := W (I) / Nrm;
         end loop;
         Set_Column (Basis, J + 1, Vj);
      end loop;

      Res.Stat := Ok;
      Res.Success := True;
      if Params.Keep_V then
         for Col in 1 .. Res.Steps loop
            for Row in 1 .. N loop
               Res.V (Row, Col) := Basis (Row, Col);
            end loop;
         end loop;
         Res.Has_V := True;
      end if;
      return Res;
   end Build_Tridiagonal;

   function Extract_Ritz (Res_In : Result; Params : Parameters) return Result
   is
      Res       : Result := Res_In;
      M         : constant Dimension := Res.Steps;
      N         : constant Dimension := Res.N;
      T         : Matrix (1 .. M, 1 .. M);
      Y         : Matrix (1 .. M, 1 .. M) :=
                    [others => [others => 0.0]];
      Eigs      : Vector (1 .. M) := [others => 0.0];
      Max_Sw    : Natural;
      Jacobi_Ok : Boolean;
      Acc       : Float;
   begin
      Res.Has_Ritz_Vecs := False;
      if M = 0 then
         Res.Stat := Ill_Started;
         Res.Success := False;
         return Res;
      end if;

      T := Make_Tridiagonal
        (Res.Alphas (1 .. M), Res.Betas (1 .. M), M);

      if Params.Max_QR_Iter = 0 then
         Max_Sw := 64;
      else
         Max_Sw := Params.Max_QR_Iter;
      end if;

      Jacobi_Ok :=
        Jacobi_Symmetric
          (T, Y, Eigs, M, 1.0E-10, Max_Sw);

      for I in 1 .. M loop
         Res.Ritz_Values (I) := Eigs (I);
      end loop;

      if Res.Has_V and then N >= 1 then
         for K in 1 .. M loop
            for I in 1 .. N loop
               Acc := 0.0;
               for J in 1 .. M loop
                  Acc := Acc + Res.V (I, J) * Y (J, K);
               end loop;
               Res.Ritz_Vectors (I, K) := Acc;
            end loop;
         end loop;
         Res.Has_Ritz_Vecs := True;
      end if;

      if not Jacobi_Ok and then Res.Stat = Ok then
         Res.Stat := Iteration_Limit;
         Res.Success := False;
      end if;
      return Res;
   end Extract_Ritz;

   function Run
     (A      : Matrix;
      V0     : Vector;
      Params : Parameters := Default_Parameters) return Result
   is
      Built : constant Result := Build_Tridiagonal (A, V0, Params);
   begin
      if not Built.Success
        and then Built.Stat /= Breakdown
      then
         return Built;
      end if;
      if Built.Steps = 0 then
         return Built;
      end if;
      return Extract_Ritz (Built, Params);
   end Run;

   function Run
     (A      : Matrix;
      Params : Parameters := Default_Parameters) return Result
   is
      Res : Result;
      N   : Dimension;
      V0  : Vector (1 .. Max_N);
   begin
      if A'Length (1) = 0
        or else A'Length (2) = 0
        or else A'Length (1) /= A'Length (2)
      then
         Res.Stat := Dimension_Error;
         Res.Success := False;
         Res.N := 0;
         return Res;
      end if;

      N := A'Length (1);
      for I in 1 .. N loop
         V0 (I) := 1.0;
      end loop;
      return Run (A, V0 (1 .. N), Params);
   end Run;

   function Iterate
     (A      : Matrix;
      V0     : Vector;
      Params : Parameters := Default_Parameters) return Result
   is
   begin
      return Run (A, V0, Params);
   end Iterate;

   function Ritz_Vector
     (Res : Result; Z : Vector) return Vector
   is
      N : constant Dimension := Res.N;
      M : constant Dimension := Res.Steps;
      Y : Vector (1 .. N) := [others => 0.0];
      S : Float;
   begin
      for I in 1 .. N loop
         S := 0.0;
         for J in 1 .. M loop
            S := S + Res.V (I, J) * Z (Z'First + (J - 1));
         end loop;
         Y (I) := S;
      end loop;
      return Y;
   end Ritz_Vector;

end Lanczos;
