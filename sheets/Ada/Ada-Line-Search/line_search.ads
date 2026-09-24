--  Line_Search — Ada 2023 educational package for Wikipedia
--  "Line search": choose a step length α along a descent direction p
--  so that φ(α) = f(x + α p) decreases sufficiently. Implements
--  Armijo backtracking, (strong) Wolfe conditions, golden-section /
--  Fibonacci exact 1-D search, fixed step, and exact quadratic φ.
--  Primary source: https://en.wikipedia.org/wiki/Line_search
--  Siblings: Ada-BFGS / Ada-Newtons-Method-in-Optimization (README).

pragma Ada_2022;

package Line_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Dim : constant := 8;
   subtype Dim_Count is Positive range 1 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;

   --  Point / vector in R^n (n ≤ Max_Dim).
   type Point is array (Dim_Index range <>) of Real;
   subtype Vector is Point;

   --  C1             : Armijo sufficient-decrease constant c₁ ∈ (0,1)
   --  C2             : Wolfe curvature constant c₂ ∈ (c₁,1)
   --  Rho            : geometric shrink α ← ρ α on backtrack (e.g. 0.5)
   --  Max_Backtracks : max Armijo / Wolfe trial steps
   --  Alpha0         : initial trial step length
   --  Fd_Eps         : finite-difference step for φ'(α) when Grad is null
   --  Strong_Wolfe   : True → |φ'(α)| ≤ c₂ |φ'(0)|; False → weak Wolfe
   --  Tol            : golden-section / Fibonacci interval tolerance
   --  Max_Iterations : max iterations for exact 1-D searches
   type Config is record
      C1             : Positive_Real := 1.0E-4;
      C2             : Positive_Real := 0.9;
      Rho            : Positive_Real := 0.5;
      Max_Backtracks : Positive      := 50;
      Alpha0         : Positive_Real := 1.0;
      Fd_Eps         : Positive_Real := 1.0E-8;
      Strong_Wolfe   : Boolean       := True;
      Tol            : Positive_Real := 1.0E-8;
      Max_Iterations : Positive      := 100;
   end record;

   Default_Config : constant Config := (others => <>);

   --  Alpha   : accepted (or last-tried) step length
   --  Success : True when acceptance conditions were met
   --  Evals   : number of objective (φ / f) evaluations performed
   type Result is record
      Alpha   : Real    := 0.0;
      Success : Boolean := False;
      Evals   : Natural := 0;
   end record;

   --  Smooth objective f : R^n → R.
   type Objective_Fn is access function (X : Point) return Real;

   --  Optional analytical gradient ∇f.
   type Grad_Fn is access function (X : Point) return Point;

   --  Univariate restriction φ(α) for exact 1-D searches.
   type Scalar_Fn is access function (Alpha : Real) return Real;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Point_Near
     (A, B : Point; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   function Norm2 (X : Point) return Non_Negative
     with Global => null;

   function Dot (A, B : Point) return Real
     with Pre => A'Length = B'Length, Global => null;

   function Add (A, B : Point) return Point
     with Pre => A'Length = B'Length, Global => null;

   function Sub (A, B : Point) return Point
     with Pre => A'Length = B'Length, Global => null;

   function Scale (C : Real; X : Point) return Point
     with Global => null;

   ---------------------------------------------------------------------------
   -- Acceptance predicates (exposed for unit tests)
   ---------------------------------------------------------------------------

   function Armijo_Accept
     (Phi_Alpha, Phi_0, Alpha, C1, Phi_Prime_0 : Real) return Boolean
     with Global => null;
   --  True iff φ(α) ≤ φ(0) + c₁ α φ'(0).

   function Wolfe_Curvature_Accept
     (Phi_Prime_Alpha, Phi_Prime_0, C2 : Real;
      Strong : Boolean := True) return Boolean
     with Global => null;
   --  Weak:  φ'(α) ≥ c₂ φ'(0).
   --  Strong: |φ'(α)| ≤ c₂ |φ'(0)|.

   function Directional_Derivative
     (Grad : Point; P : Point) return Real
     with Pre => Grad'Length = P'Length, Global => null;
   --  φ'(0) = ∇f(x)ᵀ p.

   function Directional_Derivative_FD
     (Obj : Objective_Fn;
      X   : Point;
      P   : Point;
      Eps : Positive_Real := 1.0E-8) return Real
     with Pre => Obj /= null and then X'Length = P'Length,
          Global => null;
   --  Central FD approximation of φ'(0) = [f(x+εp) − f(x−εp)] / (2ε).

   ---------------------------------------------------------------------------
   -- Line-search algorithms
   ---------------------------------------------------------------------------

   function Armijo_Backtrack
     (Obj  : Objective_Fn;
      X    : Point;
      P    : Point;
      Grad : Grad_Fn := null;
      Cfg  : Config  := Default_Config) return Result
     with Pre => Obj /= null
            and then X'Length = P'Length
            and then Cfg.C1 < 1.0
            and then Cfg.Rho < 1.0;
   --  Backtracking: start α = Alpha0; accept first α with Armijo;
   --  else α ← Rho·α up to Max_Backtracks. Grad null → FD φ'(0).

   function Wolfe_Line_Search
     (Obj  : Objective_Fn;
      X    : Point;
      P    : Point;
      Grad : Grad_Fn := null;
      Cfg  : Config  := Default_Config) return Result
     with Pre => Obj /= null
            and then X'Length = P'Length
            and then Cfg.C1 < Cfg.C2
            and then Cfg.C2 < 1.0
            and then Cfg.Rho < 1.0;
   --  Backtracking that also requires (strong) Wolfe curvature.
   --  Directional derivative at trial points via Grad or FD.

   function Golden_Section
     (Phi : Scalar_Fn;
      Lo  : Real;
      Hi  : Real;
      Cfg : Config := Default_Config) return Result
     with Pre => Phi /= null and then Lo < Hi;
   --  Golden-section search for unimodal φ on [Lo, Hi].

   function Fibonacci_Search
     (Phi : Scalar_Fn;
      Lo  : Real;
      Hi  : Real;
      Cfg : Config := Default_Config) return Result
     with Pre => Phi /= null and then Lo < Hi;
   --  Fibonacci search for unimodal φ on [Lo, Hi] (fixed iteration
   --  count derived from Tol / Max_Iterations).

   function Fixed_Step (Alpha : Positive_Real) return Result
     with Pre => Alpha > 0.0, Global => null;
   --  Return α unchanged (no search). Useful as a baseline / learning-rate
   --  step when no adaptive line search is desired.

   function Exact_Quadratic
     (A, B, C : Real) return Result
     with Global => null;
   --  Exact minimizer of φ(α) = A + B α + C α² when C > 0:
   --  α* = −B / (2C). Success False when C ≤ 0 (not a bowl).

   ---------------------------------------------------------------------------
   -- Built-in demo objectives (+ analytical gradients)
   ---------------------------------------------------------------------------

   function Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = Σ x_i²; unique min 0 at the origin.

   function Sphere_Grad (X : Point) return Point
     with Global => null;
   --  ∇f = 2x.

   function Rosenbrock (X : Point) return Real
     with Global => null;
   --  Classic banana: f(x,y)=(1−x)² + 100(y−x²)².
   --  Global min 0 at (1,1). Uses first two coordinates.

   function Rosenbrock_Grad (X : Point) return Point
     with Global => null;

   function Quadratic_1D (Alpha : Real) return Real
     with Global => null;
   --  Demo φ(α) = (α − 2)²  (min at α=2).

   function Quartic_Unimodal (Alpha : Real) return Real
     with Global => null;
   --  Demo φ(α) = (α − 1.5)⁴ + 0.1 (α − 1.5)²  (min at α=1.5).

end Line_Search;
