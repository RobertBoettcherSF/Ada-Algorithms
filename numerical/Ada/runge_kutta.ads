--  Runge_Kutta — Ada 2023 educational package for Wikipedia
--  "Runge–Kutta methods": explicit one-step ODE schemes with
--  intermediate stages for the scalar IVP
--    y' = f(t, y).
--  Implements classic RK4, midpoint (RK2), Heun / improved Euler
--  (RK2), and a tiny forward-Euler (RK1) catalogue contrast.
--  Primary source:
--  https://en.wikipedia.org/wiki/Runge%E2%80%93Kutta_methods

pragma Ada_2022;

package Runge_Kutta
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Right-hand side f(t, y) of the scalar IVP y' = f(t, y).
   type ODE_Fn is access function (T, Y : Real) return Real;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for null F, non-positive step size, or empty/backward
   --  integration interval.

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  |A − B| ≤ Tol.

   function Abs_Error (Approx, Exact : Real) return Non_Negative
     with Global => null;
   --  |Approx − Exact|.

   ---------------------------------------------------------------------------
   -- Exact solution helper
   ---------------------------------------------------------------------------

   --  Exact solution of y' = λ y, y(0) = Y0:  Y0 · e^{λ T}.
   function Exact_Exponential
     (Lambda, T : Real;
      Y0        : Real := 1.0) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- One-step methods
   ---------------------------------------------------------------------------

   --  Classic 4-stage Runge–Kutta (RK4):
   --    k1 = f(t, y)
   --    k2 = f(t + h/2, y + h k1/2)
   --    k3 = f(t + h/2, y + h k2/2)
   --    k4 = f(t + h,   y + h k3)
   --    y_{n+1} = y + (h/6)(k1 + 2 k2 + 2 k3 + k4).
   --  Order 4; local truncation O(h^5). Raises Invalid_Argument if
   --  F is null or H ≤ 0.
   function Step_RK4
     (F : ODE_Fn;
      T : Real;
      Y : Real;
      H : Real) return Real
     with Pre => F /= null, Global => null;

   --  Explicit midpoint method (RK2):
   --    k1 = f(t, y)
   --    k2 = f(t + h/2, y + h k1/2)
   --    y_{n+1} = y + h k2.
   --  Order 2. Raises Invalid_Argument if F is null or H ≤ 0.
   function Step_Midpoint
     (F : ODE_Fn;
      T : Real;
      Y : Real;
      H : Real) return Real
     with Pre => F /= null, Global => null;

   --  Heun / improved Euler (explicit RK2):
   --    k1 = f(t, y)
   --    k2 = f(t + h, y + h k1)
   --    y_{n+1} = y + (h/2)(k1 + k2).
   --  Order 2. Raises Invalid_Argument if F is null or H ≤ 0.
   function Step_Heun
     (F : ODE_Fn;
      T : Real;
      Y : Real;
      H : Real) return Real
     with Pre => F /= null, Global => null;

   --  Forward Euler as RK1 catalogue contrast:
   --    y_{n+1} = y + h f(t, y).
   --  Order 1. Raises Invalid_Argument if F is null or H ≤ 0.
   function Step_Euler
     (F : ODE_Fn;
      T : Real;
      Y : Real;
      H : Real) return Real
     with Pre => F /= null, Global => null;

   ---------------------------------------------------------------------------
   -- Multi-step integration (equal steps on [T0, T1])
   ---------------------------------------------------------------------------

   --  Integrate with classic RK4. h = (T1 − T0) / N.
   --  Raises Invalid_Argument if F is null or T1 ≤ T0.
   function Integrate_RK4
     (F  : ODE_Fn;
      T0 : Real;
      Y0 : Real;
      T1 : Real;
      N  : Positive) return Real
     with Pre => F /= null, Global => null;

   --  Integrate with midpoint (RK2).
   function Integrate_Midpoint
     (F  : ODE_Fn;
      T0 : Real;
      Y0 : Real;
      T1 : Real;
      N  : Positive) return Real
     with Pre => F /= null, Global => null;

   --  Integrate with Heun / improved Euler (RK2).
   function Integrate_Heun
     (F  : ODE_Fn;
      T0 : Real;
      Y0 : Real;
      T1 : Real;
      N  : Positive) return Real
     with Pre => F /= null, Global => null;

   --  Integrate with forward Euler (RK1 contrast).
   function Integrate_Euler
     (F  : ODE_Fn;
      T0 : Real;
      Y0 : Real;
      T1 : Real;
      N  : Positive) return Real
     with Pre => F /= null, Global => null;

   ---------------------------------------------------------------------------
   -- Educational sample ODEs (library-level for 'Access in tests)
   ---------------------------------------------------------------------------

   --  y' = −y   (λ = −1); exact e^{−t} from y(0)=1.
   function F_Decay (T, Y : Real) return Real;

   --  y' = +y   (λ = +1); exact e^{t} from y(0)=1.
   function F_Growth (T, Y : Real) return Real;

   --  y' = −2 y (λ = −2).
   function F_Decay_2 (T, Y : Real) return Real;

   --  Mildly stiff linear decay y' = −50 y (λ = −50).
   function F_Stiff (T, Y : Real) return Real;

   --  Autonomous nonlinear: y' = y (1 − y)  (logistic, r=1, K=1).
   function F_Logistic (T, Y : Real) return Real;

end Runge_Kutta;
