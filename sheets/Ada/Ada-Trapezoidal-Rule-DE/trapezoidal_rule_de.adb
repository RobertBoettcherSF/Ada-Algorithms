--  Trapezoidal_Rule_DE body — implicit trapezoidal / Heun ODE steps.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Trapezoidal_Rule_DE
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

   function Amplification (Z : Real) return Real is
      Denom : constant Real := 1.0 - Z / 2.0;
   begin
      if abs (Denom) < 1.0E-30 then
         raise Invalid_Argument;
      end if;
      return (1.0 + Z / 2.0) / Denom;
   end Amplification;

   function Exact_Exponential
     (Lambda, T : Real;
      Y0        : Real := 1.0) return Real
   is
   begin
      return Y0 * Exp (Lambda * T);
   end Exact_Exponential;

   -------------------------------------------------------------------------
   -- Finite-difference ∂f/∂y when no analytic Jacobian is supplied
   -------------------------------------------------------------------------

   function Approx_DF_DY
     (F : ODE_Fn;
      T : Real;
      Y : Real) return Real
   is
      Dy : constant Real :=
        Real'Max (1.0E-8, 1.0E-8 * abs (Y));
   begin
      return (F (T, Y + Dy) - F (T, Y - Dy)) / (2.0 * Dy);
   end Approx_DF_DY;

   -------------------------------------------------------------------------
   -- One-step methods
   -------------------------------------------------------------------------

   function Step_Implicit
     (F     : ODE_Fn;
      T     : Real;
      Y     : Real;
      H     : Real;
      Cfg   : Config       := (others => <>);
      DF_DY : Partial_Y_Fn := null) return Step_Result
   is
      Result : Step_Result;
      Fn     : Real;
      T_Next : Real;
      Y_Cur  : Real;
      Y_New  : Real;
      G      : Real;
      Gp     : Real;
      Jac    : Real;
      Dy  : Real;
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;

      Fn     := F (T, Y);
      T_Next := T + H;
      --  Forward-Euler predictor (Wikipedia / Heun initial guess).
      Y_Cur  := Y + H * Fn;

      for K in 1 .. Cfg.Max_Iterations loop
         case Cfg.Solver is
            when Fixed_Point =>
               Y_New := Y + (H / 2.0) * (Fn + F (T_Next, Y_Cur));
               Dy := Y_New - Y_Cur;
               Y_Cur := Y_New;

            when Newton =>
               --  g(z) = z − y − (h/2)(f_n + f(t_{n+1}, z)) = 0
               G := Y_Cur - Y - (H / 2.0) * (Fn + F (T_Next, Y_Cur));
               if DF_DY /= null then
                  Jac := DF_DY (T_Next, Y_Cur);
               else
                  Jac := Approx_DF_DY (F, T_Next, Y_Cur);
               end if;
               Gp := 1.0 - (H / 2.0) * Jac;
               if abs (Gp) < 1.0E-30 then
                  raise Invalid_Argument;
               end if;
               Dy := -G / Gp;
               Y_Cur := Y_Cur + Dy;
         end case;

         Result.Iterations := K;
         if abs (Dy) <= Cfg.Tol then
            Result.Y_Next    := Y_Cur;
            Result.Converged := True;
            return Result;
         end if;
      end loop;

      raise Invalid_Argument;
   end Step_Implicit;

   function Step_Heun
     (F : ODE_Fn;
      T : Real;
      Y : Real;
      H : Real) return Real
   is
      Fn    : Real;
      Y_Hat : Real;
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;
      Fn    := F (T, Y);
      Y_Hat := Y + H * Fn;
      return Y + (H / 2.0) * (Fn + F (T + H, Y_Hat));
   end Step_Heun;

   -------------------------------------------------------------------------
   -- Multi-step integration
   -------------------------------------------------------------------------

   function Integrate
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
      Step_R : Step_Result;
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if T1 <= T0 then
         raise Invalid_Argument;
      end if;
      H := (T1 - T0) / Real (N);
      for I in 1 .. N loop
         Step_R := Step_Implicit (F, T, Y, H, Cfg, DF_DY);
         Y := Step_R.Y_Next;
         T := T0 + Real (I) * H;
      end loop;
      return Y;
   end Integrate;

   function Integrate_Heun
     (F  : ODE_Fn;
      T0 : Real;
      Y0 : Real;
      T1 : Real;
      N  : Positive) return Real
   is
      H : Real;
      T : Real := T0;
      Y : Real := Y0;
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if T1 <= T0 then
         raise Invalid_Argument;
      end if;
      H := (T1 - T0) / Real (N);
      for I in 1 .. N loop
         Y := Step_Heun (F, T, Y, H);
         T := T0 + Real (I) * H;
      end loop;
      return Y;
   end Integrate_Heun;

   -------------------------------------------------------------------------
   -- Sample ODEs
   -------------------------------------------------------------------------

   function F_Decay (T, Y : Real) return Real is
      pragma Unreferenced (T);
   begin
      return -Y;
   end F_Decay;

   function DF_Decay (T, Y : Real) return Real is
      pragma Unreferenced (T, Y);
   begin
      return -1.0;
   end DF_Decay;

   function F_Growth (T, Y : Real) return Real is
      pragma Unreferenced (T);
   begin
      return Y;
   end F_Growth;

   function DF_Growth (T, Y : Real) return Real is
      pragma Unreferenced (T, Y);
   begin
      return 1.0;
   end DF_Growth;

   function F_Decay_2 (T, Y : Real) return Real is
      pragma Unreferenced (T);
   begin
      return -2.0 * Y;
   end F_Decay_2;

   function DF_Decay_2 (T, Y : Real) return Real is
      pragma Unreferenced (T, Y);
   begin
      return -2.0;
   end DF_Decay_2;

   function F_Stiff (T, Y : Real) return Real is
      pragma Unreferenced (T);
   begin
      return -50.0 * Y;
   end F_Stiff;

   function DF_Stiff (T, Y : Real) return Real is
      pragma Unreferenced (T, Y);
   begin
      return -50.0;
   end DF_Stiff;

   function F_Logistic (T, Y : Real) return Real is
      pragma Unreferenced (T);
   begin
      return Y * (1.0 - Y);
   end F_Logistic;

   function DF_Logistic (T, Y : Real) return Real is
      pragma Unreferenced (T);
   begin
      return 1.0 - 2.0 * Y;
   end DF_Logistic;

end Trapezoidal_Rule_DE;
