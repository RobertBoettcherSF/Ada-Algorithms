--  Gauss_Newton — Ada 2023 educational package for Wikipedia
--  "Gauss–Newton algorithm": iterative nonlinear least-squares solver
--  that linearizes residuals via the Jacobian and solves the undamped
--  normal equations
--    (JᵀJ) δ = −Jᵀ r
--  with optional simple backtracking line search when the full step
--  raises the cost. NO λ damping (contrast with Levenberg–Marquardt).
--  Primary source:
--  https://en.wikipedia.org/wiki/Gauss–Newton_algorithm
--  Siblings: Ada-Levenberg-Marquardt / Ada-Nelder-Mead (README links).

pragma Ada_2022;

package Gauss_Newton
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

   --  Dense n×n matrix for the normal equations (n ≤ Max_Params).
   type Square_Matrix is
     array (Param_Index range <>, Param_Index range <>) of Real;

   --  Max_Iterations : hard iteration budget
   --  Step_Tol       : stop when ‖δ‖ ≤ Step_Tol (accepted step)
   --  Cost_Tol       : stop when relative cost improvement ≤ Cost_Tol
   --  Fd_Eps         : finite-difference step for numerical Jacobian
   --  Use_Line_Search: if True, backtrack α when S(β+αδ) rises
   --  Line_Search_Rho: multiply α by this on each backtrack (e.g. 0.5)
   --  Max_Line_Search: max backtracking attempts per outer iteration
   type Config is record
      Max_Iterations  : Positive      := 200;
      Step_Tol        : Non_Negative  := 1.0E-10;
      Cost_Tol        : Non_Negative  := 1.0E-12;
      Fd_Eps          : Positive_Real := 1.0E-7;
      Use_Line_Search : Boolean       := True;
      Line_Search_Rho : Positive_Real := 0.5;
      Max_Line_Search : Positive      := 20;
   end record;

   type Result is record
      Final_Params : Parameter_Vector (1 .. Max_Params) := [others => 0.0];
      Final_Cost   : Non_Negative := 0.0;
      N_Params     : Param_Count := 1;
      N_Residuals  : Residual_Count := 1;
      Iterations   : Natural := 0;
      Success      : Boolean := False;
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
   --  S(β) = ½ ‖r‖²  (½ Σ r_i²); conventional NLS cost.

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
   --  Forward finite-difference Jacobian of residuals.

   function Backtrack_Alpha
     (Alpha0 : Positive_Real;
      Rho    : Positive_Real;
      K      : Natural) return Positive_Real
     with Global => null;
   --  α_k = Alpha0 · Rho^K  (simple geometric backtracking schedule).

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
   --  Undamped Gauss–Newton nonlinear least squares. If Jac is null, a
   --  finite-difference Jacobian is used. Residuals from Model must have
   --  length in 1 .. Max_Residuals. Optional backtracking line search
   --  (Config.Use_Line_Search) keeps the core update β ← β + αδ clear.

   function Minimize
     (Model     : Model_Fn;
      Beta0     : Parameter_Vector;
      Jac       : Jacobian_Fn := null;
      Cfg       : Config := (others => <>)) return Result
     renames Fit;
   --  Alias for Fit (minimize cost S = ½ ‖r‖²).

end Gauss_Newton;
