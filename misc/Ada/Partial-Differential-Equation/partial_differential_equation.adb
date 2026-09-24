--  Partial_Differential_Equation body — classification, Poisson (Thomas),
--  FTCS heat, upwind advection, and leapfrog wave sketches.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Partial_Differential_Equation
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

   procedure Check_Dt (Dt : Real) is
   begin
      if Dt <= 0.0 then
         raise Invalid_Argument;
      end if;
   end Check_Dt;

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
   -- Taxonomy
   -------------------------------------------------------------------------

   function Classify_2nd_Order (A, B, C : Real) return PDE_Class is
      Disc : Real;
   begin
      if A = 0.0 and then B = 0.0 and then C = 0.0 then
         return Degenerate;
      end if;
      Disc := B * B - A * C;
      if abs (Disc) <= Discriminant_Tol then
         return Parabolic;
      elsif Disc < 0.0 then
         return Elliptic;
      else
         return Hyperbolic;
      end if;
   end Classify_2nd_Order;

   function Class_Name (C : PDE_Class) return String is
   begin
      case C is
         when Elliptic    => return "Elliptic";
         when Parabolic   => return "Parabolic";
         when Hyperbolic  => return "Hyperbolic";
         when Degenerate  => return "Degenerate";
      end case;
   end Class_Name;

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
   -- Elliptic: 1D Poisson
   -------------------------------------------------------------------------

   function Solve_Poisson_1D
     (G     : Grid;
      Left  : Real;
      Right : Real;
      H     : Real) return Grid
   is
      N               : constant Natural := G'Length;
      H2              : Real;
      A, B, C, D, X_Int : Grid (1 .. N);
      U               : Grid (1 .. N + 2);
      G_Lo            : constant Positive := G'First;
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
      D (1) := D (1) + Left;
      D (N) := D (N) + Right;

      Thomas_Solve (A, B, C, D, X_Int, N);

      U (1) := Left;
      for I in 1 .. N loop
         U (I + 1) := X_Int (I);
      end loop;
      U (N + 2) := Right;
      return U;
   end Solve_Poisson_1D;

   -------------------------------------------------------------------------
   -- Parabolic: FTCS heat
   -------------------------------------------------------------------------

   function Heat_FTCS_Stable (Alpha, H, Dt : Real) return Boolean is
      R : Real;
   begin
      if Alpha < 0.0 or else H <= 0.0 or else Dt <= 0.0 then
         return False;
      end if;
      R := Alpha * Dt / (H * H);
      return R <= 0.5;
   end Heat_FTCS_Stable;

   function Heat_FTCS_Step
     (U            : Grid;
      Alpha, H, Dt : Real;
      Left, Right  : Real) return Grid
   is
      N      : constant Natural := U'Length;
      Result : Grid (1 .. N);
      Lo     : constant Positive := U'First;
      R      : Real;
      Uj, Ul, Ur : Real;
   begin
      Check_H (H);
      Check_Dt (Dt);
      if N < 3 then
         raise Invalid_Argument;
      end if;
      if Alpha < 0.0 then
         raise Invalid_Argument;
      end if;
      R := Alpha * Dt / (H * H);
      if R > 0.5 then
         raise Invalid_Argument;
      end if;

      Result (1) := Left;
      Result (N) := Right;
      for J in 2 .. N - 1 loop
         Ul := U (Lo + J - 2);
         Uj := U (Lo + J - 1);
         Ur := U (Lo + J);
         Result (J) := Uj + R * (Ul - 2.0 * Uj + Ur);
      end loop;
      return Result;
   end Heat_FTCS_Step;

   -------------------------------------------------------------------------
   -- Hyperbolic: CFL helpers, upwind advection, leapfrog wave
   -------------------------------------------------------------------------

   function CFL_Advection (C, H, Dt : Real) return Real is
   begin
      Check_H (H);
      Check_Dt (Dt);
      return C * Dt / H;
   end CFL_Advection;

   function CFL_Wave (C, H, Dt : Real) return Real is
   begin
      Check_H (H);
      Check_Dt (Dt);
      return abs (C) * Dt / H;
   end CFL_Wave;

   function Advection_Upwind_Step
     (U        : Grid;
      C, H, Dt : Real) return Grid
   is
      N      : constant Natural := U'Length;
      Result : Grid (1 .. N);
      Lo     : constant Positive := U'First;
      Nu     : Real;
      Uj, Ul : Real;
   begin
      Check_H (H);
      Check_Dt (Dt);
      if C < 0.0 then
         raise Invalid_Argument;
      end if;
      if N < 2 then
         raise Invalid_Argument;
      end if;
      Nu := C * Dt / H;
      if Nu > 1.0 then
         raise Invalid_Argument;
      end if;

      --  Inflow Dirichlet at left; upwind for j = 2 .. N
      Result (1) := U (Lo);
      for J in 2 .. N loop
         Ul := U (Lo + J - 2);
         Uj := U (Lo + J - 1);
         Result (J) := Uj - Nu * (Uj - Ul);
      end loop;
      return Result;
   end Advection_Upwind_Step;

   function Wave_Leapfrog_Step
     (U_Curr, U_Prev : Grid;
      C, H, Dt       : Real;
      Left, Right    : Real) return Grid
   is
      N      : constant Natural := U_Curr'Length;
      Result : Grid (1 .. N);
      Lo_C   : constant Positive := U_Curr'First;
      Lo_P   : constant Positive := U_Prev'First;
      Lam2   : Real;
      Uj, Ul, Ur, Up : Real;
   begin
      Check_H (H);
      Check_Dt (Dt);
      if N < 3 then
         raise Invalid_Argument;
      end if;
      if U_Prev'Length /= N then
         raise Invalid_Argument;
      end if;
      Lam2 := (C * Dt / H) ** 2;
      if abs (C) * Dt / H > 1.0 then
         raise Invalid_Argument;
      end if;

      Result (1) := Left;
      Result (N) := Right;
      for J in 2 .. N - 1 loop
         Ul := U_Curr (Lo_C + J - 2);
         Uj := U_Curr (Lo_C + J - 1);
         Ur := U_Curr (Lo_C + J);
         Up := U_Prev (Lo_P + J - 1);
         Result (J) := 2.0 * Uj - Up + Lam2 * (Ul - 2.0 * Uj + Ur);
      end loop;
      return Result;
   end Wave_Leapfrog_Step;

end Partial_Differential_Equation;
