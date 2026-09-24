--  Newtons_Method_Optimization — Ada 2023 educational package for Wikipedia
--  "Newton's method in optimization": unconstrained minimization that
--  solves H(x) p = −∇f(x) for a Newton direction and updates
--  x ← x + α p (pure Newton α=1, or Armijo-damped Newton).
--  Optional educational Hessian regularization (τ I) when H is not PD.
--  Primary source:
--  https://en.wikipedia.org/wiki/Newton%27s_method_in_optimization
--  Siblings: Ada-BFGS / Ada-Gauss-Newton / Ada-Levenberg-Marquardt /
--  Ada-Nonlinear-Optimization (README links).

pragma Ada_2022;

package Newtons_Method_Optimization
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

   --  Dense n×n Hessian (or workspace).
   type Matrix is array (Dim_Index range <>, Dim_Index range <>) of Real;

   --  Max_Iterations         : hard outer iteration budget
   --  Grad_Tol               : stop when ‖∇f‖ ≤ Grad_Tol
   --  Step_Tol               : stop when ‖α p‖ ≤ Step_Tol
   --  Fd_Eps                 : central FD step for numerical gradient
   --  Fd_Hess_Eps            : central FD step for numerical Hessian
   --  Armijo_C               : sufficient-decrease constant c₁ ∈ (0,1)
   --  Line_Search_Rho        : multiply α by this on each backtrack
   --  Max_Line_Search        : max Armijo backtracking attempts
   --  Use_Line_Search        : True → Armijo; False → pure Newton α=1
   --  Hessian_Regularization : if True, add τ I when H is not PD-ish
   --  Reg_Tau0 / Reg_Tau_Grow / Reg_Tau_Max : regularization schedule
   type Config is record
      Max_Iterations         : Positive      := 100;
      Grad_Tol               : Non_Negative  := 1.0E-8;
      Step_Tol               : Non_Negative  := 1.0E-12;
      Fd_Eps                 : Positive_Real := 1.0E-7;
      Fd_Hess_Eps            : Positive_Real := 1.0E-5;
      Armijo_C               : Positive_Real := 1.0E-4;
      Line_Search_Rho        : Positive_Real := 0.5;
      Max_Line_Search        : Positive      := 30;
      Use_Line_Search        : Boolean       := True;
      Hessian_Regularization : Boolean       := True;
      Reg_Tau0               : Positive_Real := 1.0E-6;
      Reg_Tau_Grow           : Positive_Real := 10.0;
      Reg_Tau_Max            : Positive_Real := 1.0E8;
   end record;

   Default_Config : constant Config := (others => <>);

   type Result is record
      Final_Point     : Point (1 .. Max_Dim) := [others => 0.0];
      Final_Value     : Real         := 0.0;
      Final_Grad_Norm : Non_Negative := 0.0;
      Dim             : Dim_Count    := 1;
      Iterations      : Natural      := 0;
      Success         : Boolean      := False;
      Regularized     : Boolean      := False;
   end record;

   --  Smooth objective f : R^n → R to minimize.
   type Objective_Fn is access function (X : Point) return Real;

   --  Optional analytical gradient ∇f.
   type Gradient_Fn is access function (X : Point) return Point;

   --  Optional analytical Hessian ∇²f.
   type Hessian_Fn is access function (X : Point) return Matrix;

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
   --  N×N identity matrix.

   function Mat_Add (A, B : Matrix) return Matrix
     with Pre => A'Length (1) = A'Length (2)
            and then B'Length (1) = B'Length (2)
            and then A'Length (1) = B'Length (1),
          Global => null;

   function Mat_Scale (C : Real; A : Matrix) return Matrix
     with Pre => A'Length (1) = A'Length (2), Global => null;

   function Quadratic_Form (H : Matrix; X : Point) return Real
     with Pre => H'Length (1) = H'Length (2)
            and then H'Length (1) = X'Length,
          Global => null;
   --  xᵀ H x.

   ---------------------------------------------------------------------------
   -- Linear algebra / PD checks / regularization
   ---------------------------------------------------------------------------

   function Solve_Linear
     (A : Matrix; B : Point) return Point
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) = B'Length,
          Global => null;
   --  Dense GE with partial pivoting (n ≤ Max_Dim). Works for any
   --  nonsingular A (SPD Newton Hessians are the common case).
   --  Raises Singular_System if A is (numerically) singular.

   function Is_Symmetric
     (H : Matrix; Tol : Real := 1.0E-10) return Boolean
     with Pre => H'Length (1) = H'Length (2) and then Tol >= 0.0,
          Global => null;

   function Is_Positive_Definite_Ish
     (H : Matrix; Tol : Real := 1.0E-12) return Boolean
     with Pre => H'Length (1) = H'Length (2) and then Tol >= 0.0,
          Global => null;
   --  Educational Sylvester check: all leading principal minors > Tol.
   --  Also requires approximate symmetry. Not a production eigensolver.

   function Regularize_Hessian
     (H : Matrix; Tau : Non_Negative) return Matrix
     with Pre => H'Length (1) = H'Length (2), Global => null;
   --  Return H + τ I (Levenberg-style diagonal shift for education).

   function Make_PD_Hessian
     (H       : Matrix;
      Tau0    : Positive_Real := 1.0E-6;
      Grow    : Positive_Real := 10.0;
      Tau_Max : Positive_Real := 1.0E8;
      Used_Reg : access Boolean := null) return Matrix
     with Pre => H'Length (1) = H'Length (2), Global => null;
   --  If H is already PD-ish, return H. Else grow τ = Tau0, Tau0·Grow, …
   --  until H+τI is PD-ish or τ exceeds Tau_Max (then return last try).
   --  If Used_Reg /= null, set it True when any τ > 0 was applied.

   ---------------------------------------------------------------------------
   -- Newton core (exposed for unit tests)
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

   function Newton_Direction
     (H : Matrix; G : Point) return Point
     with Pre => H'Length (1) = H'Length (2)
            and then H'Length (1) = G'Length,
          Global => null;
   --  p = −H⁻¹ g via Solve_Linear. Raises Singular_System if H singular.

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
   -- Built-in demo objectives (+ analytical grads / Hessians)
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

   function Quadratic_Bowl (X : Point) return Real
     with Global => null;
   --  f(x) = ½ Σ i·x_i²  (PD quadratic). Unique min 0 at the origin.
   --  Exact Newton with α=1 finds the minimizer in one step from any x0.

   function Quadratic_Bowl_Grad (X : Point) return Point
     with Global => null;

   function Quadratic_Bowl_Hess (X : Point) return Matrix
     with Global => null;
   --  ∇²f = diag(1,2,…,n).

   function Rosenbrock (X : Point) return Real
     with Global => null;
   --  Classic banana: f(x,y)=(a−x)² + b(y−x²)² with a=1, b=100.
   --  Global min 0 at (1,1). Uses first two coordinates.

   function Rosenbrock_Grad (X : Point) return Point
     with Global => null;

   function Rosenbrock_Hess (X : Point) return Matrix
     with Global => null;

   function Himmelblau (X : Point) return Real
     with Global => null;
   --  f(x,y)=(x²+y−11)²+(x+y²−7)²; four global minima with f=0.
   --  Uses first two coordinates.

   function Himmelblau_Grad (X : Point) return Point
     with Global => null;

   function Himmelblau_Hess (X : Point) return Matrix
     with Global => null;

   function Quartic_1D (X : Point) return Real
     with Global => null;
   --  f(x) = (x−3)⁴ using the first coordinate. Unique min 0 at x=3.
   --  Hessian vanishes at the minimizer (educational singular case).

   function Quartic_1D_Grad (X : Point) return Point
     with Global => null;
   --  ∇f = 4(x−3)³.

   function Quartic_1D_Hess (X : Point) return Matrix
     with Global => null;
   --  ∇²f = 12(x−3)² (zero at the minimizer).

   function Shifted_Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = Σ (x_i − 1)²; unique min 0 at (1,…,1).

   function Shifted_Sphere_Grad (X : Point) return Point
     with Global => null;

   function Shifted_Sphere_Hess (X : Point) return Matrix
     with Global => null;
   --  ∇²f = 2 I.

   ---------------------------------------------------------------------------
   -- Driver
   ---------------------------------------------------------------------------

   function Minimize
     (Objective : Objective_Fn;
      X0        : Point;
      Grad      : Gradient_Fn := null;
      Hess      : Hessian_Fn := null;
      Cfg       : Config := Default_Config) return Result
     with Pre => Objective /= null
            and then X0'Length >= 1
            and then X0'Length <= Max_Dim,
          Global => null;
   --  Newton's method for unconstrained minimization of Objective.
   --  Direction: solve H(x) p = −∇f(x) (optionally after τ I shift).
   --  Update: x ← x + α p with α=1 (pure) or Armijo (damped).
   --  Missing Grad/Hess → central finite differences.
   --  Falls back to steepest descent if the linear solve fails / direction
   --  is not descent.

end Newtons_Method_Optimization;
