--  Levenberg_Marquardt — Ada 2023 educational package for Wikipedia
--  "Levenberg–Marquardt algorithm" (damped least squares; Levenberg
--  1944, Marquardt 1963): iterative nonlinear least-squares solver
--  that interpolates between Gauss–Newton and gradient descent via a
--  damping factor λ. Uses Marquardt diagonal scaling:
--    (JᵀJ + λ diag(JᵀJ)) δ = −Jᵀ r
--  Primary source:
--  https://en.wikipedia.org/wiki/Levenberg–Marquardt_algorithm
--  Siblings: Ada-Nelder-Mead / Ada-Simulated-Annealing /
--  Ada-Partial-Least-Squares (README links).

pragma Ada_2022;

package Levenberg_Marquardt
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Params     : constant := 8;
   Max_Residuals  : constant := 64;

   subtype Param_Count is Positive range 1 .. Max_Params;
   subtype Param_Index is Positive range 1 .. Max_Params;
   subtype Residual_Count is Positive range 1 .. Max_Residuals;
   subtype Residual_Index is Positive range 1 .. Max_Residuals;

   type Parameter_Vector is array (Param_Index range <>) of Real;
   type Residual_Vector  is array (Residual_Index range <>) of Real;

   --  Jacobian J(i,j) = ∂r_i / ∂β_j   (rows = residuals, cols = params)
   type Jacobian is
     array (Residual_Index range <>, Param_Index range <>) of Real;

   --  Dense n×n matrix for the damped normal equations (n ≤ Max_Params).
   type Square_Matrix is
     array (Param_Index range <>, Param_Index range <>) of Real;

   --  Lambda_Init : initial damping factor λ₀
   --  Lambda_Up   : multiply λ by this on a failed (cost-increasing) step
   --  Lambda_Down : divide λ by this on a successful (cost-decreasing) step
   --  Max_Iterations : hard iteration budget
   --  Step_Tol    : stop when ‖δ‖ ≤ Step_Tol
   --  Cost_Tol    : stop when relative cost improvement ≤ Cost_Tol
   --  Fd_Eps      : finite-difference step for numerical Jacobian
   type Config is record
      Lambda_Init    : Positive_Real := 1.0E-3;
      Lambda_Up      : Positive_Real := 10.0;
      Lambda_Down    : Positive_Real := 10.0;
      Max_Iterations : Positive      := 200;
      Step_Tol       : Non_Negative  := 1.0E-10;
      Cost_Tol       : Non_Negative  := 1.0E-12;
      Fd_Eps         : Positive_Real := 1.0E-7;
   end record;

   type Result is record
      Final_Params : Parameter_Vector (1 .. Max_Params) := [others => 0.0];
      Final_Cost   : Non_Negative := 0.0;
      N_Params     : Param_Count := 1;
      N_Residuals  : Residual_Count := 1;
      Iterations   : Natural := 0;
      Success      : Boolean := False;
      Final_Lambda : Non_Negative := 0.0;
   end record;

   --  Model: residuals r(β) to minimize ‖r‖²  (typically y − f(x,β)).
   type Model_Fn is access function
     (Beta : Parameter_Vector) return Residual_Vector;

   --  Optional analytical Jacobian of residuals ∂r/∂β.
   type Jacobian_Fn is access function
     (Beta : Parameter_Vector) return Jacobian;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   Singular_System  : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Params_Near
     (A, B : Parameter_Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   function Residuals_Near
     (A, B : Residual_Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   function Norm2 (X : Parameter_Vector) return Non_Negative
     with Global => null;

   function Residual_Norm2 (R : Residual_Vector) return Non_Negative
     with Global => null;

   function Dot (A, B : Parameter_Vector) return Real
     with Pre => A'Length = B'Length, Global => null;

   function Residual_Dot (A, B : Residual_Vector) return Real
     with Pre => A'Length = B'Length, Global => null;

   function Add (A, B : Parameter_Vector) return Parameter_Vector
     with Pre => A'Length = B'Length, Global => null;

   function Sub (A, B : Parameter_Vector) return Parameter_Vector
     with Pre => A'Length = B'Length, Global => null;

   function Scale (C : Real; X : Parameter_Vector) return Parameter_Vector
     with Global => null;

   function Cost (R : Residual_Vector) return Non_Negative
     with Global => null;
   --  S(β) = ½ ‖r‖²  (½ Σ r_i²); conventional LM cost.

   ---------------------------------------------------------------------------
   -- Linear algebra (exposed for unit tests)
   ---------------------------------------------------------------------------

   function JTJ (J : Jacobian) return Square_Matrix
     with Pre => J'Length (1) >= 1 and then J'Length (2) >= 1,
          Global => null;
   --  A = Jᵀ J  (n×n, n = number of columns of J).

   function JTr (J : Jacobian; R : Residual_Vector) return Parameter_Vector
     with Pre => J'Length (1) = R'Length and then J'Length (2) >= 1,
          Global => null;
   --  g = Jᵀ r

   function Mat_Vec (A : Square_Matrix; X : Parameter_Vector)
     return Parameter_Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) = X'Length,
          Global => null;

   function Solve_SPD
     (A : Square_Matrix; B : Parameter_Vector) return Parameter_Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) = B'Length,
          Global => null;
   --  Solve A x = b for small dense systems via Gaussian elimination
   --  with partial pivoting (n ≤ Max_Params). Raises Singular_System
   --  if the matrix is (numerically) singular.

   function Finite_Difference_Jacobian
     (Model : Model_Fn;
      Beta  : Parameter_Vector;
      Eps   : Positive_Real := 1.0E-7) return Jacobian
     with Pre => Model /= null and then Beta'Length >= 1,
          Global => null;
   --  Central/forward finite-difference Jacobian of residuals.

   function Damped_Normal_Matrix
     (A : Square_Matrix; Lambda : Non_Negative) return Square_Matrix
     with Pre => A'Length (1) = A'Length (2), Global => null;
   --  Marquardt form: A + λ diag(A), with floor on tiny diagonal entries.

   function Adjust_Lambda
     (Lambda     : Positive_Real;
      Improved   : Boolean;
      Lambda_Up  : Positive_Real;
      Lambda_Down : Positive_Real) return Positive_Real
     with Global => null;
   --  λ ← λ·Up on failure; λ ← λ/Down on success (floored away from 0).

   ---------------------------------------------------------------------------
   -- Built-in demo models (curve fitting / toy NLS)
   ---------------------------------------------------------------------------

   --  Shared sample abscissae / ordinates for the built-in fits.
   --  Linear_Truth:    y = 2 + 3 x
   --  Quadratic_Truth: y = 1 − 2 x + 0.5 x²
   --  Exp_Truth:       y = 5 · e^(−0.4 x)

   function Linear_Residuals (Beta : Parameter_Vector) return Residual_Vector
     with Global => null;
   --  r_i = y_i − (a + b x_i); Beta = (a, b). Needs ≥ 2 params.

   function Linear_Jacobian (Beta : Parameter_Vector) return Jacobian
     with Global => null;
   --  Analytical ∂r/∂β for Linear_Residuals.

   function Quadratic_Residuals
     (Beta : Parameter_Vector) return Residual_Vector
     with Global => null;
   --  r_i = y_i − (a + b x_i + c x_i²); Beta = (a, b, c).

   function Quadratic_Jacobian (Beta : Parameter_Vector) return Jacobian
     with Global => null;

   function Exp_Decay_Residuals
     (Beta : Parameter_Vector) return Residual_Vector
     with Global => null;
   --  r_i = y_i − a · e^(−b x_i); Beta = (a, b).

   function Exp_Decay_Jacobian (Beta : Parameter_Vector) return Jacobian
     with Global => null;

   function Rosenbrock_Residuals
     (Beta : Parameter_Vector) return Residual_Vector
     with Global => null;
   --  Two residuals: r1 = 1−x, r2 = 10(y−x²); min ‖r‖² = 0 at (1,1).

   function Rosenbrock_Jacobian (Beta : Parameter_Vector) return Jacobian
     with Global => null;

   function Sphere_Residuals (Beta : Parameter_Vector) return Residual_Vector
     with Global => null;
   --  r_i = Beta_i  (identity residual stack); min 0 at the origin.

   ---------------------------------------------------------------------------
   -- Driver
   ---------------------------------------------------------------------------

   function Fit
     (Model     : Model_Fn;
      Beta0     : Parameter_Vector;
      Jac       : Jacobian_Fn := null;
      Cfg       : Config := (others => <>)) return Result
     with Pre => Model /= null
            and then Beta0'Length >= 1
            and then Beta0'Length <= Max_Params,
          Global => null;
   --  Levenberg–Marquardt nonlinear least squares. If Jac is null, a
   --  finite-difference Jacobian is used. Residuals from Model must have
   --  length in 1 .. Max_Residuals.

   function Minimize
     (Model     : Model_Fn;
      Beta0     : Parameter_Vector;
      Jac       : Jacobian_Fn := null;
      Cfg       : Config := (others => <>)) return Result
     renames Fit;
   --  Alias for Fit (minimize cost S = ½ ‖r‖²).

end Levenberg_Marquardt;
