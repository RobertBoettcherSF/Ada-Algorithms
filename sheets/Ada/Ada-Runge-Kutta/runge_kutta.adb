--  Runge_Kutta body — explicit RK4, midpoint, Heun, and Euler contrast.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Runge_Kutta
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
   -- One-step methods
   -------------------------------------------------------------------------

   function Step_RK4
     (F : ODE_Fn;
      T : Real;
      Y : Real;
      H : Real) return Real
   is
      K1, K2, K3, K4 : Real;
      Half_H         : Real;
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;
      Half_H := H * 0.5;
      K1 := F (T, Y);
      K2 := F (T + Half_H, Y + Half_H * K1);
      K3 := F (T + Half_H, Y + Half_H * K2);
      K4 := F (T + H, Y + H * K3);
      return Y + (H / 6.0) * (K1 + 2.0 * K2 + 2.0 * K3 + K4);
   end Step_RK4;

   function Step_Midpoint
     (F : ODE_Fn;
      T : Real;
      Y : Real;
      H : Real) return Real
   is
      K1, K2 : Real;
      Half_H : Real;
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;
      Half_H := H * 0.5;
      K1 := F (T, Y);
      K2 := F (T + Half_H, Y + Half_H * K1);
      return Y + H * K2;
   end Step_Midpoint;

   function Step_Heun
     (F : ODE_Fn;
      T : Real;
      Y : Real;
      H : Real) return Real
   is
      K1, K2 : Real;
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;
      K1 := F (T, Y);
      K2 := F (T + H, Y + H * K1);
      return Y + (H * 0.5) * (K1 + K2);
   end Step_Heun;

   function Step_Euler
     (F : ODE_Fn;
      T : Real;
      Y : Real;
      H : Real) return Real
   is
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;
      return Y + H * F (T, Y);
   end Step_Euler;

   -------------------------------------------------------------------------
   -- Multi-step integration
   -------------------------------------------------------------------------

   function Integrate_RK4
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
         Y := Step_RK4 (F, T, Y, H);
         T := T0 + Real (I) * H;
      end loop;
      return Y;
   end Integrate_RK4;

   function Integrate_Midpoint
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
         Y := Step_Midpoint (F, T, Y, H);
         T := T0 + Real (I) * H;
      end loop;
      return Y;
   end Integrate_Midpoint;

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

   function Integrate_Euler
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
         Y := Step_Euler (F, T, Y, H);
         T := T0 + Real (I) * H;
      end loop;
      return Y;
   end Integrate_Euler;

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

end Runge_Kutta;
