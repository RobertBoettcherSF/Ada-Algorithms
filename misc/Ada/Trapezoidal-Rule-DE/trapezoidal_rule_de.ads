--  Trapezoidal_Rule_DE — Ada 2023 educational package for Wikipedia
--  "Trapezoidal rule (differential equations)": the implicit second-order
--  ODE step obtained by applying the trapezoidal quadrature rule to
--    y' = f(t, y)
--  over one step of size h. Equivalent to the (implicit) trapezoidal /
--  Crank–Nicolson Runge–Kutta tableau for scalar ODEs; A-stable on the
--  linear test equation. Also exposes the explicit Heun / improved-Euler
--  predictor-corrector as a pedagogical contrast.
--  Primary source:
--  https://en.wikipedia.org/wiki/Trapezoidal_rule_(differential_equations)

pragma Ada_2022;

package Trapezoidal_Rule_DE
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

   --  Optional analytic partial derivative ∂f/∂y for Newton solves.
   type Partial_Y_Fn is access function (T, Y : Real) return Real;

   --  How to resolve the implicit equation for y_{n+1}.
   type Solver_Kind is (Fixed_Point, Newton);

   --  Max_Iterations : inner nonlinear iteration budget per step
   --  Tol            : |Δy| stop tolerance for the implicit solve
   --  Solver         : fixed-point iteration or Newton
   type Config is record
      Max_Iterations : Positive      := 50;
      Tol            : Positive_Real := 1.0E-12;
      Solver         : Solver_Kind   := Fixed_Point;
   end record;

   type Step_Result is record
      Y_Next     : Real    := 0.0;
      Iterations : Natural := 0;
      Converged  : Boolean := False;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for null F, non-positive step size, empty/backward interval,
   --  or failed nonlinear convergence on an implicit step.

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
   -- Linear-test / A-stability helpers
   ---------------------------------------------------------------------------

   --  Stability function of the trapezoidal rule on y' = λ y:
   --    R(z) = (1 + z/2) / (1 − z/2),   z = h λ.
   --  Raises Invalid_Argument when |1 − z/2| is tiny (pole).
   function Amplification (Z : Real) return Real
     with Global => null;

   --  Exact solution of y' = λ y, y(0) = Y0:  Y0 · e^{λ T}.
   function Exact_Exponential
     (Lambda, T : Real;
      Y0        : Real := 1.0) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- One-step methods
   ---------------------------------------------------------------------------

   --  One implicit trapezoidal step:
   --    y_{n+1} = y_n + (h/2) ( f(t_n,y_n) + f(t_n+h, y_{n+1}) ).
   --  Initial guess = forward Euler. Fixed-point iterates the right-hand
   --  side; Newton uses DF_DY when non-null, else a finite-difference
   --  ∂f/∂y. Raises Invalid_Argument if F is null, H ≤ 0, or the solve
   --  fails to converge within Max_Iterations.
   function Step_Implicit
     (F     : ODE_Fn;
      T     : Real;
      Y     : Real;
      H     : Real;
      Cfg   : Config      := (others => <>);
      DF_DY : Partial_Y_Fn := null) return Step_Result
     with Pre => F /= null, Global => null;

   --  Explicit Heun / improved Euler (predictor-corrector trapezoidal):
   --    ŷ = y_n + h f(t_n, y_n)
   --    y_{n+1} = y_n + (h/2) ( f(t_n,y_n) + f(t_n+h, ŷ) ).
   --  Raises Invalid_Argument if F is null or H ≤ 0.
   function Step_Heun
     (F : ODE_Fn;
      T : Real;
      Y : Real;
      H : Real) return Real
     with Pre => F /= null, Global => null;

   ---------------------------------------------------------------------------
   -- Multi-step integration
   ---------------------------------------------------------------------------

   --  Integrate y' = F from (T0, Y0) to T1 with N equal steps using the
   --  implicit trapezoidal rule. Step size h = (T1 − T0) / N.
   --  Raises Invalid_Argument if F is null, N < 1 conceptually (Positive),
   --  T1 ≤ T0, or any step fails to converge.
   function Integrate
     (F     : ODE_Fn;
      T0    : Real;
      Y0    : Real;
      T1    : Real;
      N     : Positive;
      Cfg   : Config       := (others => <>);
      DF_DY : Partial_Y_Fn := null) return Real
     with Pre => F /= null, Global => null;

   --  Same interval integration with the explicit Heun step.
   function Integrate_Heun
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

end Trapezoidal_Rule_DE;
