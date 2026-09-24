--  Backward_Euler — Ada 2023 educational package for Wikipedia
--  "Backward Euler method": the implicit first-order one-step method
--  (equivalently BDF1) for the scalar IVP
--    y' = f(t, y)
--    y_{n+1} = y_n + h f(t_{n+1}, y_{n+1}).
--  A-stable and L-stable: amplification R(z) = 1/(1 − z) on y' = λ y
--  with R(∞) = 0 (stiff damping). Each step solves a (generally
--  nonlinear) equation for y_{n+1} by Newton or fixed-point iteration.
--  Primary source:
--  https://en.wikipedia.org/wiki/Backward_Euler_method

pragma Ada_2022;

package Backward_Euler
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

   --  Optional analytic ∂f/∂y for Newton on the implicit step.
   type Partial_Y_Fn is access function (T, Y : Real) return Real;

   ---------------------------------------------------------------------------
   -- Nonlinear solver config
   ---------------------------------------------------------------------------

   --  Max_Iterations : inner nonlinear iteration budget per step
   --  Tol            : |Δy| stop tolerance for the implicit solve
   --  DF_DY          : optional analytic ∂f/∂y; when non-null, Step uses
   --                   Newton; when null, Step uses fixed-point iteration.
   type Config is record
      Max_Iterations : Positive      := 50;
      Tol            : Positive_Real := 1.0E-12;
      DF_DY          : Partial_Y_Fn  := null;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for null F, H ≤ 0, empty/backward interval, singularity of
   --  Amplification at Z = 1, or failed nonlinear convergence.

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

   --  Stability function of backward Euler on y' = λ y:
   --    R(z) = 1 / (1 − z),   z = h λ.
   --  Raises Invalid_Argument near the pole z = 1.
   function Amplification (Z : Real) return Real
     with Global => null;

   --  True iff |R(Z)| ≤ 1 (absolute stability). False near the pole.
   --  Backward Euler is A-stable: |R(z)| ≤ 1 for all Re(z) ≤ 0, and
   --  L-stable: R(∞) = 0.
   function Amplification_Bounded (Z : Real) return Boolean
     with Global => null;

   --  Exact solution of y' = λ y, y(0) = Y0:  Y0 · e^{λ T}.
   function Exact_Exponential
     (Lambda, T : Real;
      Y0        : Real := 1.0) return Real
     with Global => null;

   --  Forward Euler amplification R_FE(z) = 1 + z (contrast helper).
   function Forward_Euler_Amplification (Z : Real) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- One-step method
   ---------------------------------------------------------------------------

   --  One backward Euler step:
   --    y_{n+1} = y_n + h f(t_n + h, y_{n+1}).
   --  Initial guess = forward Euler predictor. Uses Newton when
   --  Cfg.DF_DY /= null, else fixed-point iteration.
   --  Raises Invalid_Argument if F is null, H ≤ 0, or the solve fails
   --  to converge within Max_Iterations.
   function Step
     (F   : ODE_Fn;
      T   : Real;
      Y   : Real;
      H   : Real;
      Cfg : Config := (others => <>)) return Real
     with Pre => F /= null, Global => null;

   --  One forward Euler step y + h f(t, y) — stiff-regime contrast only.
   --  Raises Invalid_Argument if F is null or H ≤ 0.
   function Forward_Euler_Step
     (F : ODE_Fn;
      T : Real;
      Y : Real;
      H : Real) return Real
     with Pre => F /= null, Global => null;

   ---------------------------------------------------------------------------
   -- Multi-step integration
   ---------------------------------------------------------------------------

   --  Integrate y' = F from (T0, Y0) to T1 with N equal backward-Euler
   --  steps. Step size h = (T1 − T0) / N.
   --  Raises Invalid_Argument if F is null, T1 ≤ T0, or any step fails.
   function Integrate
     (F   : ODE_Fn;
      T0  : Real;
      Y0  : Real;
      T1  : Real;
      N   : Positive;
      Cfg : Config := (others => <>)) return Real
     with Pre => F /= null, Global => null;

   --  Equal-step forward Euler on the same interval (stiff contrast).
   function Forward_Euler_Integrate
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
   function DF_Decay (T, Y : Real) return Real;
   --  ∂f/∂y = −1.

   --  y' = +y   (λ = +1); exact e^{t} from y(0)=1.
   function F_Growth (T, Y : Real) return Real;
   function DF_Growth (T, Y : Real) return Real;
   --  ∂f/∂y = +1.

   --  y' = −2 y (λ = −2).
   function F_Decay_2 (T, Y : Real) return Real;
   function DF_Decay_2 (T, Y : Real) return Real;

   --  Mildly stiff linear decay y' = −50 y (λ = −50).
   function F_Stiff (T, Y : Real) return Real;
   function DF_Stiff (T, Y : Real) return Real;

   --  Autonomous nonlinear: y' = y (1 − y)  (logistic, r=1, K=1).
   function F_Logistic (T, Y : Real) return Real;
   function DF_Logistic (T, Y : Real) return Real;
   --  ∂f/∂y = 1 − 2y.

   --  Autonomous nonlinear: y' = y².
   --  Exact with y(0)=Y0: Y0 / (1 − Y0 t) while Y0 t < 1.
   function F_Square (T, Y : Real) return Real;
   function DF_Square (T, Y : Real) return Real;
   --  ∂f/∂y = 2y.

end Backward_Euler;
