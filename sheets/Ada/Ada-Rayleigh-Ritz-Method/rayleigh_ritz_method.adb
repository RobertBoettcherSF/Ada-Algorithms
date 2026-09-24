--  Rayleigh_Ritz_Method body — matrix Rayleigh–Ritz, Jacobi, generalized RR.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Rayleigh_Ritz_Method is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   Pi : constant Real := 3.141592653589793_23846;

   -------------------------------------------------------------------------
   -- Near / vector helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Dot (X, Y : Vector) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I) * Y (I);
      end loop;
      return S;
   end Dot;

   function Norm2 (X : Vector) return Non_Negative is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I) * X (I);
      end loop;
      if S < 0.0 then
         return 0.0;
      end if;
      return Non_Negative (S);
   end Norm2;

   function Norm (X : Vector) return Non_Negative is
      S2 : constant Non_Negative := Norm2 (X);
   begin
      if S2 = 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (Real (S2)));
   end Norm;

   procedure Scale (X : in out Vector; Alpha : Real) is
   begin
      for I in X'Range loop
         X (I) := Alpha * X (I);
      end loop;
   end Scale;

   procedure Axpy (Y : in out Vector; Alpha : Real; X : Vector) is
   begin
      for I in Y'Range loop
         Y (I) := Y (I) + Alpha * X (I);
      end loop;
   end Axpy;

   function Mat_Vec (A : Matrix; X : Vector) return Vector is
      Y : Vector (X'Range) := [others => 0.0];
   begin
      for I in A'Range (1) loop
         declare
            S : Real := 0.0;
         begin
            for J in A'Range (2) loop
               S := S + A (I, J) * X (J);
            end loop;
            Y (I) := S;
         end;
      end loop;
      return Y;
   end Mat_Vec;

   function Residual_Norm (A : Matrix; X : Vector; Theta : Real)
     return Non_Negative
   is
      Ax : constant Vector := Mat_Vec (A, X);
      R  : Vector (X'Range);
   begin
      for I in X'Range loop
         R (I) := Ax (I) - Theta * X (I);
      end loop;
      return Norm (R);
   end Residual_Norm;

   -------------------------------------------------------------------------
   -- Fill / column helpers
   -------------------------------------------------------------------------

   function Zero_Matrix (N : Dim_N) return Matrix is
      Z : constant Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      return Z;
   end Zero_Matrix;

   function Identity (N : Dim_N) return Matrix is
      Imat : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         Imat (I, I) := 1.0;
      end loop;
      return Imat;
   end Identity;

   function Column (Q : Basis; Col : Index_K) return Vector is
      V : Vector (Q'Range (1));
   begin
      for I in Q'Range (1) loop
         V (I) := Q (I, Col);
      end loop;
      return V;
   end Column;

   procedure Set_Column (Q : in out Basis; Col : Index_K; V : Vector) is
   begin
      for I in Q'Range (1) loop
         Q (I, Col) := V (I);
      end loop;
   end Set_Column;

   -------------------------------------------------------------------------
   -- Rayleigh quotient
   -------------------------------------------------------------------------

   function Rayleigh_Quotient (A : Matrix; X : Vector) return Real is
      Ax  : Vector (X'Range);
      Num : Real;
      Den : constant Non_Negative := Norm2 (X);
   begin
      if Den = 0.0 then
         raise Degenerate with "Rayleigh_Quotient: zero vector";
      end if;
      Ax  := Mat_Vec (A, X);
      Num := Dot (X, Ax);
      return Num / Real (Den);
   end Rayleigh_Quotient;

   -------------------------------------------------------------------------
   -- Modified Gram–Schmidt
   -------------------------------------------------------------------------

   procedure Orthonormalize
     (Q          : in out Basis;
      Rank       : out Dim_K;
      Tol        : Real := Epsilon_Tol;
      Raise_Rank : Boolean := False)
   is
      N   : constant Index_N := Q'Last (1);
      K0  : constant Index_K := Q'Last (2);
      Kept : Dim_K := 0;
   begin
      for J in Q'Range (2) loop
         declare
            V : Vector (1 .. N) := Column (Q, J);
         begin
            --  Subtract projections onto already kept columns.
            for P in 1 .. Kept loop
               declare
                  Qp : constant Vector := Column (Q, Index_K (P));
                  C  : constant Real := Dot (Qp, V);
               begin
                  Axpy (V, -C, Qp);
               end;
            end loop;

            declare
               Nv : constant Non_Negative := Norm (V);
            begin
               if Real (Nv) > Tol then
                  Scale (V, 1.0 / Real (Nv));
                  Kept := Kept + 1;
                  Set_Column (Q, Index_K (Kept), V);
               elsif Raise_Rank then
                  raise Rank_Deficient
                    with "Orthonormalize: column dropped";
               end if;
            end;
         end;
      end loop;

      --  Zero unused trailing columns for cleanliness.
      for J in Kept + 1 .. K0 loop
         for I in 1 .. N loop
            Q (I, J) := 0.0;
         end loop;
      end loop;

      Rank := Kept;
   end Orthonormalize;

   function Is_Orthonormal
     (Q   : Basis;
      K   : Dim_K;
      Tol : Real := 1.0E-8) return Boolean
   is
   begin
      if K = 0 then
         return True;
      end if;
      for J in 1 .. K loop
         for I in 1 .. J loop
            declare
               Qi : constant Vector := Column (Q, Index_K (I));
               Qj : constant Vector := Column (Q, Index_K (J));
               G  : constant Real := Dot (Qi, Qj);
               Exp : constant Real := (if I = J then 1.0 else 0.0);
            begin
               if abs (G - Exp) > Tol then
                  return False;
               end if;
            end;
         end loop;
      end loop;
      return True;
   end Is_Orthonormal;

   -------------------------------------------------------------------------
   -- Projection
   -------------------------------------------------------------------------

   function Project_QtAQ
     (A : Matrix;
      Q : Basis;
      K : Dim_K) return Small_Matrix
   is
      T : Small_Matrix (1 .. K, 1 .. K) := [others => [others => 0.0]];
   begin
      for J in 1 .. K loop
         declare
            Qj  : constant Vector := Column (Q, Index_K (J));
            AQj : constant Vector := Mat_Vec (A, Qj);
         begin
            for I in 1 .. K loop
               declare
                  Qi : constant Vector := Column (Q, Index_K (I));
               begin
                  T (Index_K (I), Index_K (J)) := Dot (Qi, AQj);
               end;
            end loop;
         end;
      end loop;
      return T;
   end Project_QtAQ;

   function Project_QtBQ
     (B : Matrix;
      Q : Basis;
      K : Dim_K) return Small_Matrix
   is
   begin
      return Project_QtAQ (B, Q, K);
   end Project_QtBQ;

   -------------------------------------------------------------------------
   -- Analytic 2 × 2
   -------------------------------------------------------------------------

   procedure Eigen_2x2
     (A11, A12, A22 : Real;
      Lam1, Lam2    : out Real;
      V1x, V1y      : out Real;
      V2x, V2y      : out Real)
   is
      Trace : constant Real := A11 + A22;
      Det   : constant Real := A11 * A22 - A12 * A12;
      Disc  : Real := Trace * Trace - 4.0 * Det;
      S     : Real;
      N1, N2 : Real;
   begin
      if Disc < 0.0 then
         Disc := 0.0;
      end if;
      S := Math.Sqrt (Disc);
      Lam1 := 0.5 * (Trace - S);
      Lam2 := 0.5 * (Trace + S);

      --  Eigenvector for Lam1: (A12, Lam1 - A11) or (Lam1 - A22, A12).
      if abs (A12) > abs (Lam1 - A22) then
         V1x := A12;
         V1y := Lam1 - A11;
      else
         V1x := Lam1 - A22;
         V1y := A12;
      end if;
      N1 := Math.Sqrt (V1x * V1x + V1y * V1y);
      if N1 < 1.0E-30 then
         V1x := 1.0;
         V1y := 0.0;
      else
         V1x := V1x / N1;
         V1y := V1y / N1;
      end if;

      --  Orthogonal partner (rotate 90°); flip so it matches Lam2 direction.
      V2x := -V1y;
      V2y := V1x;
      --  If A12 ≈ 0 and A11 > A22, Lam1 = A22, Lam2 = A11 — already ok.
      --  Verify (A - Lam2 I) V2 ≈ 0; if not, negate.
      declare
         R0 : constant Real := (A11 - Lam2) * V2x + A12 * V2y;
         R1 : constant Real := A12 * V2x + (A22 - Lam2) * V2y;
      begin
         if abs (R0) + abs (R1) >
           abs ((A11 - Lam2) * (-V2x) + A12 * (-V2y))
             + abs (A12 * (-V2x) + (A22 - Lam2) * (-V2y))
         then
            V2x := -V2x;
            V2y := -V2y;
         end if;
      end;
      N2 := Math.Sqrt (V2x * V2x + V2y * V2y);
      if N2 > 0.0 then
         V2x := V2x / N2;
         V2y := V2y / N2;
      end if;
   end Eigen_2x2;

   -------------------------------------------------------------------------
   -- Jacobi symmetric eigensolver
   -------------------------------------------------------------------------

   procedure Sort_Eigenpairs
     (Eigenvals : in out Small_Vector;
      Y         : in out Small_Matrix;
      K         : Dim_K)
   is
   begin
      for I in 1 .. K - 1 loop
         for J in I + 1 .. K loop
            if Eigenvals (Index_K (J)) < Eigenvals (Index_K (I)) then
               declare
                  Tmp : constant Real := Eigenvals (Index_K (I));
               begin
                  Eigenvals (Index_K (I)) := Eigenvals (Index_K (J));
                  Eigenvals (Index_K (J)) := Tmp;
               end;
               for R in 1 .. K loop
                  declare
                     U : constant Real :=
                       Y (Index_K (R), Index_K (I));
                  begin
                     Y (Index_K (R), Index_K (I)) :=
                       Y (Index_K (R), Index_K (J));
                     Y (Index_K (R), Index_K (J)) := U;
                  end;
               end loop;
            end if;
         end loop;
      end loop;
   end Sort_Eigenpairs;

   procedure Jacobi_Symmetric
     (T         : in out Small_Matrix;
      Y         : out Small_Matrix;
      Eigenvals : out Small_Vector;
      K         : Dim_K;
      Tol       : Real := Jacobi_Tol)
   is
      Max_Sweeps : constant Natural := 64;
   begin
      --  Initialize Y = I_K
      for I in 1 .. K loop
         for J in 1 .. K loop
            if I = J then
               Y (Index_K (I), Index_K (J)) := 1.0;
            else
               Y (Index_K (I), Index_K (J)) := 0.0;
            end if;
         end loop;
      end loop;

      if K = 1 then
         Eigenvals (1) := T (1, 1);
         return;
      end if;

      if K = 2 then
         declare
            L1, L2, V1x, V1y, V2x, V2y : Real;
         begin
            Eigen_2x2
              (T (1, 1), T (1, 2), T (2, 2),
               L1, L2, V1x, V1y, V2x, V2y);
            T (1, 1) := L1;
            T (2, 2) := L2;
            T (1, 2) := 0.0;
            T (2, 1) := 0.0;
            Y (1, 1) := V1x;
            Y (2, 1) := V1y;
            Y (1, 2) := V2x;
            Y (2, 2) := V2y;
            Eigenvals (1) := L1;
            Eigenvals (2) := L2;
            return;
         end;
      end if;

      for Sweep in 1 .. Max_Sweeps loop
         declare
            Off : Real := 0.0;
         begin
            for I in 1 .. K loop
               for J in I + 1 .. K loop
                  Off := Off + abs (T (Index_K (I), Index_K (J)));
               end loop;
            end loop;
            exit when Off < Tol * Real (K);

            for P in 1 .. K - 1 loop
               for Q in P + 1 .. K loop
                  declare
                     App : constant Real := T (Index_K (P), Index_K (P));
                     Aqq : constant Real := T (Index_K (Q), Index_K (Q));
                     Apq : constant Real := T (Index_K (P), Index_K (Q));
                  begin
                     if abs (Apq) > Tol then
                        declare
                           Tau : constant Real :=
                             (Aqq - App) / (2.0 * Apq);
                           T_Rot : Real;
                           C, S  : Real;
                        begin
                           if Tau >= 0.0 then
                              T_Rot :=
                                1.0 /
                                (Tau +
                                 Math.Sqrt (1.0 + Tau * Tau));
                           else
                              T_Rot :=
                                -1.0 /
                                (-Tau +
                                 Math.Sqrt (1.0 + Tau * Tau));
                           end if;
                           C := 1.0 /
                             Math.Sqrt (1.0 + T_Rot * T_Rot);
                           S := T_Rot * C;

                           --  Rotate T
                           T (Index_K (P), Index_K (P)) :=
                             App - T_Rot * Apq;
                           T (Index_K (Q), Index_K (Q)) :=
                             Aqq + T_Rot * Apq;
                           T (Index_K (P), Index_K (Q)) := 0.0;
                           T (Index_K (Q), Index_K (P)) := 0.0;

                           for R in 1 .. K loop
                              if R /= P and then R /= Q then
                                 declare
                                    Trp : constant Real :=
                                      T (Index_K (R), Index_K (P));
                                    Trq : constant Real :=
                                      T (Index_K (R), Index_K (Q));
                                 begin
                                    T (Index_K (R), Index_K (P)) :=
                                      C * Trp - S * Trq;
                                    T (Index_K (P), Index_K (R)) :=
                                      T (Index_K (R), Index_K (P));
                                    T (Index_K (R), Index_K (Q)) :=
                                      S * Trp + C * Trq;
                                    T (Index_K (Q), Index_K (R)) :=
                                      T (Index_K (R), Index_K (Q));
                                 end;
                              end if;
                           end loop;

                           --  Accumulate eigenvectors
                           for R in 1 .. K loop
                              declare
                                 Yrp : constant Real :=
                                   Y (Index_K (R), Index_K (P));
                                 Yrq : constant Real :=
                                   Y (Index_K (R), Index_K (Q));
                              begin
                                 Y (Index_K (R), Index_K (P)) :=
                                   C * Yrp - S * Yrq;
                                 Y (Index_K (R), Index_K (Q)) :=
                                   S * Yrp + C * Yrq;
                              end;
                           end loop;

                        end;
                     end if;
                  end;
               end loop;
            end loop;
         end;
      end loop;

      for I in 1 .. K loop
         Eigenvals (Index_K (I)) := T (Index_K (I), Index_K (I));
      end loop;
      Sort_Eigenpairs (Eigenvals, Y, K);
   end Jacobi_Symmetric;

   -------------------------------------------------------------------------
   -- Ritz extraction (standard)
   -------------------------------------------------------------------------

   procedure Ritz_Extract
     (A         : Matrix;
      Q         : in out Basis;
      K         : in out Dim_K;
      Ritz_Vals : out Small_Vector;
      Ritz_Vecs : out Basis;
      Tol       : Real := Epsilon_Tol)
   is
      Rank : Dim_K;
      T    : Small_Matrix (1 .. Max_K, 1 .. Max_K);
      Y    : Small_Matrix (1 .. Max_K, 1 .. Max_K);
      Eigs : Small_Vector (1 .. Max_K);
      N    : constant Index_N := Q'Last (1);
   begin
      Orthonormalize (Q, Rank, Tol, Raise_Rank => False);
      if Rank = 0 then
         raise Rank_Deficient with "Ritz_Extract: empty basis after MGS";
      end if;
      K := Rank;

      declare
         Tsub : constant Small_Matrix := Project_QtAQ (A, Q, K);
      begin
         for I in 1 .. K loop
            for J in 1 .. K loop
               T (Index_K (I), Index_K (J)) :=
                 Tsub (Index_K (I), Index_K (J));
            end loop;
         end loop;
      end;

      Jacobi_Symmetric (T, Y, Eigs, K);

      for J in 1 .. K loop
         Ritz_Vals (Index_K (J)) := Eigs (Index_K (J));
         for I in 1 .. N loop
            declare
               S : Real := 0.0;
            begin
               for P in 1 .. K loop
                  S := S + Q (I, Index_K (P)) * Y (Index_K (P), Index_K (J));
               end loop;
               Ritz_Vecs (I, Index_K (J)) := S;
            end;
         end loop;
      end loop;

      --  Zero unused Ritz columns
      for J in K + 1 .. Ritz_Vecs'Last (2) loop
         for I in Ritz_Vecs'Range (1) loop
            Ritz_Vecs (I, J) := 0.0;
         end loop;
      end loop;
      for J in K + 1 .. Ritz_Vals'Last loop
         Ritz_Vals (J) := 0.0;
      end loop;
   end Ritz_Extract;

   -------------------------------------------------------------------------
   -- Cholesky + triangular solves for generalized RR
   -------------------------------------------------------------------------

   procedure Cholesky_Decompose
     (S : in out Small_Matrix;
      K : Dim_K)
   is
   begin
      for I in 1 .. K loop
         for J in 1 .. I loop
            declare
               Sum : Real := S (Index_K (I), Index_K (J));
            begin
               for P in 1 .. J - 1 loop
                  Sum := Sum
                    - S (Index_K (I), Index_K (P))
                      * S (Index_K (J), Index_K (P));
               end loop;
               if I = J then
                  if Sum <= 0.0 then
                     raise Degenerate
                       with "Cholesky: S not SPD";
                  end if;
                  S (Index_K (I), Index_K (J)) :=
                    Math.Sqrt (Sum);
               else
                  S (Index_K (I), Index_K (J)) :=
                    Sum / S (Index_K (J), Index_K (J));
               end if;
            end;
         end loop;
         for J in I + 1 .. K loop
            S (Index_K (I), Index_K (J)) := 0.0;
         end loop;
      end loop;
   end Cholesky_Decompose;

   --  Solve L Z = M  (L lower-triangular) column-wise; M is K×K.
   procedure Solve_L_Left
     (L : Small_Matrix;
      M : in out Small_Matrix;
      K : Dim_K)
   is
   begin
      for Col in 1 .. K loop
         for I in 1 .. K loop
            declare
               Sum : Real := M (Index_K (I), Index_K (Col));
            begin
               for P in 1 .. I - 1 loop
                  Sum := Sum
                    - L (Index_K (I), Index_K (P))
                      * M (Index_K (P), Index_K (Col));
               end loop;
               M (Index_K (I), Index_K (Col)) :=
                 Sum / L (Index_K (I), Index_K (I));
            end;
         end loop;
      end loop;
   end Solve_L_Left;

   --  Solve Z Lᵀ = M  (row-wise / right multiply by L^{-T}).
   procedure Solve_LT_Right
     (L : Small_Matrix;
      M : in out Small_Matrix;
      K : Dim_K)
   is
   begin
      for Row in 1 .. K loop
         for J in reverse 1 .. K loop
            declare
               Sum : Real := M (Index_K (Row), Index_K (J));
            begin
               for P in J + 1 .. K loop
                  Sum := Sum
                    - L (Index_K (P), Index_K (J))
                      * M (Index_K (Row), Index_K (P));
               end loop;
               M (Index_K (Row), Index_K (J)) :=
                 Sum / L (Index_K (J), Index_K (J));
            end;
         end loop;
      end loop;
   end Solve_LT_Right;

   --  Solve Lᵀ y = z.
   procedure Solve_LT_Vec
     (L : Small_Matrix;
      Z : in out Small_Vector;
      K : Dim_K)
   is
   begin
      for I in reverse 1 .. K loop
         declare
            Sum : Real := Z (Index_K (I));
         begin
            for P in I + 1 .. K loop
               Sum := Sum
                 - L (Index_K (P), Index_K (I)) * Z (Index_K (P));
            end loop;
            Z (Index_K (I)) := Sum / L (Index_K (I), Index_K (I));
         end;
      end loop;
   end Solve_LT_Vec;

   procedure Ritz_Extract_Generalized
     (A         : Matrix;
      B         : Matrix;
      Q         : in out Basis;
      K         : in out Dim_K;
      Ritz_Vals : out Small_Vector;
      Ritz_Vecs : out Basis;
      Tol       : Real := Epsilon_Tol)
   is
      Rank : Dim_K;
      T    : Small_Matrix (1 .. Max_K, 1 .. Max_K);
      S    : Small_Matrix (1 .. Max_K, 1 .. Max_K);
      Y    : Small_Matrix (1 .. Max_K, 1 .. Max_K);
      Eigs : Small_Vector (1 .. Max_K);
      N    : constant Index_N := Q'Last (1);
   begin
      Orthonormalize (Q, Rank, Tol, Raise_Rank => False);
      if Rank = 0 then
         raise Rank_Deficient
           with "Ritz_Extract_Generalized: empty basis";
      end if;
      K := Rank;

      declare
         Tsub : constant Small_Matrix := Project_QtAQ (A, Q, K);
         Ssub : constant Small_Matrix := Project_QtBQ (B, Q, K);
      begin
         for I in 1 .. K loop
            for J in 1 .. K loop
               T (Index_K (I), Index_K (J)) :=
                 Tsub (Index_K (I), Index_K (J));
               S (Index_K (I), Index_K (J)) :=
                 Ssub (Index_K (I), Index_K (J));
            end loop;
         end loop;
      end;

      --  Cholesky S = L Lᵀ (L stored in S lower triangle).
      Cholesky_Decompose (S, K);

      --  Form C = L^{-1} T L^{-T}: first C := T, then L\C and C/Lᵀ.
      declare
         C : Small_Matrix (1 .. Max_K, 1 .. Max_K) := T;
      begin
         Solve_L_Left (S, C, K);
         Solve_LT_Right (S, C, K);

         Jacobi_Symmetric (C, Y, Eigs, K);

         --  Map eigenvectors: y_phys = L^{-T} y_std
         for J in 1 .. K loop
            declare
               Z : Small_Vector (1 .. Max_K);
            begin
               for I in 1 .. K loop
                  Z (Index_K (I)) := Y (Index_K (I), Index_K (J));
               end loop;
               Solve_LT_Vec (S, Z, K);
               for I in 1 .. K loop
                  Y (Index_K (I), Index_K (J)) := Z (Index_K (I));
               end loop;
            end;
         end loop;
      end;

      for J in 1 .. K loop
         Ritz_Vals (Index_K (J)) := Eigs (Index_K (J));
         for I in 1 .. N loop
            declare
               Acc : Real := 0.0;
            begin
               for P in 1 .. K loop
                  Acc := Acc
                    + Q (I, Index_K (P)) * Y (Index_K (P), Index_K (J));
               end loop;
               Ritz_Vecs (I, Index_K (J)) := Acc;
            end;
         end loop;
      end loop;

      for J in K + 1 .. Ritz_Vecs'Last (2) loop
         for I in Ritz_Vecs'Range (1) loop
            Ritz_Vecs (I, J) := 0.0;
         end loop;
      end loop;
      for J in K + 1 .. Ritz_Vals'Last loop
         Ritz_Vals (J) := 0.0;
      end loop;
   end Ritz_Extract_Generalized;


   function Identity_Basis (N : Dim_N; K : Dim_K) return Basis is
      Q : Basis (1 .. N, 1 .. K) := [others => [others => 0.0]];
   begin
      for J in 1 .. K loop
         Q (Index_N (J), Index_K (J)) := 1.0;
      end loop;
      return Q;
   end Identity_Basis;

   -------------------------------------------------------------------------
   -- Discrete Laplacian helpers
   -------------------------------------------------------------------------

   function Discrete_Laplacian (N : Dim_N) return Matrix is
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
   end Discrete_Laplacian;

   function Laplacian_Exact_Eigenvalue (N : Dim_N; J : Index_N) return Real is
      Arg : constant Real :=
        Pi * Real (J) / Real (N + 1);
   begin
      return 2.0 - 2.0 * Math.Cos (Arg);
   end Laplacian_Exact_Eigenvalue;

   function Laplacian_Exact_Eigenvector
     (N : Dim_N; J : Index_N) return Vector
   is
      V : Vector (1 .. N);
   begin
      for I in 1 .. N loop
         V (I) :=
           Math.Sin (Pi * Real (J) * Real (I) / Real (N + 1));
      end loop;
      return V;
   end Laplacian_Exact_Eigenvector;

   function Fourier_Trial_Basis (N : Dim_N; K : Dim_K) return Basis is
      Q : Basis (1 .. N, 1 .. K);
   begin
      for J in 1 .. K loop
         declare
            V : constant Vector :=
              Laplacian_Exact_Eigenvector (N, Index_N (J));
            Nv : constant Non_Negative := Norm (V);
         begin
            for I in 1 .. N loop
               if Nv > 0.0 then
                  Q (I, Index_K (J)) := V (I) / Real (Nv);
               else
                  Q (I, Index_K (J)) := 0.0;
               end if;
            end loop;
         end;
      end loop;
      return Q;
   end Fourier_Trial_Basis;

   function Polynomial_Trial_Basis (N : Dim_N; K : Dim_K) return Basis is
      Q    : Basis (1 .. N, 1 .. K);
      Rank : Dim_K;
   begin
      for J in 1 .. K loop
         declare
            P : constant Natural := Natural (J) - 1;
         begin
            for I in 1 .. N loop
               declare
                  T : constant Real := Real (I) / Real (N + 1);
                  Val : Real := 1.0;
               begin
                  for M in 1 .. P loop
                     Val := Val * T;
                  end loop;
                  Q (I, Index_K (J)) := Val;
               end;
            end loop;
         end;
      end loop;
      Orthonormalize (Q, Rank, Tol => 1.0E-12, Raise_Rank => False);
      pragma Unreferenced (Rank);
      return Q;
   end Polynomial_Trial_Basis;

end Rayleigh_Ritz_Method;
