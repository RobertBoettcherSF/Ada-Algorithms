--  Conjugate_Gradient — Ada 2023 educational package for Wikipedia
--  "Conjugate gradient method" (Hestenes–Stiefel, 1952): iterative
--  solver for symmetric positive-definite (SPD) linear systems Ax = b,
--  equivalently minimizing the quadratic ½ xᵀ A x − bᵀ x. Optional
--  Fletcher–Reeves nonlinear CG sketch for smooth f with a gradient
--  oracle (Sphere / Rosenbrock demos). Cap n ≤ 16; dense Float.
--  Primary source:
--  https://en.wikipedia.org/wiki/Conjugate_gradient_method
--  Siblings: Ada-Gradient-Descent / Ada-BFGS / Ada-Gauss-Newton /
--  Ada-Nonlinear-Optimization (README links).

pragma Ada_2022;

package Conjugate_Gradient
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   Max_N : constant := 16;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   type Vector is array (Positive range <>) of Float;
   type Matrix is array (Positive range <>, Positive range <>) of Float;

   --  Tol      : stop when ‖r‖₂ ≤ Tol
   --  Max_Iter : hard iteration budget; 0 means use N (finite-termination
   --             bound under exact arithmetic for SPD CG)
   type Parameters is record
      Tol      : Float   := 1.0E-6;
      Max_Iter : Natural := 0;
   end record;

   Default_Parameters : constant Parameters := (Tol => 1.0E-6, Max_Iter => 0);

   type Status is
     (Converged, Iteration_Limit, Breakdown, Ill_Started);

   type Result is record
      X          : Vector (1 .. Max_N) := [others => 0.0];
      N          : Dimension := 0;
      Iterations : Natural := 0;
      Residual   : Float := 0.0;
      Stat       : Status := Ill_Started;
      Success    : Boolean := False;
   end record;

   type Example_Kind is (Hilbert_Tiny, Diagonal_Plus_Ones, Poisson_1D);

   --  Smooth objective / gradient oracles for optional nonlinear CG.
   type Objective_Fn is access function (X : Vector) return Float;
   type Gradient_Fn  is access function (X : Vector) return Vector;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-10;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vec_Near
     (A, B : Vector; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   function Dot (U, V : Vector) return Float
     with Pre => U'Length = V'Length, Global => null;

   function Norm2 (V : Vector) return Float
     with Global => null;

   function Scale (V : Vector; S : Float) return Vector
     with Global => null;

   function Add (U, V : Vector) return Vector
     with Pre => U'Length = V'Length, Global => null;

   function Sub (U, V : Vector) return Vector
     with Pre => U'Length = V'Length, Global => null;

   function Mat_Vec (A : Matrix; X : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length,
          Global => null;

   function Is_Symmetric
     (A : Matrix; Tol : Float := 1.0E-6) return Boolean
     with Pre => A'Length (1) = A'Length (2) and then Tol >= 0.0,
          Global => null;
   --  |A_ij − A_ji| ≤ Tol for all i, j (light SPD prerequisite).

   function Is_Diagonally_Dominant (A : Matrix) return Boolean
     with Pre => A'Length (1) = A'Length (2), Global => null;
   --  |A_ii| ≥ Σ_{j≠i} |A_ij| for every row (sufficient for SPD when
   --  also symmetric with positive diagonal — not necessary).

   function Residual_Norm (A : Matrix; X, B : Vector) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length = B'Length,
          Global => null;
   --  ‖b − A x‖₂

   function Residual (A : Matrix; X, B : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length = B'Length,
          Global => null;
   --  r = b − A x

   ---------------------------------------------------------------------------
   -- Example SPD generators
   ---------------------------------------------------------------------------

   function Make_SPD_Example
     (Kind : Example_Kind; N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  Hilbert_Tiny       : H_ij = 1/(i+j−1) (tiny / ill-conditioned)
   --  Diagonal_Plus_Ones : A = diag(N+1,…,N+1) + ones (SPD)
   --  Poisson_1D         : tridiagonal (−1, 2, −1) discrete Laplacian

   function Make_RHS_Ones (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Zero_Vector (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   ---------------------------------------------------------------------------
   -- Classical Hestenes–Stiefel CG for SPD Ax = b
   ---------------------------------------------------------------------------

   function Conjugate_Gradient
     (A      : Matrix;
      B      : Vector;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length = X0'Length
            and then B'Length >= 1
            and then B'Length <= Max_N;
   --  r₀ = b − A x₀; p₀ = r₀; then α, x, r, β, p updates until
   --  ‖r‖ ≤ Tol or Max_Iter (default N) steps.

   function Solve_SPD
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N
            and then (X0'Length = 0 or else X0'Length = B'Length);
   --  Convenience wrapper: empty X0 ⇒ start at the zero vector.

   ---------------------------------------------------------------------------
   -- Optional Fletcher–Reeves nonlinear CG (educational sketch)
   ---------------------------------------------------------------------------

   function Fletcher_Reeves
     (Objective : Objective_Fn;
      Grad      : Gradient_Fn;
      X0        : Vector;
      Params    : Parameters := Default_Parameters) return Result
     with Pre => Objective /= null
            and then Grad /= null
            and then X0'Length >= 1
            and then X0'Length <= Max_N;
   --  β_FR = ‖g_{k+1}‖² / ‖g_k‖²; Armijo backtracking along p.
   --  Restarts with p = −g when a direction is not a descent direction.

   function Sphere (X : Vector) return Float
     with Pre => X'Length >= 1, Global => null;
   --  f(x) = ½ ‖x‖²  (unique minimizer at 0).

   function Sphere_Grad (X : Vector) return Vector
     with Pre => X'Length >= 1, Global => null;

   function Rosenbrock (X : Vector) return Float
     with Pre => X'Length = 2, Global => null;
   --  Classic 2-D Rosenbrock: f = (1−x)² + 100 (y−x²)².

   function Rosenbrock_Grad (X : Vector) return Vector
     with Pre => X'Length = 2, Global => null;

end Conjugate_Gradient;
