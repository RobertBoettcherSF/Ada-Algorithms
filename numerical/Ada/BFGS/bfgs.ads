--  BFGS — Ada 2023 educational package for Wikipedia
--  "Broyden–Fletcher–Goldfarb–Shanno algorithm": quasi-Newton
--  unconstrained minimizer that maintains an approximate inverse
--  Hessian H and takes search directions p = −H g, updating H from
--  successive (s, y) pairs without forming second derivatives.
--  Primary source:
--  https://en.wikipedia.org/wiki/Broyden–Fletcher–Goldfarb–Shanno_algorithm
--  Siblings: Ada-Gauss-Newton / Ada-Levenberg-Marquardt / Ada-Nelder-Mead
--  (README links).

pragma Ada_2022;

package BFGS
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

   --  Dense n×n matrix (inverse-Hessian H or Hessian B).
   type Matrix is array (Dim_Index range <>, Dim_Index range <>) of Real;

   --  Max_Iterations   : hard outer iteration budget
   --  Grad_Tol         : stop when ‖∇f‖ ≤ Grad_Tol
   --  Step_Tol         : stop when ‖α p‖ ≤ Step_Tol
   --  Fd_Eps           : finite-difference step for numerical gradient
   --  Armijo_C         : sufficient-decrease constant c₁ ∈ (0,1)
   --  Line_Search_Rho  : multiply α by this on each backtrack (e.g. 0.5)
   --  Max_Line_Search  : max Armijo backtracking attempts per iteration
   --  Scale_Initial_H  : after first successful step, set
   --                     H ← (sᵀy / yᵀy) I  before the first BFGS update
   type Config is record
      Max_Iterations  : Positive      := 200;
      Grad_Tol        : Non_Negative  := 1.0E-8;
      Step_Tol        : Non_Negative  := 1.0E-10;
      Fd_Eps          : Positive_Real := 1.0E-7;
      Armijo_C        : Positive_Real := 1.0E-4;
      Line_Search_Rho : Positive_Real := 0.5;
      Max_Line_Search : Positive      := 30;
      Scale_Initial_H : Boolean       := True;
   end record;

   type Result is record
      Final_Point     : Point (1 .. Max_Dim) := [others => 0.0];
      Final_Value     : Real         := 0.0;
      Final_Grad_Norm : Non_Negative := 0.0;
      Dim             : Dim_Count    := 1;
      Iterations      : Natural      := 0;
      Success         : Boolean      := False;
   end record;

   --  Smooth objective f : R^n → R to minimize.
   type Objective_Fn is access function (X : Point) return Real;

   --  Optional analytical gradient ∇f.
   type Gradient_Fn is access function (X : Point) return Point;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
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

   function Mat_Vec (A : Matrix; X : Point) return Point
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) = X'Length,
          Global => null;

   function Identity (N : Dim_Count) return Matrix
     with Global => null;
   --  N×N identity matrix.

   function Outer (U, V : Point) return Matrix
     with Pre => U'Length = V'Length, Global => null;
   --  Rank-1 matrix U Vᵀ.

   function Mat_Add (A, B : Matrix) return Matrix
     with Pre => A'Length (1) = A'Length (2)
            and then B'Length (1) = B'Length (2)
            and then A'Length (1) = B'Length (1),
          Global => null;

   function Mat_Scale (C : Real; A : Matrix) return Matrix
     with Pre => A'Length (1) = A'Length (2), Global => null;

   ---------------------------------------------------------------------------
   -- BFGS core (exposed for unit tests)
   ---------------------------------------------------------------------------

   function BFGS_Update
     (H : Matrix; S, Y : Point) return Matrix
     with Pre => H'Length (1) = H'Length (2)
            and then H'Length (1) = S'Length
            and then S'Length = Y'Length,
          Global => null;
   --  Inverse-Hessian BFGS update with ρ = 1/(yᵀs).
   --  If yᵀs ≤ 0 (curvature condition fails), returns H unchanged
   --  (skip / safeguard). Formula (Wikipedia / Nocedal–Wright):
   --    H ← (I − ρ s yᵀ) H (I − ρ y sᵀ) + ρ s sᵀ

   function Finite_Difference_Gradient
     (Obj : Objective_Fn;
      X   : Point;
      Eps : Positive_Real := 1.0E-7) return Point
     with Pre => Obj /= null and then X'Length >= 1, Global => null;
   --  Central finite-difference gradient (2n evaluations).

   function Line_Search
     (Obj     : Objective_Fn;
      X       : Point;
      F       : Real;
      G       : Point;
      P       : Point;
      C1      : Positive_Real;
      Rho     : Positive_Real;
      Max_LS  : Positive) return Positive_Real
     with Pre => Obj /= null
            and then X'Length = G'Length
            and then G'Length = P'Length
            and then C1 < 1.0,
          Global => null;
   --  Simple Armijo backtracking: start α=1, accept when
   --    f(x+αp) ≤ f(x) + c₁ α (gᵀp), else α ← ρ α.
   --  Raises Line_Search_Failed if no α accepted within Max_LS tries.

   function Armijo_Accept
     (F_New, F_Old, Alpha, C1, Dir_Deriv : Real) return Boolean
     with Global => null;
   --  True iff F_New ≤ F_Old + C1·Alpha·Dir_Deriv.

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
   --  Classic banana: f(x,y)=(a−x)² + b(y−x²)² with a=1, b=100.
   --  Global min 0 at (1,1). Uses first two coordinates.

   function Rosenbrock_Grad (X : Point) return Point
     with Global => null;

   function Quadratic_Bowl (X : Point) return Real
     with Global => null;
   --  f(x) = ½ Σ i·x_i²  (well-conditioned positive-definite bowl).
   --  Unique min 0 at the origin.

   function Quadratic_Bowl_Grad (X : Point) return Point
     with Global => null;

   function Himmelblau (X : Point) return Real
     with Global => null;
   --  f(x,y)=(x²+y−11)²+(x+y²−7)²; four global minima with f=0.
   --  Uses first two coordinates.

   function Himmelblau_Grad (X : Point) return Point
     with Global => null;

   function Shifted_Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = Σ (x_i − 1)²; unique min 0 at (1,…,1).

   function Shifted_Sphere_Grad (X : Point) return Point
     with Global => null;

   ---------------------------------------------------------------------------
   -- Driver
   ---------------------------------------------------------------------------

   function Minimize
     (Objective : Objective_Fn;
      X0        : Point;
      Grad      : Gradient_Fn := null;
      Cfg       : Config := (others => <>)) return Result
     with Pre => Objective /= null
            and then X0'Length >= 1
            and then X0'Length <= Max_Dim,
          Global => null;
   --  BFGS quasi-Newton minimization of Objective starting at X0.
   --  If Grad is null, a central finite-difference gradient is used.
   --  Maintains inverse Hessian H (init I; optional scaled identity after
   --  the first step). Line search is Armijo backtracking.

end BFGS;
