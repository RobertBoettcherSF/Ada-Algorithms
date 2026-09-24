--  Linear_Multistep_Methods body — AB / AM / BDF steppers and Advance_*.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Linear_Multistep_Methods
  with SPARK_Mode => Off
is

   package Elem is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Elem;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Abs_Error (Approx, Exact : Real) return Non_Negative is
   begin
      return abs (Approx - Exact);
   end Abs_Error;

   function Exact_Exponential
     (Lambda, T : Real;
      Y0        : Real := 1.0) return Real
   is
   begin
      return Y0 * Exp (Lambda * T);
   end Exact_Exponential;

   -------------------------------------------------------------------------
   -- Taxonomy
   -------------------------------------------------------------------------

   function Method_Name (M : Method_Kind) return String is
   begin
      case M is
         when AB2 =>
            return "Adams-Bashforth 2";
         when AB3 =>
            return "Adams-Bashforth 3";
         when AB4 =>
            return "Adams-Bashforth 4";
         when AM2_Trapezoid =>
            return "Adams-Moulton 2 (trapezoid)";
         when AM3 =>
            return "Adams-Moulton 3";
         when BDF1 =>
            return "BDF1 (backward Euler)";
         when BDF2 =>
            return "BDF2";
      end case;
   end Method_Name;

   function Is_Explicit (M : Method_Kind) return Boolean is
   begin
      case M is
         when AB2 | AB3 | AB4 =>
            return True;
         when AM2_Trapezoid | AM3 | BDF1 | BDF2 =>
            return False;
      end case;
   end Is_Explicit;

   function Is_Implicit (M : Method_Kind) return Boolean is
   begin
      return not Is_Explicit (M);
   end Is_Implicit;

   function Order (M : Method_Kind) return Positive is
   begin
      case M is
         when AB2 | AM2_Trapezoid | BDF2 =>
            return 2;
         when AB3 | AM3 =>
            return 3;
         when AB4 =>
            return 4;
         when BDF1 =>
            return 1;
      end case;
   end Order;

   function Step_Number (M : Method_Kind) return Positive is
   begin
      --  Classical k in the LMS formula (number of steps).
      case M is
         when AB2 =>
            return 2;
         when AB3 =>
            return 3;
         when AB4 =>
            return 4;
         when AM2_Trapezoid =>
            return 1;
         when AM3 =>
            return 2;
         when BDF1 =>
            return 1;
         when BDF2 =>
            return 2;
      end case;
   end Step_Number;

   -------------------------------------------------------------------------
   -- Internal: classical RK4 bootstrap step (self-contained, no sibling with)
   -------------------------------------------------------------------------

   function RK4_Step
     (F : ODE_Fn;
      T : Real;
      Y : Real;
      H : Real) return Real
   is
      K1, K2, K3, K4 : Real;
      Half_H         : Real;
   begin
      Half_H := H * 0.5;
      K1 := F (T, Y);
      K2 := F (T + Half_H, Y + Half_H * K1);
      K3 := F (T + Half_H, Y + Half_H * K2);
      K4 := F (T + H, Y + H * K3);
      return Y + (H / 6.0) * (K1 + 2.0 * K2 + 2.0 * K3 + K4);
   end RK4_Step;

   function Euler_Step
     (F : ODE_Fn;
      T : Real;
      Y : Real;
      H : Real) return Real
   is
   begin
      return Y + H * F (T, Y);
   end Euler_Step;

   --  Finite-difference ∂f/∂y when no analytic Jacobian is supplied.
   function FD_Partial_Y
     (F : ODE_Fn;
      T : Real;
      Y : Real) return Real
   is
      Eps_Y : constant Real := 1.0E-8;
      Y2    : Real;
   begin
      if abs (Y) > 1.0 then
         Y2 := Y * (1.0 + Eps_Y);
      else
         Y2 := Y + Eps_Y;
      end if;
      if abs (Y2 - Y) < Real'Model_Small then
         Y2 := Y + Real'Model_Small * 1.0E6;
      end if;
      return (F (T, Y2) - F (T, Y)) / (Y2 - Y);
   end FD_Partial_Y;

   --  Solve Y_New = Explicit_Part + H_Coef * F(T_New, Y_New)
   --  by fixed-point or Newton. Raises Invalid_Argument on failure.
   function Solve_Implicit
     (F             : ODE_Fn;
      T_New         : Real;
      Explicit_Part : Real;
      H_Coef        : Real;
      Y_Guess       : Real;
      Cfg           : Config;
      DF_DY         : Partial_Y_Fn) return Real
   is
      Y_Cur, Y_Nxt, G, Gp, DFy : Real;
   begin
      Y_Cur := Y_Guess;
      for Iter in 1 .. Cfg.Max_Iterations loop
         case Cfg.Solver is
            when Fixed_Point =>
               Y_Nxt := Explicit_Part + H_Coef * F (T_New, Y_Cur);
            when Newton =>
               --  g(y) = y − Explicit_Part − H_Coef * f(T_New, y) = 0
               G := Y_Cur - Explicit_Part - H_Coef * F (T_New, Y_Cur);
               if DF_DY /= null then
                  DFy := DF_DY (T_New, Y_Cur);
               else
                  DFy := FD_Partial_Y (F, T_New, Y_Cur);
               end if;
               Gp := 1.0 - H_Coef * DFy;
               if abs (Gp) < 1.0E-30 then
                  raise Invalid_Argument;
               end if;
               Y_Nxt := Y_Cur - G / Gp;
         end case;
         if abs (Y_Nxt - Y_Cur) <= Cfg.Tol then
            return Y_Nxt;
         end if;
         Y_Cur := Y_Nxt;
      end loop;
      raise Invalid_Argument;
   end Solve_Implicit;

   -------------------------------------------------------------------------
   -- Adams–Bashforth
   -------------------------------------------------------------------------

   function Adams_Bashforth_2_Step
     (F      : ODE_Fn;
      T      : Real;
      Y      : Real;
      F_Prev : Real;
      H      : Real) return Real
   is
      F_N : Real;
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;
      F_N := F (T, Y);
      return Y + H * (AB2_Beta_N * F_N + AB2_Beta_Nm1 * F_Prev);
   end Adams_Bashforth_2_Step;

   function Adams_Bashforth_3_Step
     (F      : ODE_Fn;
      T      : Real;
      Y      : Real;
      F_Hist : History;
      H      : Real) return Real
   is
      F_N, F_Nm1, F_Nm2 : Real;
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;
      if F_Hist'Length = 2 then
         F_N   := F (T, Y);
         F_Nm1 := F_Hist (F_Hist'First);
         F_Nm2 := F_Hist (F_Hist'First + 1);
      elsif F_Hist'Length = 3 then
         F_N   := F_Hist (F_Hist'First);
         F_Nm1 := F_Hist (F_Hist'First + 1);
         F_Nm2 := F_Hist (F_Hist'First + 2);
      else
         raise Invalid_Argument;
      end if;
      return Y
        + H
            * (AB3_Beta_N * F_N
               + AB3_Beta_Nm1 * F_Nm1
               + AB3_Beta_Nm2 * F_Nm2);
   end Adams_Bashforth_3_Step;

   function Adams_Bashforth_4_Step
     (F      : ODE_Fn;
      T      : Real;
      Y      : Real;
      F_Hist : History;
      H      : Real) return Real
   is
      F_N, F_Nm1, F_Nm2, F_Nm3 : Real;
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;
      if F_Hist'Length = 3 then
         F_N   := F (T, Y);
         F_Nm1 := F_Hist (F_Hist'First);
         F_Nm2 := F_Hist (F_Hist'First + 1);
         F_Nm3 := F_Hist (F_Hist'First + 2);
      elsif F_Hist'Length = 4 then
         F_N   := F_Hist (F_Hist'First);
         F_Nm1 := F_Hist (F_Hist'First + 1);
         F_Nm2 := F_Hist (F_Hist'First + 2);
         F_Nm3 := F_Hist (F_Hist'First + 3);
      else
         raise Invalid_Argument;
      end if;
      return Y
        + H
            * (AB4_Beta_N * F_N
               + AB4_Beta_Nm1 * F_Nm1
               + AB4_Beta_Nm2 * F_Nm2
               + AB4_Beta_Nm3 * F_Nm3);
   end Adams_Bashforth_4_Step;

   -------------------------------------------------------------------------
   -- Adams–Moulton / BDF
   -------------------------------------------------------------------------

   function Adams_Moulton_2_Step
     (F     : ODE_Fn;
      T     : Real;
      Y     : Real;
      H     : Real;
      Cfg   : Config       := (others => <>);
      DF_DY : Partial_Y_Fn := null) return Real
   is
      F_N     : Real;
      Explicit : Real;
      Guess   : Real;
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;
      F_N      := F (T, Y);
      Explicit := Y + H * AM2_Beta_N * F_N;
      Guess    := Euler_Step (F, T, Y, H);
      return Solve_Implicit
        (F, T + H, Explicit, H * AM2_Beta_Np1, Guess, Cfg, DF_DY);
   end Adams_Moulton_2_Step;

   function Adams_Moulton_3_Step
     (F      : ODE_Fn;
      T      : Real;
      Y      : Real;
      F_Prev : Real;
      H      : Real;
      Cfg    : Config       := (others => <>);
      DF_DY  : Partial_Y_Fn := null) return Real
   is
      F_N      : Real;
      Explicit : Real;
      Guess    : Real;
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;
      F_N      := F (T, Y);
      Explicit :=
        Y + H * (AM3_Beta_N * F_N + AM3_Beta_Nm1 * F_Prev);
      Guess := Euler_Step (F, T, Y, H);
      return Solve_Implicit
        (F, T + H, Explicit, H * AM3_Beta_Np1, Guess, Cfg, DF_DY);
   end Adams_Moulton_3_Step;

   function BDF1_Step
     (F     : ODE_Fn;
      T     : Real;
      Y     : Real;
      H     : Real;
      Cfg   : Config       := (others => <>);
      DF_DY : Partial_Y_Fn := null) return Real
   is
      Guess : Real;
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;
      Guess := Euler_Step (F, T, Y, H);
      --  y_new = y + h f(t+h, y_new)  ⇒  Explicit_Part = Y, H_Coef = H
      return Solve_Implicit (F, T + H, Y, H, Guess, Cfg, DF_DY);
   end BDF1_Step;

   function BDF2_Step
     (F      : ODE_Fn;
      T      : Real;
      Y      : Real;
      Y_Prev : Real;
      H      : Real;
      Cfg    : Config       := (others => <>);
      DF_DY  : Partial_Y_Fn := null) return Real
   is
      Explicit : Real;
      Guess    : Real;
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;
      --  y_new = (4/3) Y − (1/3) Y_Prev + (2/3) h f(t+h, y_new)
      Explicit := (4.0 / 3.0) * Y - (1.0 / 3.0) * Y_Prev;
      Guess    := Euler_Step (F, T, Y, H);
      return Solve_Implicit
        (F, T + H, Explicit, (2.0 / 3.0) * H, Guess, Cfg, DF_DY);
   end BDF2_Step;

   -------------------------------------------------------------------------
   -- Advance_* (bootstrap with RK4 for the first k−1 steps)
   -------------------------------------------------------------------------

   procedure Require_Interval (F : ODE_Fn; T0, T1 : Real) is
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if T1 <= T0 then
         raise Invalid_Argument;
      end if;
   end Require_Interval;

   function Advance_AB2
     (F  : ODE_Fn;
      T0 : Real;
      Y0 : Real;
      T1 : Real;
      N  : Positive) return Real
   is
      H     : Real;
      T     : Real := T0;
      Y     : Real := Y0;
      F_Cur : Real;
      F_Prv : Real;
      Y_New : Real;
   begin
      Require_Interval (F, T0, T1);
      if N < 2 then
         raise Invalid_Argument;
      end if;
      H     := (T1 - T0) / Real (N);
      F_Prv := F (T, Y);
      --  Bootstrap step 1 with classic RK4 (order ≥ AB2).
      Y     := RK4_Step (F, T, Y, H);
      T     := T0 + H;
      F_Cur := F (T, Y);
      for I in 2 .. N loop
         Y_New := Adams_Bashforth_2_Step (F, T, Y, F_Prv, H);
         F_Prv := F_Cur;
         Y     := Y_New;
         T     := T0 + Real (I) * H;
         F_Cur := F (T, Y);
      end loop;
      return Y;
   end Advance_AB2;

   function Advance_AB3
     (F  : ODE_Fn;
      T0 : Real;
      Y0 : Real;
      T1 : Real;
      N  : Positive) return Real
   is
      H              : Real;
      T              : Real := T0;
      Y              : Real := Y0;
      F0, F1, F2 : Real;
      Hist       : History (1 .. 2);
      Y_New      : Real;
   begin
      Require_Interval (F, T0, T1);
      if N < 3 then
         raise Invalid_Argument;
      end if;
      H  := (T1 - T0) / Real (N);
      F0 := F (T, Y);
      Y  := RK4_Step (F, T, Y, H);
      T  := T0 + H;
      F1 := F (T, Y);
      Y  := RK4_Step (F, T, Y, H);
      T  := T0 + 2.0 * H;
      F2 := F (T, Y);
      for I in 3 .. N loop
         Hist  := [F1, F0];
         Y_New := Adams_Bashforth_3_Step (F, T, Y, Hist, H);
         F0    := F1;
         F1    := F2;
         Y     := Y_New;
         T     := T0 + Real (I) * H;
         F2    := F (T, Y);
      end loop;
      return Y;
   end Advance_AB3;

   function Advance_AB4
     (F  : ODE_Fn;
      T0 : Real;
      Y0 : Real;
      T1 : Real;
      N  : Positive) return Real
   is
      H                    : Real;
      T                    : Real := T0;
      Y                    : Real := Y0;
      Fa, Fb, Fc, Fd       : Real;
      Hist                 : History (1 .. 3);
      Y_New                : Real;
   begin
      Require_Interval (F, T0, T1);
      if N < 4 then
         raise Invalid_Argument;
      end if;
      H  := (T1 - T0) / Real (N);
      Fa := F (T, Y);
      Y  := RK4_Step (F, T, Y, H);
      T  := T0 + H;
      Fb := F (T, Y);
      Y  := RK4_Step (F, T, Y, H);
      T  := T0 + 2.0 * H;
      Fc := F (T, Y);
      Y  := RK4_Step (F, T, Y, H);
      T  := T0 + 3.0 * H;
      Fd := F (T, Y);
      for I in 4 .. N loop
         Hist  := [Fc, Fb, Fa];
         Y_New := Adams_Bashforth_4_Step (F, T, Y, Hist, H);
         Fa    := Fb;
         Fb    := Fc;
         Fc    := Fd;
         Y     := Y_New;
         T     := T0 + Real (I) * H;
         Fd    := F (T, Y);
      end loop;
      return Y;
   end Advance_AB4;

   function Advance_AM2
     (F     : ODE_Fn;
      T0    : Real;
      Y0    : Real;
      T1    : Real;
      N     : Positive;
      Cfg   : Config       := (others => <>);
      DF_DY : Partial_Y_Fn := null) return Real
   is
      H : Real;
      T : Real := T0;
      Y : Real := Y0;
   begin
      Require_Interval (F, T0, T1);
      H := (T1 - T0) / Real (N);
      for I in 1 .. N loop
         Y := Adams_Moulton_2_Step (F, T, Y, H, Cfg, DF_DY);
         T := T0 + Real (I) * H;
      end loop;
      return Y;
   end Advance_AM2;

   function Advance_AM3
     (F     : ODE_Fn;
      T0    : Real;
      Y0    : Real;
      T1    : Real;
      N     : Positive;
      Cfg   : Config       := (others => <>);
      DF_DY : Partial_Y_Fn := null) return Real
   is
      H     : Real;
      T     : Real := T0;
      Y     : Real := Y0;
      F_Prv  : Real;
      F_Cur  : Real;
      Y_New  : Real;
   begin
      Require_Interval (F, T0, T1);
      if N < 2 then
         raise Invalid_Argument;
      end if;
      H     := (T1 - T0) / Real (N);
      F_Prv := F (T, Y);
      --  Bootstrap first step with AM2 (same family, order 2).
      Y     := Adams_Moulton_2_Step (F, T, Y, H, Cfg, DF_DY);
      T     := T0 + H;
      F_Cur := F (T, Y);
      for I in 2 .. N loop
         Y_New := Adams_Moulton_3_Step (F, T, Y, F_Prv, H, Cfg, DF_DY);
         F_Prv := F_Cur;
         Y     := Y_New;
         T     := T0 + Real (I) * H;
         F_Cur := F (T, Y);
      end loop;
      return Y;
   end Advance_AM3;

   function Advance_BDF1
     (F     : ODE_Fn;
      T0    : Real;
      Y0    : Real;
      T1    : Real;
      N     : Positive;
      Cfg   : Config       := (others => <>);
      DF_DY : Partial_Y_Fn := null) return Real
   is
      H : Real;
      T : Real := T0;
      Y : Real := Y0;
   begin
      Require_Interval (F, T0, T1);
      H := (T1 - T0) / Real (N);
      for I in 1 .. N loop
         Y := BDF1_Step (F, T, Y, H, Cfg, DF_DY);
         T := T0 + Real (I) * H;
      end loop;
      return Y;
   end Advance_BDF1;

   function Advance_BDF2
     (F     : ODE_Fn;
      T0    : Real;
      Y0    : Real;
      T1    : Real;
      N     : Positive;
      Cfg   : Config       := (others => <>);
      DF_DY : Partial_Y_Fn := null) return Real
   is
      H      : Real;
      T      : Real := T0;
      Y      : Real := Y0;
      Y_Prev : Real;
      Y_New  : Real;
   begin
      Require_Interval (F, T0, T1);
      if N < 2 then
         raise Invalid_Argument;
      end if;
      H      := (T1 - T0) / Real (N);
      Y_Prev := Y0;
      --  Bootstrap step 1 with BDF1 (backward Euler).
      Y      := BDF1_Step (F, T, Y, H, Cfg, DF_DY);
      T      := T0 + H;
      for I in 2 .. N loop
         Y_New  := BDF2_Step (F, T, Y, Y_Prev, H, Cfg, DF_DY);
         Y_Prev := Y;
         Y      := Y_New;
         T      := T0 + Real (I) * H;
      end loop;
      return Y;
   end Advance_BDF2;

   -------------------------------------------------------------------------
   -- Zero-stability / root condition
   -------------------------------------------------------------------------

   function Characteristic_Polynomial_Roots_OK
     (M : Method_Kind) return Boolean
   is
      --  For quadratic ρ(ζ) = a ζ² + b ζ + c, check root condition.
      function Quad_OK (A, B, C : Real) return Boolean is
         Disc, R1, R2, Sqrt_D : Real;
      begin
         if abs (A) < 1.0E-30 then
            --  Degenerate linear: A≈0 → B ζ + C = 0 → ζ = −C/B
            if abs (B) < 1.0E-30 then
               return False;
            end if;
            R1 := -C / B;
            return abs (R1) <= 1.0 + 1.0E-12;
         end if;
         Disc := B * B - 4.0 * A * C;
         if Disc < -1.0E-12 then
            --  Complex conjugate pair: |root|² = |C/A| for monic-scale
            --  ρ = a(ζ−re−i im)(ζ−re+i im); product of roots = C/A.
            return abs (C / A) <= 1.0 + 1.0E-12;
         end if;
         if Disc < 0.0 then
            Disc := 0.0;
         end if;
         Sqrt_D := Sqrt (Disc);
         R1     := (-B + Sqrt_D) / (2.0 * A);
         R2     := (-B - Sqrt_D) / (2.0 * A);
         if abs (R1) > 1.0 + 1.0E-12 or else abs (R2) > 1.0 + 1.0E-12 then
            return False;
         end if;
         --  Roots on the unit circle must be simple.
         if abs (abs (R1) - 1.0) <= 1.0E-12
           and then abs (abs (R2) - 1.0) <= 1.0E-12
           and then abs (R1 - R2) <= 1.0E-12
         then
            return False;
         end if;
         return True;
      end Quad_OK;
   begin
      case M is
         when AB2 =>
            --  ρ(ζ) = ζ² − ζ = ζ(ζ − 1); roots 0, 1.
            return Quad_OK (1.0, -1.0, 0.0);
         when BDF2 =>
            --  ρ(ζ) = (3/2) ζ² − 2 ζ + 1/2; roots 1, 1/3.
            return Quad_OK (1.5, -2.0, 0.5);
         when AM2_Trapezoid | BDF1 =>
            --  ρ(ζ) = ζ − 1; single root 1 (simple) → zero-stable.
            return True;
         when AB3 | AB4 | AM3 =>
            --  Classical Adams / AM3 first characteristic polynomials
            --  satisfy the root condition (textbook; all catalogue methods
            --  here are zero-stable).
            return True;
      end case;
   end Characteristic_Polynomial_Roots_OK;

   -------------------------------------------------------------------------
   -- Sample ODEs
   -------------------------------------------------------------------------

   function F_Decay (T, Y : Real) return Real is
      pragma Unreferenced (T);
   begin
      return -Y;
   end F_Decay;

   function F_Growth (T, Y : Real) return Real is
      pragma Unreferenced (T);
   begin
      return Y;
   end F_Growth;

   function F_Decay_2 (T, Y : Real) return Real is
      pragma Unreferenced (T);
   begin
      return -2.0 * Y;
   end F_Decay_2;

   function F_Stiff (T, Y : Real) return Real is
      pragma Unreferenced (T);
   begin
      return -50.0 * Y;
   end F_Stiff;

   function F_Logistic (T, Y : Real) return Real is
      pragma Unreferenced (T);
   begin
      return Y * (1.0 - Y);
   end F_Logistic;

   function DF_Decay (T, Y : Real) return Real is
      pragma Unreferenced (T, Y);
   begin
      return -1.0;
   end DF_Decay;

   function DF_Growth (T, Y : Real) return Real is
      pragma Unreferenced (T, Y);
   begin
      return 1.0;
   end DF_Growth;

   function DF_Decay_2 (T, Y : Real) return Real is
      pragma Unreferenced (T, Y);
   begin
      return -2.0;
   end DF_Decay_2;

   function DF_Stiff (T, Y : Real) return Real is
      pragma Unreferenced (T, Y);
   begin
      return -50.0;
   end DF_Stiff;

   function DF_Logistic (T, Y : Real) return Real is
      pragma Unreferenced (T);
   begin
      return 1.0 - 2.0 * Y;
   end DF_Logistic;

end Linear_Multistep_Methods;
