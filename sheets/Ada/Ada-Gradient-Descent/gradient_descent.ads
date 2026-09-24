--  Gradient_Descent — Ada 2023 educational package for Wikipedia
--  "Gradient descent": first-order unconstrained minimizer that takes
--  repeated steps opposite the gradient, x ← x − η ∇f(x). Supports
--  fixed step size, Armijo backtracking along −∇f, optional heavy-ball
--  momentum, and a gradient-ascent Maximize variant.
--  Primary source: https://en.wikipedia.org/wiki/Gradient_descent
--  Siblings: Ada-Line-Search / Ada-BFGS / Ada-Nonlinear-Optimization
--  (README links).

pragma Ada_2022;

package Gradient_Descent
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   Max_Dim : constant := 8;
   subtype Dim_Count is Positive range 1 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;

   --  Point / vector in R^n (n ≤ Max_Dim).
   type Point is array (Dim_Index range <>) of Real;
   subtype Vector is Point;

   --  Max_Iterations   : hard outer iteration budget
   --  Step             : fixed learning rate η (also initial α for Armijo)
   --  Grad_Tol         : stop when ‖∇f‖ ≤ Grad_Tol
   --  Step_Tol         : stop when ‖Δx‖ ≤ Step_Tol
   --  Use_Line_Search  : True → Armijo backtracking along −∇f; else fixed η
   --  Momentum_Beta    : heavy-ball β ∈ [0,1) for Minimize_Momentum
   --  Armijo_C         : sufficient-decrease constant c₁ ∈ (0,1)
   --  Line_Search_Rho  : multiply α by this on each backtrack (e.g. 0.5)
   --  Max_Line_Search  : max Armijo backtracking attempts per iteration
   --  Fd_Eps           : finite-difference step for numerical gradient
   type Config is record
      Max_Iterations  : Positive      := 500;
      Step            : Positive_Real := 0.1;
      Grad_Tol        : Non_Negative  := 1.0E-8;
      Step_Tol        : Non_Negative  := 1.0E-12;
      Use_Line_Search : Boolean       := False;
      Momentum_Beta   : Unit_Interval := 0.0;
      Armijo_C        : Positive_Real := 1.0E-4;
      Line_Search_Rho : Positive_Real := 0.5;
      Max_Line_Search : Positive      := 40;
      Fd_Eps          : Positive_Real := 1.0E-7;
   end record;

   Default_Config : constant Config := (others => <>);

   type Result is record
      Final_Point     : Point (1 .. Max_Dim) := [others => 0.0];
      Final_Value     : Real         := 0.0;
      Final_Grad_Norm : Non_Negative := 0.0;
      Dim             : Dim_Count    := 1;
      Iterations      : Natural      := 0;
      Success         : Boolean      := False;
   end record;

   --  Smooth objective f : R^n → R.
   type Objective_Fn is access function (X : Point) return Real;

   --  Optional analytical gradient ∇f.
   type Grad_Fn is access function (X : Point) return Point;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument   : exception;
   Line_Search_Failed : exception;

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
   -- Core primitives (exposed for unit tests)
   ---------------------------------------------------------------------------

   function Finite_Difference_Gradient
     (Obj : Objective_Fn;
      X   : Point;
      Eps : Positive_Real := 1.0E-7) return Point
     with Pre => Obj /= null and then X'Length >= 1, Global => null;
   --  Central finite-difference gradient (2n evaluations).

   function Armijo_Accept
     (F_New, F_Old, Alpha, C1, Dir_Deriv : Real) return Boolean
     with Global => null;
   --  True iff F_New ≤ F_Old + C1·Alpha·Dir_Deriv.

   function Line_Search
     (Obj    : Objective_Fn;
      X      : Point;
      F      : Real;
      G      : Point;
      P      : Point;
      Alpha0 : Positive_Real;
      C1     : Positive_Real;
      Rho    : Positive_Real;
      Max_LS : Positive) return Positive_Real
     with Pre => Obj /= null
            and then X'Length = G'Length
            and then G'Length = P'Length
            and then C1 < 1.0
            and then Rho < 1.0,
          Global => null;
   --  Armijo backtracking along P starting at Alpha0.
   --  Raises Line_Search_Failed if no α accepted within Max_LS tries.

   function Descent_Step
     (X : Point; G : Point; Eta : Real) return Point
     with Pre => X'Length = G'Length, Global => null;
   --  x ← x − η g  (one fixed-step gradient-descent update).

   function Ascent_Step
     (X : Point; G : Point; Eta : Real) return Point
     with Pre => X'Length = G'Length, Global => null;
   --  x ← x + η g  (one fixed-step gradient-ascent update).

   function Momentum_Step
     (X : Point; V : in out Point; G : Point; Eta, Beta : Real) return Point
     with Pre => X'Length = V'Length and then V'Length = G'Length,
          Global => null;
   --  Heavy-ball: v ← β v − η g;  x ← x + v.  Updates V in place.

   ---------------------------------------------------------------------------
   -- Built-in demo objectives (+ analytical gradients)
   ---------------------------------------------------------------------------

   function Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = Σ x_i²; unique min 0 at the origin.

   function Sphere_Grad (X : Point) return Point
     with Global => null;
   --  ∇f = 2x.

   function Quadratic_Bowl (X : Point) return Real
     with Global => null;
   --  f(x) = ½ Σ i·x_i²  (well-conditioned positive-definite bowl).
   --  Unique min 0 at the origin.

   function Quadratic_Bowl_Grad (X : Point) return Point
     with Global => null;

   function Rosenbrock (X : Point) return Real
     with Global => null;
   --  Classic banana: f(x,y)=(1−x)² + 100(y−x²)².
   --  Global min 0 at (1,1). Uses first two coordinates.

   function Rosenbrock_Grad (X : Point) return Point
     with Global => null;

   function Himmelblau (X : Point) return Real
     with Global => null;
   --  f(x,y)=(x²+y−11)²+(x+y²−7)²; four global minima with f=0.
   --  Uses first two coordinates.

   function Himmelblau_Grad (X : Point) return Point
     with Global => null;

   function Negated_Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = −Σ x_i²; unique max 0 at the origin (ascent demo).

   function Negated_Sphere_Grad (X : Point) return Point
     with Global => null;
   --  ∇f = −2x.

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   function Minimize
     (Objective : Objective_Fn;
      X0        : Point;
      Grad      : Grad_Fn := null;
      Cfg       : Config := Default_Config) return Result
     with Pre => Objective /= null
            and then X0'Length >= 1
            and then X0'Length <= Max_Dim,
          Global => null;
   --  Gradient descent: x ← x − η ∇f (fixed η) or Armijo along −∇f
   --  when Use_Line_Search. Grad null → central FD.

   function Maximize
     (Objective : Objective_Fn;
      X0        : Point;
      Grad      : Grad_Fn := null;
      Cfg       : Config := Default_Config) return Result
     with Pre => Objective /= null
            and then X0'Length >= 1
            and then X0'Length <= Max_Dim,
          Global => null;
   --  Gradient ascent: x ← x + η ∇f (or Armijo along +∇f). Equivalent
   --  to Minimize of −f; Success when ‖∇f‖ ≤ Grad_Tol.

   function Minimize_Momentum
     (Objective : Objective_Fn;
      X0        : Point;
      Grad      : Grad_Fn := null;
      Cfg       : Config := Default_Config) return Result
     with Pre => Objective /= null
            and then X0'Length >= 1
            and then X0'Length <= Max_Dim,
          Global => null;
   --  Heavy-ball / Polyak momentum: v ← β v − η g; x ← x + v
   --  with β = Momentum_Beta (default 0 → plain GD). Fixed step only
   --  (line search ignored). Grad null → central FD.

end Gradient_Descent;
