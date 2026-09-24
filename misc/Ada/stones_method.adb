--  Stones_Method body — Stone SIP (1968) incomplete LU + residual
--  iteration; dense ILU(0) variant; Jacobi / Gauss–Seidel comparison.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Stones_Method is

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

   function Make_Poisson_2D (N_Grid : Dimension) return Pentadiagonal is
      P : Pentadiagonal;
      N : constant Positive := N_Grid * N_Grid;
   begin
      P.N_Grid := N_Grid;
      P.N      := N;
      for I in 1 .. N loop
         P.A_P (I) := 4.0;
         P.A_W (I) := 0.0;
         P.A_E (I) := 0.0;
         P.A_S (I) := 0.0;
         P.A_N (I) := 0.0;
         --  West / East (same row)
         if (I - 1) mod N_Grid /= 0 then
            P.A_W (I) := -1.0;
         end if;
         if I mod N_Grid /= 0 then
            P.A_E (I) := -1.0;
         end if;
         --  South / North (previous / next row)
         if I > N_Grid then
            P.A_S (I) := -1.0;
         end if;
         if I + N_Grid <= N then
            P.A_N (I) := -1.0;
         end if;
      end loop;
      return P;
   end Make_Poisson_2D;

   function Pentadiagonal_To_Dense (P : Pentadiagonal) return Matrix is
      N  : constant Positive := P.N;
      NG : constant Positive := P.N_Grid;
      A  : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         A (I, I) := P.A_P (I);
         if P.A_W (I) /= 0.0 then
            A (I, I - 1) := P.A_W (I);
         end if;
         if P.A_E (I) /= 0.0 then
            A (I, I + 1) := P.A_E (I);
         end if;
         if P.A_S (I) /= 0.0 then
            A (I, I - NG) := P.A_S (I);
         end if;
         if P.A_N (I) /= 0.0 then
            A (I, I + NG) := P.A_N (I);
         end if;
      end loop;
      return A;
   end Pentadiagonal_To_Dense;

   function Make_Example
     (Kind : Example_Kind; N : Dimension) return Matrix
   is
   begin
      case Kind is
         when Poisson_2D =>
            return Pentadiagonal_To_Dense (Make_Poisson_2D (N));
         when Diagonally_Dominant =>
            declare
               A : Matrix (1 .. N, 1 .. N) :=
                 [others => [others => 0.0]];
            begin
               for I in 1 .. N loop
                  for J in 1 .. N loop
                     if I = J then
                        A (I, J) := Float (N);
                     else
                        A (I, J) := 1.0;
                     end if;
                  end loop;
               end loop;
               return A;
            end;
         when Poisson_1D =>
            declare
               A : Matrix (1 .. N, 1 .. N) :=
                 [others => [others => 0.0]];
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
            end;
      end case;
   end Make_Example;

   function Make_RHS_Ones (N : Dimension) return Vector is
   begin
      return [for I in 1 .. N => 1.0];
   end Make_RHS_Ones;

   function Zero_Vector (N : Dimension) return Vector is
   begin
      return [for I in 1 .. N => 0.0];
   end Zero_Vector;

   function Make_RHS_From_Solution
     (A : Matrix; X_Star : Vector) return Vector
   is
   begin
      return Mat_Vec (A, X_Star);
   end Make_RHS_From_Solution;

   function Apply_Pentadiagonal
     (P : Pentadiagonal; X : Vector) return Vector
   is
      N  : constant Positive := P.N;
      NG : constant Positive := P.N_Grid;
      Y  : Vector (1 .. N) := [others => 0.0];
   begin
      for I in 1 .. N loop
         declare
            Acc : Float := P.A_P (I) * X (I);
         begin
            if P.A_W (I) /= 0.0 then
               Acc := Acc + P.A_W (I) * X (I - 1);
            end if;
            if P.A_E (I) /= 0.0 then
               Acc := Acc + P.A_E (I) * X (I + 1);
            end if;
            if P.A_S (I) /= 0.0 then
               Acc := Acc + P.A_S (I) * X (I - NG);
            end if;
            if P.A_N (I) /= 0.0 then
               Acc := Acc + P.A_N (I) * X (I + NG);
            end if;
            Y (I) := Acc;
         end;
      end loop;
      return Y;
   end Apply_Pentadiagonal;

   function Make_RHS_From_Solution
     (P : Pentadiagonal; X_Star : Vector) return Vector
   is
   begin
      return Apply_Pentadiagonal (P, X_Star);
   end Make_RHS_From_Solution;

   function Residual_Penta
     (P : Pentadiagonal; X, B : Vector) return Vector
   is
   begin
      return Sub (B, Apply_Pentadiagonal (P, X));
   end Residual_Penta;

   function Residual_Norm_Penta
     (P : Pentadiagonal; X, B : Vector) return Float
   is
   begin
      return Norm2 (Residual_Penta (P, X, B));
   end Residual_Norm_Penta;

   -------------------------------------------------------------------------
   -- Stone SIP factorization (five-point / Option A)
   -------------------------------------------------------------------------
   --
   --  Following the classical SIP construction for a five-point stencil
   --  (Stone 1968; Ferziger & Perić): L has (LW, LS, LP), U has unit
   --  diagonal plus (UE, UN). Neglected NW / SE fill contributions are
   --  approximately cancelled by modifying the diagonal with Alpha:
   --
   --    LW_i = A_W,i / (1 + Alpha * UN_{i-1})
   --    LS_i = A_S,i / (1 + Alpha * UE_{i-N})
   --    P1   = Alpha * LW_i * UN_{i-1}
   --    P2   = Alpha * LS_i * UE_{i-N}
   --    LP_i = A_P,i + P1 + P2 - LW_i * UE_{i-1} - LS_i * UN_{i-N}
   --    UE_i = (A_E,i - P1) / LP_i
   --    UN_i = (A_N,i - P2) / LP_i
   --
   --  Exact published formulae vary slightly by reference; this package
   --  uses the widely taught CFD form above.

   function Factor_SIP
     (P : Pentadiagonal; Alpha : Float := 0.92) return SIP_Factors
   is
      F  : SIP_Factors;
      N  : constant Positive := P.N;
      NG : constant Positive := P.N_Grid;
   begin
      F.N_Grid := NG;
      F.N      := N;
      F.Alpha  := Alpha;
      F.Valid  := False;

      for I in 1 .. N loop
         declare
            UN_W : Float := 0.0;
            UE_S : Float := 0.0;
            UE_W : Float := 0.0;
            UN_S : Float := 0.0;
            LW, LS, LP, UE, UN, P1, P2 : Float;
         begin
            --  Neighbours by grid index (not by coefficient), so boundary
            --  rows never read off-grid factor entries.
            if (I - 1) mod NG /= 0 then
               UN_W := F.U_N (I - 1);
               UE_W := F.U_E (I - 1);
            end if;
            if I > NG then
               UE_S := F.U_E (I - NG);
               UN_S := F.U_N (I - NG);
            end if;

            LW := P.A_W (I) / (1.0 + Alpha * UN_W);
            LS := P.A_S (I) / (1.0 + Alpha * UE_S);
            P1 := Alpha * LW * UN_W;
            P2 := Alpha * LS * UE_S;
            LP := P.A_P (I) + P1 + P2 - LW * UE_W - LS * UN_S;

            if abs (LP) < Diagonal_Tol then
               return F;  -- Valid remains False
            end if;

            --  Store UE/UN even on the east/north boundary (unused in
            --  back-substitution); keeps Stone diagonal compensation
            --  consistent with interior formulae.
            UE := (P.A_E (I) - P1) / LP;
            UN := (P.A_N (I) - P2) / LP;

            F.L_W (I) := LW;
            F.L_S (I) := LS;
            F.L_P (I) := LP;
            F.U_E (I) := UE;
            F.U_N (I) := UN;
         end;
      end loop;

      F.Valid := True;
      return F;
   end Factor_SIP;

   function Apply_SIP_Preconditioner
     (F : SIP_Factors; R : Vector) return Vector
   is
      N  : constant Positive := F.N;
      NG : constant Positive := F.N_Grid;
      Y  : Vector (1 .. N) := [others => 0.0];  -- forward: L y = r
      Z  : Vector (1 .. N) := [others => 0.0];  -- back:    U z = y
   begin
      --  Forward substitution: L y = r
      --  (LW y_{i-1} + LS y_{i-N} + LP y_i = r_i)
      for I in 1 .. N loop
         declare
            Acc : Float := R (I);
         begin
            if (I - 1) mod NG /= 0 then
               Acc := Acc - F.L_W (I) * Y (I - 1);
            end if;
            if I > NG then
               Acc := Acc - F.L_S (I) * Y (I - NG);
            end if;
            Y (I) := Acc / F.L_P (I);
         end;
      end loop;

      --  Back substitution: U z = y  (unit diagonal + UE, UN)
      --  z_i + UE z_{i+1} + UN z_{i+N} = y_i
      for I in reverse 1 .. N loop
         declare
            Acc : Float := Y (I);
         begin
            if I mod NG /= 0 then
               Acc := Acc - F.U_E (I) * Z (I + 1);
            end if;
            if I + NG <= N then
               Acc := Acc - F.U_N (I) * Z (I + NG);
            end if;
            Z (I) := Acc;
         end;
      end loop;

      return Z;
   end Apply_SIP_Preconditioner;

   function Solve_SIP
     (P      : Pentadiagonal;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
   is
      Res  : Result;
      N    : constant Positive := P.N;
      Budget : Natural;
      F    : SIP_Factors;
      X    : Vector (1 .. N);
      R, Z : Vector (1 .. N);
      Rn   : Float;
   begin
      Res.N := N;

      if Params.Alpha < 0.0 or else Params.Alpha > 1.0 then
         Res.Stat := Bad_Alpha;
         return Res;
      end if;

      if Params.Max_Iter = 0 then
         Budget := Default_Max_Iter;
      else
         Budget := Params.Max_Iter;
      end if;

      F := Factor_SIP (P, Params.Alpha);
      if not F.Valid then
         Res.Stat := Factorization_Failed;
         return Res;
      end if;

      if X0'Length = 0 then
         X := [others => 0.0];
      else
         for I in 1 .. N loop
            X (I) := X0 (X0'First + I - 1);
         end loop;
      end if;

      for K in 1 .. Budget loop
         R  := Residual_Penta (P, X, B);
         Rn := Norm2 (R);
         if Rn <= Params.Tol then
            for I in 1 .. N loop
               Res.X (I) := X (I);
            end loop;
            Res.Iterations := K - 1;
            Res.Residual   := Rn;
            Res.Stat       := Converged;
            Res.Success    := True;
            return Res;
         end if;

         Z := Apply_SIP_Preconditioner (F, R);
         for I in 1 .. N loop
            X (I) := X (I) + Z (I);
         end loop;
      end loop;

      R  := Residual_Penta (P, X, B);
      Rn := Norm2 (R);
      for I in 1 .. N loop
         Res.X (I) := X (I);
      end loop;
      Res.Iterations := Budget;
      Res.Residual   := Rn;
      if Rn <= Params.Tol then
         Res.Stat    := Converged;
         Res.Success := True;
      else
         Res.Stat    := Iteration_Limit;
         Res.Success := False;
      end if;
      return Res;
   end Solve_SIP;

   -------------------------------------------------------------------------
   -- Dense ILU(0) with optional Stone row-sum compensation (Option B)
   -------------------------------------------------------------------------

   function Factor_ILU0
     (A : Matrix; Alpha : Float := 0.0) return Dense_ILU
   is
      N : constant Positive := A'Length (1);
      F : Dense_ILU;
      --  Work copy; after factorization (Doolittle ILU(0)):
      --    lower M(i,k) = L multipliers, diag/upper = U (pivots on diag).
      M : Matrix (1 .. N, 1 .. N);
   begin
      F.N     := N;
      F.Alpha := Alpha;
      F.Valid := False;

      for I in 1 .. N loop
         for J in 1 .. N loop
            M (I, J) :=
              A (A'First (1) + I - 1, A'First (2) + J - 1);
         end loop;
      end loop;

      --  Doolittle-style ILU(0): update only where A is nonzero.
      for I in 1 .. N loop
         for K in 1 .. I - 1 loop
            if abs (A (A'First (1) + I - 1,
                       A'First (2) + K - 1)) > 0.0
              and then abs (M (K, K)) >= Diagonal_Tol
            then
               M (I, K) := M (I, K) / M (K, K);
               for J in K + 1 .. N loop
                  if abs (A (A'First (1) + I - 1,
                             A'First (2) + J - 1)) > 0.0
                  then
                     M (I, J) := M (I, J) - M (I, K) * M (K, J);
                  elsif Alpha > 0.0 then
                     --  Stone-ish: dump a fraction of neglected fill
                     --  onto the diagonal.
                     M (I, I) :=
                       M (I, I) - Alpha * M (I, K) * M (K, J);
                  end if;
               end loop;
            end if;
         end loop;
         if abs (M (I, I)) < Diagonal_Tol then
            return F;
         end if;
      end loop;

      --  Store Doolittle form: L unit-diagonal (multipliers below),
      --  U with pivots on the diagonal (upper as factored).
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I > J then
               F.L (I, J) := M (I, J);
               F.U (I, J) := 0.0;
            elsif I = J then
               F.L (I, J) := 1.0;
               F.U (I, J) := M (I, J);
            else
               F.L (I, J) := 0.0;
               F.U (I, J) := M (I, J);
            end if;
         end loop;
      end loop;

      F.Valid := True;
      return F;
   end Factor_ILU0;

   function Apply_Dense_ILU
     (F : Dense_ILU; R : Vector) return Vector
   is
      N : constant Positive := F.N;
      Y : Vector (1 .. N) := [others => 0.0];
      Z : Vector (1 .. N) := [others => 0.0];
   begin
      --  Forward: L y = r  (unit diagonal L)
      for I in 1 .. N loop
         declare
            Acc : Float := R (I);
         begin
            for J in 1 .. I - 1 loop
               Acc := Acc - F.L (I, J) * Y (J);
            end loop;
            Y (I) := Acc;
         end;
      end loop;

      --  Back: U z = y  (pivots on U diagonal)
      for I in reverse 1 .. N loop
         declare
            Acc : Float := Y (I);
         begin
            for J in I + 1 .. N loop
               Acc := Acc - F.U (I, J) * Z (J);
            end loop;
            Z (I) := Acc / F.U (I, I);
         end;
      end loop;

      return Z;
   end Apply_Dense_ILU;

   function Solve_SIP_Dense
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
   is
      Res    : Result;
      N      : constant Positive := B'Length;
      Budget : Natural;
      F      : Dense_ILU;
      X      : Vector (1 .. N);
      R, Z   : Vector (1 .. N);
      Rn     : Float;
      A1     : Matrix (1 .. N, 1 .. N);
   begin
      Res.N := N;

      if Params.Alpha < 0.0 or else Params.Alpha > 1.0 then
         Res.Stat := Bad_Alpha;
         return Res;
      end if;

      for I in 1 .. N loop
         for J in 1 .. N loop
            A1 (I, J) :=
              A (A'First (1) + I - 1, A'First (2) + J - 1);
         end loop;
      end loop;

      if Params.Max_Iter = 0 then
         Budget := Default_Max_Iter;
      else
         Budget := Params.Max_Iter;
      end if;

      F := Factor_ILU0 (A1, Params.Alpha);
      if not F.Valid then
         Res.Stat := Factorization_Failed;
         return Res;
      end if;

      if X0'Length = 0 then
         X := [others => 0.0];
      else
         for I in 1 .. N loop
            X (I) := X0 (X0'First + I - 1);
         end loop;
      end if;

      for K in 1 .. Budget loop
         R  := Residual (A1, X, B);
         Rn := Norm2 (R);
         if Rn <= Params.Tol then
            for I in 1 .. N loop
               Res.X (I) := X (I);
            end loop;
            Res.Iterations := K - 1;
            Res.Residual   := Rn;
            Res.Stat       := Converged;
            Res.Success    := True;
            return Res;
         end if;

         Z := Apply_Dense_ILU (F, R);
         for I in 1 .. N loop
            X (I) := X (I) + Z (I);
         end loop;
      end loop;

      R  := Residual (A1, X, B);
      Rn := Norm2 (R);
      for I in 1 .. N loop
         Res.X (I) := X (I);
      end loop;
      Res.Iterations := Budget;
      Res.Residual   := Rn;
      if Rn <= Params.Tol then
         Res.Stat    := Converged;
         Res.Success := True;
      else
         Res.Stat    := Iteration_Limit;
         Res.Success := False;
      end if;
      return Res;
   end Solve_SIP_Dense;

   -------------------------------------------------------------------------
   -- Jacobi / Gauss–Seidel (dense comparison)
   -------------------------------------------------------------------------

   function Solve_Jacobi
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
   is
      Res    : Result;
      N      : constant Positive := B'Length;
      Budget : Natural;
      X, Xn  : Vector (1 .. N);
      Rn     : Float;
      A1     : Matrix (1 .. N, 1 .. N);
   begin
      Res.N := N;

      for I in 1 .. N loop
         for J in 1 .. N loop
            A1 (I, J) :=
              A (A'First (1) + I - 1, A'First (2) + J - 1);
         end loop;
      end loop;

      for I in 1 .. N loop
         if abs (A1 (I, I)) < Diagonal_Tol then
            Res.Stat := Zero_Diagonal;
            return Res;
         end if;
      end loop;

      if Params.Max_Iter = 0 then
         Budget := Default_Max_Iter;
      else
         Budget := Params.Max_Iter;
      end if;

      if X0'Length = 0 then
         X := [others => 0.0];
      else
         for I in 1 .. N loop
            X (I) := X0 (X0'First + I - 1);
         end loop;
      end if;

      for K in 1 .. Budget loop
         Rn := Residual_Norm (A1, X, B);
         if Rn <= Params.Tol then
            for I in 1 .. N loop
               Res.X (I) := X (I);
            end loop;
            Res.Iterations := K - 1;
            Res.Residual   := Rn;
            Res.Stat       := Converged;
            Res.Success    := True;
            return Res;
         end if;

         for I in 1 .. N loop
            declare
               Acc : Float := B (B'First + I - 1);
            begin
               for J in 1 .. N loop
                  if J /= I then
                     Acc := Acc - A1 (I, J) * X (J);
                  end if;
               end loop;
               Xn (I) := Acc / A1 (I, I);
            end;
         end loop;
         X := Xn;
      end loop;

      Rn := Residual_Norm (A1, X, B);
      for I in 1 .. N loop
         Res.X (I) := X (I);
      end loop;
      Res.Iterations := Budget;
      Res.Residual   := Rn;
      if Rn <= Params.Tol then
         Res.Stat    := Converged;
         Res.Success := True;
      else
         Res.Stat    := Iteration_Limit;
         Res.Success := False;
      end if;
      return Res;
   end Solve_Jacobi;

   function Solve_Gauss_Seidel
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
   is
      Res    : Result;
      N      : constant Positive := B'Length;
      Budget : Natural;
      X      : Vector (1 .. N);
      Rn     : Float;
      A1     : Matrix (1 .. N, 1 .. N);
   begin
      Res.N := N;

      for I in 1 .. N loop
         for J in 1 .. N loop
            A1 (I, J) :=
              A (A'First (1) + I - 1, A'First (2) + J - 1);
         end loop;
      end loop;

      for I in 1 .. N loop
         if abs (A1 (I, I)) < Diagonal_Tol then
            Res.Stat := Zero_Diagonal;
            return Res;
         end if;
      end loop;

      if Params.Max_Iter = 0 then
         Budget := Default_Max_Iter;
      else
         Budget := Params.Max_Iter;
      end if;

      if X0'Length = 0 then
         X := [others => 0.0];
      else
         for I in 1 .. N loop
            X (I) := X0 (X0'First + I - 1);
         end loop;
      end if;

      for K in 1 .. Budget loop
         Rn := Residual_Norm (A1, X, B);
         if Rn <= Params.Tol then
            for I in 1 .. N loop
               Res.X (I) := X (I);
            end loop;
            Res.Iterations := K - 1;
            Res.Residual   := Rn;
            Res.Stat       := Converged;
            Res.Success    := True;
            return Res;
         end if;

         for I in 1 .. N loop
            declare
               Acc : Float := B (B'First + I - 1);
            begin
               for J in 1 .. N loop
                  if J /= I then
                     Acc := Acc - A1 (I, J) * X (J);
                  end if;
               end loop;
               X (I) := Acc / A1 (I, I);
            end;
         end loop;
      end loop;

      Rn := Residual_Norm (A1, X, B);
      for I in 1 .. N loop
         Res.X (I) := X (I);
      end loop;
      Res.Iterations := Budget;
      Res.Residual   := Rn;
      if Rn <= Params.Tol then
         Res.Stat    := Converged;
         Res.Success := True;
      else
         Res.Stat    := Iteration_Limit;
         Res.Success := False;
      end if;
      return Res;
   end Solve_Gauss_Seidel;

end Stones_Method;
