--  Crank_Nicolson body — CN heat step (embedded Thomas), advance,
--  r-parameter and Fourier amplification helpers.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Crank_Nicolson
  with SPARK_Mode => Off
is

   package Elem is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Elem;

   -------------------------------------------------------------------------
   -- Local helpers
   -------------------------------------------------------------------------

   procedure Check_H (H : Real) is
   begin
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;
   end Check_H;

   procedure Check_Positive (X : Real) is
   begin
      if X <= 0.0 then
         raise Invalid_Argument;
      end if;
   end Check_Positive;

   --  Thomas TDMA for a_i x_{i-1} + b_i x_i + c_i x_{i+1} = d_i
   --  with a_1 = c_n = 0. Writes X(1 .. N). Raises on tiny pivot.
   procedure Thomas_Solve
     (A, B, C, D : Grid;
      X          : out Grid;
      N          : Positive)
   is
      Cp    : Grid (1 .. N);
      Dp    : Grid (1 .. N);
      Denom : Real;
   begin
      if abs (B (B'First)) <= Pivot_Tol then
         raise Invalid_Argument;
      end if;
      Cp (1) := C (C'First) / B (B'First);
      Dp (1) := D (D'First) / B (B'First);

      for I in 2 .. N loop
         Denom := B (B'First + I - 1)
           - A (A'First + I - 1) * Cp (I - 1);
         if abs (Denom) <= Pivot_Tol then
            raise Invalid_Argument;
         end if;
         if I < N then
            Cp (I) := C (C'First + I - 1) / Denom;
         else
            Cp (I) := 0.0;
         end if;
         Dp (I) :=
           (D (D'First + I - 1) - A (A'First + I - 1) * Dp (I - 1))
           / Denom;
      end loop;

      X (X'First + N - 1) := Dp (N);
      for I in reverse 1 .. N - 1 loop
         X (X'First + I - 1) := Dp (I) - Cp (I) * X (X'First + I);
      end loop;
   end Thomas_Solve;

   -------------------------------------------------------------------------
   -- Numeric helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Abs_Error (Approx, Exact : Real) return Non_Negative is
   begin
      return abs (Approx - Exact);
   end Abs_Error;

   function Vec_Near
     (A, B : Grid; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in A'Range loop
         if abs (A (I) - B (I - A'First + B'First)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Vec_Near;

   function L2_Error
     (U, Exact : Grid; H : Real) return Non_Negative
   is
      Sum : Real := 0.0;
      D   : Real;
      Lo  : constant Positive := Exact'First;
   begin
      Check_H (H);
      if U'Length /= Exact'Length then
         raise Invalid_Argument;
      end if;
      for I in U'Range loop
         D := U (I) - Exact (Lo + (I - U'First));
         Sum := Sum + D * D;
      end loop;
      return Sqrt (H * Sum);
   end L2_Error;

   function Max_Error (U, Exact : Grid) return Non_Negative is
      M  : Real := 0.0;
      D  : Real;
      Lo : constant Positive := Exact'First;
   begin
      if U'Length /= Exact'Length then
         raise Invalid_Argument;
      end if;
      for I in U'Range loop
         D := abs (U (I) - Exact (Lo + (I - U'First)));
         if D > M then
            M := D;
         end if;
      end loop;
      return M;
   end Max_Error;

   -------------------------------------------------------------------------
   -- Geometry / sampling
   -------------------------------------------------------------------------

   function X_At (X_Min, H : Real; J : Positive) return Real is
   begin
      Check_H (H);
      return X_Min + Real (J - 1) * H;
   end X_At;

   function Sample
     (N     : Point_Count;
      H     : Real;
      X_Min : Real := 0.0) return Grid
   is
      Result : Grid (1 .. N);
   begin
      Check_H (H);
      for J in 1 .. N loop
         Result (J) := F (X_At (X_Min, H, J));
      end loop;
      return Result;
   end Sample;

   -------------------------------------------------------------------------
   -- r-parameter and stability
   -------------------------------------------------------------------------

   function R_Param (Alpha, Dt, H : Real) return Real is
   begin
      Check_Positive (Alpha);
      Check_Positive (Dt);
      Check_H (H);
      return Alpha * Dt / (2.0 * H * H);
   end R_Param;

   function Amplification_Factor (R, Theta : Real) return Real is
      S, Four_R_S2, Num, Den : Real;
   begin
      if R < 0.0 then
         raise Invalid_Argument;
      end if;
      S := Sin (Theta / 2.0);
      Four_R_S2 := 4.0 * R * S * S;
      Num := 1.0 - Four_R_S2;
      Den := 1.0 + Four_R_S2;
      --  Den ≥ 1 for R ≥ 0; never zero.
      return Num / Den;
   end Amplification_Factor;

   function Amplification_Bounded
     (R, Theta : Real; Tol : Real := Epsilon_Tol) return Boolean
   is
      A : Real;
   begin
      A := Amplification_Factor (R, Theta);
      return abs (A) <= 1.0 + Tol;
   end Amplification_Bounded;

   function Unconditionally_Stable (R : Real) return Boolean is
      --  Representative phases covering low / mid / Nyquist modes.
      Thetas : constant array (1 .. 6) of Real :=
        [0.01, 0.25, 0.5, 1.0, 2.0, 3.141592653589793];
   begin
      if R < 0.0 then
         raise Invalid_Argument;
      end if;
      for K in Thetas'Range loop
         if not Amplification_Bounded (R, Thetas (K)) then
            return False;
         end if;
      end loop;
      return True;
   end Unconditionally_Stable;

   -------------------------------------------------------------------------
   -- Heat CN step / advance
   -------------------------------------------------------------------------

   function Heat_CN_Step
     (U        : Grid;
      H        : Real;
      Dt       : Real;
      Alpha    : Real;
      Left_BC  : Real := 0.0;
      Right_BC : Real := 0.0) return Grid
   is
      N      : constant Natural := U'Length;
      M      : Natural;  -- interior count = N - 2
      R      : Real;
      Lo     : constant Positive := U'First;
      Hi     : constant Positive := U'Last;
      A, B, C, D : Grid (1 .. Max_Points);
      Result : Grid (Lo .. Hi);
      U_Jm1, U_J, U_Jp1 : Real;
      RHS               : Real;
   begin
      Check_H (H);
      Check_Positive (Dt);
      Check_Positive (Alpha);
      if N < 3 or else N > Max_Points then
         raise Invalid_Argument;
      end if;

      M := N - 2;
      R := Alpha * Dt / (2.0 * H * H);

      --  Assemble interior tridiagonal (indices 1 .. M map to grid
      --  indices Lo+1 .. Lo+N-2).
      for I in 1 .. M loop
         A (I) := -R;
         B (I) := 1.0 + 2.0 * R;
         C (I) := -R;
         --  Full-grid neighbour indices for the known time level.
         U_Jm1 := U (Lo + I - 1);       -- j-1  (I=1 → Lo, boundary)
         U_J   := U (Lo + I);           -- j
         U_Jp1 := U (Lo + I + 1);       -- j+1
         RHS := R * U_Jm1 + (1.0 - 2.0 * R) * U_J + R * U_Jp1;
         D (I) := RHS;
      end loop;
      A (1) := 0.0;
      C (M) := 0.0;
      --  Fold next-time Dirichlet into RHS:
      --  −r U_left^{n+1} moves to +r Left_BC on the first row, etc.
      D (1) := D (1) + R * Left_BC;
      D (M) := D (M) + R * Right_BC;

      declare
         A_Int : constant Grid := A (1 .. M);
         B_Int : constant Grid := B (1 .. M);
         C_Int : constant Grid := C (1 .. M);
         D_Int : constant Grid := D (1 .. M);
         X_Sol : Grid (1 .. M);
      begin
         Thomas_Solve (A_Int, B_Int, C_Int, D_Int, X_Sol, M);
         Result (Lo) := Left_BC;
         for I in 1 .. M loop
            Result (Lo + I) := X_Sol (I);
         end loop;
         Result (Hi) := Right_BC;
      end;

      return Result;
   end Heat_CN_Step;

   function Heat_CN_Advance
     (U0       : Grid;
      H        : Real;
      Dt       : Real;
      Alpha    : Real;
      N_Steps  : Positive;
      Left_BC  : Real := 0.0;
      Right_BC : Real := 0.0) return Grid
   is
      U : Grid (U0'Range) := U0;
   begin
      for S in 1 .. N_Steps loop
         U := Heat_CN_Step (U, H, Dt, Alpha, Left_BC, Right_BC);
      end loop;
      return U;
   end Heat_CN_Advance;

end Crank_Nicolson;
