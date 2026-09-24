--  Euler_Integration body — forward Euler and semi-implicit sketch.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Euler_Integration
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
   begin
      return 1.0 + Z;
   end Amplification;

   function Exact_Exponential
     (Lambda, T : Real;
      Y0        : Real := 1.0) return Real
   is
   begin
      return Y0 * Exp (Lambda * T);
   end Exact_Exponential;

   -------------------------------------------------------------------------
   -- One-step method
   -------------------------------------------------------------------------

   function Step
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
   end Step;

   -------------------------------------------------------------------------
   -- Multi-step integration
   -------------------------------------------------------------------------

   function Integrate
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
         Y := Step (F, T, Y, H);
         T := T0 + Real (I) * H;
      end loop;
      return Y;
   end Integrate;

   -------------------------------------------------------------------------
   -- Semi-implicit (symplectic) Euler
   -------------------------------------------------------------------------

   procedure Step_Semi_Implicit
     (G : Force_Fn;
      Y : in out Real;
      V : in out Real;
      H : Real)
   is
   begin
      if G = null then
         raise Invalid_Argument;
      end if;
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;
      V := V + H * G (Y);
      Y := Y + H * V;
   end Step_Semi_Implicit;

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

   function G_Harmonic (Y : Real) return Real is
   begin
      return -Y;
   end G_Harmonic;

end Euler_Integration;
