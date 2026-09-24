--  Euler_Integration — Ada 2023 educational package for Wikipedia
--  "Euler method" / "Euler integration": the explicit first-order
--  forward Euler step for the scalar IVP
--    y' = f(t, y)
--    y_{n+1} = y_n + h f(t_n, y_n).
--  Conditionally stable: amplification R(z) = 1 + z on y' = λ y
--  (stability disk |1 + z| ≤ 1). Also sketches semi-implicit
--  (symplectic) Euler for the mechanical reduction of y'' = G(y).
--  Primary sources:
--  https://en.wikipedia.org/wiki/Euler_method
--  https://en.wikipedia.org/wiki/Euler_integration

pragma Ada_2022;

package Euler_Integration
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

   --  Autonomous force G(y) for the mechanical sketch y'' = G(y)
   --  reduced to (y' = v, v' = G(y)).
   type Force_Fn is access function (Y : Real) return Real;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for null F/G, non-positive step size, or empty/backward
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
   -- Linear-test / stability helpers
   ---------------------------------------------------------------------------

   --  Stability function of forward Euler on y' = λ y:
   --    R(z) = 1 + z,   z = h λ.
   function Amplification (Z : Real) return Real
     with Global => null;

   --  Exact solution of y' = λ y, y(0) = Y0:  Y0 · e^{λ T}.
   function Exact_Exponential
     (Lambda, T : Real;
      Y0        : Real := 1.0) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- One-step method
   ---------------------------------------------------------------------------

   --  One forward Euler step:
   --    y_{n+1} = y_n + h f(t_n, y_n).
   --  Raises Invalid_Argument if F is null or H ≤ 0.
   function Step
     (F : ODE_Fn;
      T : Real;
      Y : Real;
      H : Real) return Real
     with Pre => F /= null, Global => null;

   ---------------------------------------------------------------------------
   -- Multi-step integration
   ---------------------------------------------------------------------------

   --  Integrate y' = F from (T0, Y0) to T1 with N equal steps using
   --  forward Euler. Step size h = (T1 − T0) / N.
   --  Raises Invalid_Argument if F is null, T1 ≤ T0.
   function Integrate
     (F  : ODE_Fn;
      T0 : Real;
      Y0 : Real;
      T1 : Real;
      N  : Positive) return Real
     with Pre => F /= null, Global => null;

   ---------------------------------------------------------------------------
   -- Semi-implicit (symplectic) Euler sketch for y'' = G(y)
   ---------------------------------------------------------------------------

   --  One semi-implicit Euler step on the first-order system
   --    y' = v,   v' = G(y):
   --      v_{n+1} = v_n + h G(y_n)
   --      y_{n+1} = y_n + h v_{n+1}.
   --  Raises Invalid_Argument if G is null or H ≤ 0.
   procedure Step_Semi_Implicit
     (G : Force_Fn;
      Y : in out Real;
      V : in out Real;
      H : Real)
     with Pre => G /= null, Global => null;

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

   --  Harmonic oscillator force G(y) = −y for y'' = −y (ω = 1).
   function G_Harmonic (Y : Real) return Real;

end Euler_Integration;
