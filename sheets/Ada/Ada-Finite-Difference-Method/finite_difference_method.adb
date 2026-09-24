--  Finite_Difference_Method body — FD stencils, 1D Poisson (Thomas),
--  and one FTCS heat step.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Finite_Difference_Method
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

   --  Thomas TDMA for a_i x_{i-1} + b_i x_i + c_i x_{i+1} = d_i
   --  with a_1 = c_n = 0. Writes X(1 .. N). Raises on tiny pivot.
   procedure Thomas_Solve
     (A, B, C, D : Grid;
      X          : out Grid;
      N          : Positive)
   is
      Cp : Grid (1 .. N);
      Dp : Grid (1 .. N);
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
   -- First derivatives
   -------------------------------------------------------------------------

   function Diff_Forward (F : Grid; H : Real) return Grid is
      N      : constant Natural := F'Length;
      Result : Grid (1 .. N - 1);
      Lo     : constant Positive := F'First;
   begin
      Check_H (H);
      if N < 2 then
         raise Invalid_Argument;
      end if;
      for K in 1 .. N - 1 loop
         Result (K) := (F (Lo + K) - F (Lo + K - 1)) / H;
      end loop;
      return Result;
   end Diff_Forward;

   function Diff_Backward (F : Grid; H : Real) return Grid is
      N      : constant Natural := F'Length;
      Result : Grid (1 .. N - 1);
      Lo     : constant Positive := F'First;
   begin
      Check_H (H);
      if N < 2 then
         raise Invalid_Argument;
      end if;
      --  Result(k) approximates f' at index Lo+k (right of each pair)
      for K in 1 .. N - 1 loop
         Result (K) := (F (Lo + K) - F (Lo + K - 1)) / H;
      end loop;
      return Result;
   end Diff_Backward;

   function Diff_Central (F : Grid; H : Real) return Grid is
      N      : constant Natural := F'Length;
      Result : Grid (1 .. N - 2);
      Lo     : constant Positive := F'First;
      Two_H  : Real;
   begin
      Check_H (H);
      if N < 3 then
         raise Invalid_Argument;
      end if;
      Two_H := 2.0 * H;
      for K in 1 .. N - 2 loop
         --  interior index = Lo + K
         Result (K) := (F (Lo + K + 1) - F (Lo + K - 1)) / Two_H;
      end loop;
      return Result;
   end Diff_Central;

   -------------------------------------------------------------------------
   -- Second derivative
   -------------------------------------------------------------------------

   function Diff2_Central (F : Grid; H : Real) return Grid is
      N      : constant Natural := F'Length;
      Result : Grid (1 .. N - 2);
      Lo     : constant Positive := F'First;
      H2     : Real;
   begin
      Check_H (H);
      if N < 3 then
         raise Invalid_Argument;
      end if;
      H2 := H * H;
      for K in 1 .. N - 2 loop
         Result (K) :=
           (F (Lo + K + 1) - 2.0 * F (Lo + K) + F (Lo + K - 1)) / H2;
      end loop;
      return Result;
   end Diff2_Central;

   -------------------------------------------------------------------------
   -- 1D Poisson
   -------------------------------------------------------------------------

   function Solve_Poisson_1D
     (G       : Grid;
      H       : Real;
      U_Left  : Real := 0.0;
      U_Right : Real := 0.0) return Grid
   is
      N      : constant Natural := G'Length;
      H2     : Real;
      A, B, C, D, X_Int : Grid (1 .. N);
      U      : Grid (1 .. N + 2);
      G_Lo   : constant Positive := G'First;
   begin
      Check_H (H);
      if N < 1 then
         raise Invalid_Argument;
      end if;
      if N + 2 > Max_Points then
         raise Invalid_Argument;
      end if;

      H2 := H * H;

      --  (−1, 2, −1) / H² · u = g, with BC contribution on RHS
      for I in 1 .. N loop
         A (I) := -1.0;
         B (I) := 2.0;
         C (I) := -1.0;
         D (I) := G (G_Lo + I - 1) * H2;
      end loop;
      A (1) := 0.0;
      C (N) := 0.0;
      --  Fold Dirichlet: row 1 gains +U_Left, row N gains +U_Right
      --  because −(−U_Left) from the missing −u_0 term in
      --  (−u_0 + 2u_1 − u_2) = g_1 H²  ⇒  2u_1 − u_2 = g_1 H² + U_Left
      D (1) := D (1) + U_Left;
      D (N) := D (N) + U_Right;

      Thomas_Solve (A, B, C, D, X_Int, N);

      U (1) := U_Left;
      for I in 1 .. N loop
         U (I + 1) := X_Int (I);
      end loop;
      U (N + 2) := U_Right;
      return U;
   end Solve_Poisson_1D;

   -------------------------------------------------------------------------
   -- FTCS heat
   -------------------------------------------------------------------------

   function FTCS_Stable (R : Real) return Boolean is
   begin
      return R >= 0.0 and then R <= 0.5;
   end FTCS_Stable;

   function Heat_FTCS_Step (U : Grid; R : Real) return Grid is
      N      : constant Natural := U'Length;
      Result : Grid (1 .. N);
      Lo     : constant Positive := U'First;
      Uj, Ul, Ur : Real;
   begin
      if N < 3 then
         raise Invalid_Argument;
      end if;
      if R < 0.0 or else R > 0.5 then
         raise Invalid_Argument;
      end if;

      Result (1) := U (Lo);
      Result (N) := U (Lo + N - 1);
      for J in 2 .. N - 1 loop
         Ul := U (Lo + J - 2);
         Uj := U (Lo + J - 1);
         Ur := U (Lo + J);
         Result (J) := Uj + R * (Ul - 2.0 * Uj + Ur);
      end loop;
      return Result;
   end Heat_FTCS_Step;

end Finite_Difference_Method;
