--  Nonlinear_Optimization — Ada 2023 educational survey package for
--  Wikipedia "Nonlinear programming" / nonlinear optimization:
--  unconstrained (and simple box-constrained) smooth minimization with
--  gradient descent, Newton, Armijo line search, finite-difference
--  gradients, stationarity checks, and a method taxonomy.
--  Self-contained; sibling solvers (BFGS, Gauss–Newton, LM, Nelder–Mead,
--  SA, …) are linked in README only — not package dependencies.
--  Primary source: https://en.wikipedia.org/wiki/Nonlinear_programming

pragma Ada_2022;

package Nonlinear_Optimization
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
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

   --  Dense n×n matrix (Hessian or workspace).
   type Matrix is array (Dim_Index range <>, Dim_Index range <>) of Real;

   --  Smooth objective f : R^n → R to minimize.
   type Objective_Fn is access function (X : Point) return Real;

   --  Analytical gradient ∇f.
   type Gradient_Fn is access function (X : Point) return Point;

   --  Analytical Hessian ∇²f.
   type Hessian_Fn is access function (X : Point) return Matrix;

   --  GD / Newton / projected-GD controls.
   --  Use_Armijo=True → backtracking line search; else fixed Step_Size.
   type Config is record
      Max_Iterations  : Positive      := 200;
      Grad_Tol        : Non_Negative  := 1.0E-8;
      Step_Tol        : Non_Negative  := 1.0E-12;
      Fd_Eps          : Positive_Real := 1.0E-7;
      Armijo_C        : Positive_Real := 1.0E-4;
      Line_Search_Rho : Positive_Real := 0.5;
      Max_Line_Search : Positive      := 30;
      Step_Size       : Positive_Real := 0.1;
      Use_Armijo      : Boolean       := True;
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

   --  Axis-aligned box [Lo, Hi] for projected gradient (NLP flavor).
   type Box is record
      Lo : Point (1 .. Max_Dim) := [others => Real'First / 4.0];
      Hi : Point (1 .. Max_Dim) := [others => Real'Last / 4.0];
      Dim : Dim_Count := 1;
   end record;

   ---------------------------------------------------------------------------
   -- Method taxonomy (Wikipedia numeric methods: 0th / 1st / 2nd order)
   ---------------------------------------------------------------------------

   type Method_Kind is
     (Gradient_Descent,
      Newton,
      Quasi_Newton_BFGS,
      Gauss_Newton,
      Levenberg_Marquardt,
      Nelder_Mead,
      Simulated_Annealing);

   type Method_Info is record
      Kind             : Method_Kind;
      Needs_Gradient   : Boolean;
      Needs_Hessian    : Boolean;
      Derivative_Free  : Boolean;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument   : exception;
   Line_Search_Failed : exception;
   Singular_System    : exception;

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

   function Mat_Vec (A : Matrix; X : Point) return Point
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) = X'Length,
          Global => null;

   function Identity (N : Dim_Count) return Matrix
     with Global => null;

   ---------------------------------------------------------------------------
   -- Linear algebra (educational Newton)
   ---------------------------------------------------------------------------

   function Solve_SPD
     (A : Matrix; B : Point) return Point
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) = B'Length,
          Global => null;
   --  Solve A x = b for small dense systems via Gaussian elimination
   --  with partial pivoting (n ≤ Max_Dim). Raises Singular_System if
   --  the matrix is (numerically) singular. Named SPD for the common
   --  Newton / trust-region case; works for any nonsingular A.

   ---------------------------------------------------------------------------
   -- Line search (Armijo backtracking)
   ---------------------------------------------------------------------------

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
      C1     : Positive_Real;
      Rho    : Positive_Real;
      Max_LS : Positive) return Positive_Real
     with Pre => Obj /= null
            and then X'Length = G'Length
            and then G'Length = P'Length
            and then C1 < 1.0,
          Global => null;
   --  Armijo backtracking: start α=1, accept when
   --    f(x+αp) ≤ f(x) + c₁ α (gᵀp), else α ← ρ α.
   --  Raises Line_Search_Failed if no α accepted within Max_LS tries.

   ---------------------------------------------------------------------------
   -- Finite differences
   ---------------------------------------------------------------------------

   function Finite_Difference_Gradient
     (Obj : Objective_Fn;
      X   : Point;
      Eps : Positive_Real := 1.0E-7) return Point
     with Pre => Obj /= null and then X'Length >= 1, Global => null;
   --  Central finite-difference gradient (2n evaluations).

   function Finite_Difference_Hessian
     (Obj : Objective_Fn;
      X   : Point;
      Eps : Positive_Real := 1.0E-5) return Matrix
     with Pre => Obj /= null and then X'Length >= 1, Global => null;
   --  Central finite-difference Hessian for small n (O(n²) evaluations).

   ---------------------------------------------------------------------------
   -- Stationarity / box projection (NLP flavor)
   ---------------------------------------------------------------------------

   function Is_Stationary
     (G : Point; Tol : Non_Negative := 1.0E-8) return Boolean
     with Global => null;
   --  First-order optimality proxy: ‖∇f‖ ≤ Tol.

   function Grad_Norm (G : Point) return Non_Negative
     with Global => null;

   function Project_Box (X : Point; B : Box) return Point
     with Pre => X'Length = B.Dim and then B.Dim >= 1, Global => null;
   --  Componentwise projection onto [Lo_i, Hi_i].

   function Make_Box
     (Lo, Hi : Point) return Box
     with Pre => Lo'Length = Hi'Length
            and then Lo'Length >= 1
            and then Lo'Length <= Max_Dim,
          Global => null;

   ---------------------------------------------------------------------------
   -- Demo objectives (+ analytical grads / Hessians)
   ---------------------------------------------------------------------------

   function Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = Σ x_i²; unique min 0 at the origin.

   function Sphere_Grad (X : Point) return Point
     with Global => null;
   --  ∇f = 2x.

   function Sphere_Hess (X : Point) return Matrix
     with Global => null;
   --  ∇²f = 2 I.

   function Rosenbrock (X : Point) return Real
     with Global => null;
   --  Classic banana: f(x,y)=(a−x)² + b(y−x²)² with a=1, b=100.
   --  Global min 0 at (1,1). Uses first two coordinates.

   function Rosenbrock_Grad (X : Point) return Point
     with Global => null;

   function Rosenbrock_Hess (X : Point) return Matrix
     with Global => null;

   function Quadratic_Bowl (X : Point) return Real
     with Global => null;
   --  f(x) = ½ Σ i·x_i²  (well-conditioned positive-definite bowl).
   --  Unique min 0 at the origin.

   function Quadratic_Bowl_Grad (X : Point) return Point
     with Global => null;

   function Quadratic_Bowl_Hess (X : Point) return Matrix
     with Global => null;
   --  ∇²f = diag(1,2,…,n).

   function Himmelblau (X : Point) return Real
     with Global => null;
   --  f(x,y)=(x²+y−11)²+(x+y²−7)²; four global minima with f=0.
   --  Uses first two coordinates.

   function Himmelblau_Grad (X : Point) return Point
     with Global => null;

   ---------------------------------------------------------------------------
   -- Drivers: gradient descent / Newton / projected GD
   ---------------------------------------------------------------------------

   function Minimize_GD
     (Objective : Objective_Fn;
      X0        : Point;
      Grad      : Gradient_Fn := null;
      Cfg       : Config := Default_Config) return Result
     with Pre => Objective /= null
            and then X0'Length >= 1
            and then X0'Length <= Max_Dim,
          Global => null;
   --  Gradient descent: p = −∇f.  If Use_Armijo, Armijo backtracking;
   --  else fixed Step_Size.  If Grad is null, central FD gradient.

   function Minimize_Newton
     (Objective : Objective_Fn;
      X0        : Point;
      Grad      : Gradient_Fn := null;
      Hess      : Hessian_Fn := null;
      Cfg       : Config := Default_Config) return Result
     with Pre => Objective /= null
            and then X0'Length >= 1
            and then X0'Length <= Max_Dim,
          Global => null;
   --  Educational Newton: solve ∇²f(x) p = −∇f(x), then Armijo (or
   --  unit) step along p.  Missing Grad/Hess → central FD.

   function Minimize_Projected_GD
     (Objective : Objective_Fn;
      X0        : Point;
      Bounds    : Box;
      Grad      : Gradient_Fn := null;
      Cfg       : Config := Default_Config) return Result
     with Pre => Objective /= null
            and then X0'Length >= 1
            and then X0'Length = Bounds.Dim
            and then X0'Length <= Max_Dim,
          Global => null;
   --  Projected gradient: x ← Π_Box(x − α ∇f).  Bound-constrained NLP.

   function Gradient_Descent_Step
     (X : Point; G : Point; Alpha : Real) return Point
     with Pre => X'Length = G'Length, Global => null;
   --  One unconstrained GD step: x − α g.

   function Projected_Gradient_Step
     (X : Point; G : Point; Alpha : Real; Bounds : Box) return Point
     with Pre => X'Length = G'Length and then X'Length = Bounds.Dim,
          Global => null;
   --  One projected step: Π_Box(x − α g).

   function Newton_Direction
     (H : Matrix; G : Point) return Point
     with Pre => H'Length (1) = H'Length (2)
            and then H'Length (1) = G'Length,
          Global => null;
   --  p = −H⁻¹ g via Solve_SPD.

   ---------------------------------------------------------------------------
   -- Method catalog / compare helpers
   ---------------------------------------------------------------------------

   function Classify_Method (K : Method_Kind) return Method_Info
     with Global => null;

   function Method_Name (K : Method_Kind) return String
     with Global => null;

   function Method_Count return Positive
     with Global => null;
   --  Number of catalogued Method_Kind values.

   type Compare_Sample is record
      Step_Size   : Positive_Real := 0.1;
      Final_Value : Real := 0.0;
      Grad_Norm   : Non_Negative := 0.0;
      Iterations  : Natural := 0;
      Success     : Boolean := False;
   end record;

   type Compare_Table is array (Positive range <>) of Compare_Sample;

   function Compare_Fixed_Step_GD
     (Objective  : Objective_Fn;
      X0         : Point;
      Grad       : Gradient_Fn;
      Step_Sizes : Point;
      Max_Iters  : Positive := 100;
      Grad_Tol   : Non_Negative := 1.0E-8) return Compare_Table
     with Pre => Objective /= null
            and then Grad /= null
            and then X0'Length >= 1
            and then X0'Length <= Max_Dim
            and then Step_Sizes'Length >= 1,
          Global => null;
   --  Run fixed-step GD for each entry of Step_Sizes; return a table
   --  of final f, ‖g‖, iterations (educational step-size comparison).

end Nonlinear_Optimization;
