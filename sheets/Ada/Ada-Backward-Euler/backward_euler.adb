--  Backward_Euler body — implicit Euler / BDF1 with Newton or fixed-point.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Backward_Euler
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
      Denom : constant Real := 1.0 - Z;
   begin
      if abs (Denom) < 1.0E-30 then
         raise Invalid_Argument;
      end if;
      return 1.0 / Denom;
   end Amplification;

   function Amplification_Bounded (Z : Real) return Boolean is
      Denom : constant Real := 1.0 - Z;
      R     : Real;
   begin
      if abs (Denom) < 1.0E-30 then
         return False;
      end if;
      R := 1.0 / Denom;
      return abs (R) <= 1.0;
   end Amplification_Bounded;

   function Exact_Exponential
     (Lambda, T : Real;
      Y0        : Real := 1.0) return Real
   is
   begin
      return Y0 * Exp (Lambda * T);
   end Exact_Exponential;

   function Forward_Euler_Amplification (Z : Real) return Real is
   begin
      return 1.0 + Z;
   end Forward_Euler_Amplification;

   -------------------------------------------------------------------------
   -- One-step methods
   -------------------------------------------------------------------------

   function Step
     (F   : ODE_Fn;
      T   : Real;
      Y   : Real;
      H   : Real;
      Cfg : Config := (others => <>)) return Real
   is
      T_New : Real;
      Y_Cur : Real;
      Y_Nxt : Real;
      G     : Real;
      Gp    : Real;
      DFy   : Real;
   begin
      if F = null then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;

      T_New := T + H;
      --  Forward-Euler predictor as initial guess.
      Y_Cur := Y + H * F (T, Y);

      for Iter in 1 .. Cfg.Max_Iterations loop
         if Cfg.DF_DY /= null then
            --  Newton on g(y) = y − Y − H f(T_New, y) = 0
            G   := Y_Cur - Y - H * F (T_New, Y_Cur);
            DFy := Cfg.DF_DY (T_New, Y_Cur);
            Gp  := 1.0 - H * DFy;
            if abs (Gp) < 1.0E-30 then
               raise Invalid_Argument;
            end if;
            Y_Nxt := Y_Cur - G / Gp;
         else
            --  Fixed-point: y ← Y + H f(T_New, y)
            Y_Nxt := Y + H * F (T_New, Y_Cur);
         end if;

         if abs (Y_Nxt - Y_Cur) <= Cfg.Tol then
            return Y_Nxt;
         end if;
         Y_Cur := Y_Nxt;
      end loop;

      raise Invalid_Argument;
   end Step;

   function Forward_Euler_Step
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
   end Forward_Euler_Step;

   -------------------------------------------------------------------------
   -- Multi-step integration
   -------------------------------------------------------------------------

   function Integrate
     (F   : ODE_Fn;
      T0  : Real;
      Y0  : Real;
      T1  : Real;
      N   : Positive;
      Cfg : Config := (others => <>)) return Real
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
         Y := Step (F, T, Y, H, Cfg);
         T := T0 + Real (I) * H;
      end loop;
      return Y;
   end Integrate;

   function Forward_Euler_Integrate
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
         Y := Forward_Euler_Step (F, T, Y, H);
         T := T0 + Real (I) * H;
      end loop;
      return Y;
   end Forward_Euler_Integrate;

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

   function F_Square (T, Y : Real) return Real is
      pragma Unreferenced (T);
   begin
      return Y * Y;
   end F_Square;

   function DF_Square (T, Y : Real) return Real is
      pragma Unreferenced (T);
   begin
      return 2.0 * Y;
   end DF_Square;

end Backward_Euler;
