--  System_Of_Linear_Equations — Ada 2023 educational survey package for
--  Wikipedia "System of linear equations": taxonomy + minimal working
--  sketches of major solution families for Ax = b (direct dense GEPP,
--  Thomas tridiagonal, Jacobi / Gauss–Seidel, CG for SPD). Self-contained;
--  sibling solvers linked in README only — not package dependencies.
--  Cap n ≤ 16; educational Float.
--  Primary source: https://en.wikipedia.org/wiki/System_of_linear_equations

pragma Ada_2022;

package System_Of_Linear_Equations
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   Max_N : constant := 16;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   type Vector is array (Positive range <>) of Float;
   type Matrix is array (Positive range <>, Positive range <>) of Float;

   --  Iterative / Krylov controls.
   --  Tol      : stop when ‖r‖₂ ≤ Tol
   --  Max_Iter : hard budget; 0 ⇒ generous default (or N for CG)
   type Parameters is record
      Tol      : Float   := 1.0E-6;
      Max_Iter : Natural := 0;
   end record;

   Default_Parameters : constant Parameters :=
     (Tol => 1.0E-6, Max_Iter => 0);

   Default_Max_Iter_Stationary : constant Natural := 5_000;
   --  CG default Max_Iter when 0 is N (finite termination under exact arith).

   type Status is
     (Ok, Converged, Singular, Zero_Pivot, Zero_Diagonal,
      Iteration_Limit, Breakdown, Dimension_Error, Ill_Started,
      Not_Tridiagonal);

   type Result is record
      X          : Vector (1 .. Max_N) := [others => 0.0];
      N          : Dimension := 0;
      Iterations : Natural := 0;
      Residual   : Float := 0.0;
      Stat       : Status := Ill_Started;
      Success    : Boolean := False;
      Swap_Count : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Method taxonomy (Wikipedia: elimination / iterative / structured)
   ---------------------------------------------------------------------------

   type Method_Kind is
     (Gaussian_Elimination,
      Thomas,
      Jacobi,
      Gauss_Seidel,
      Conjugate_Gradient,
      BiCG);

   type Method_Info is record
      Kind            : Method_Kind;
      Is_Direct       : Boolean;
      Is_Iterative    : Boolean;
      Needs_SPD       : Boolean;
      Needs_DD        : Boolean;  --  sufficient (not necessary) for Jacobi/GS
      Structured_Only : Boolean;  --  Thomas: tridiagonal band
   end record;

   --  Lightweight property flags for Classify_Matrix / Recommend_Method.
   type Matrix_Properties is record
      N                      : Dimension := 0;
      Symmetric              : Boolean := False;
      Diagonally_Dominant    : Boolean := False;
      Strictly_DD            : Boolean := False;
      Positive_Diagonal      : Boolean := False;
      SPD_Heuristic          : Boolean := False;
      --  Symmetric ∧ positive diagonal ∧ (row) DD — educational proxy,
      --  not a true SPD certificate.
      Tridiagonal            : Boolean := False;
      Singular_Heuristic     : Boolean := False;
      --  Zero row-sum of abs, or zero diagonal entry.
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-10;
   Pivot_Tol   : constant Float := 1.0E-12;
   Diagonal_Tol : constant Float := 1.0E-12;

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

   function Is_Square (A : Matrix) return Boolean
     with Global => null;

   function Is_Symmetric
     (A : Matrix; Tol : Float := 1.0E-6) return Boolean
     with Pre => A'Length (1) = A'Length (2) and then Tol >= 0.0,
          Global => null;

   function Is_Diagonally_Dominant (A : Matrix) return Boolean
     with Pre => A'Length (1) = A'Length (2), Global => null;
   --  |A_ii| ≥ Σ_{j≠i} |A_ij| for every row.

   function Is_Strictly_Diagonally_Dominant (A : Matrix) return Boolean
     with Pre => A'Length (1) = A'Length (2), Global => null;

   function Is_Tridiagonal
     (A : Matrix; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => A'Length (1) = A'Length (2) and then Tol >= 0.0,
          Global => null;
   --  |A_ij| ≤ Tol whenever |i−j| > 1.

   function Has_Positive_Diagonal
     (A : Matrix; Tol : Float := Diagonal_Tol) return Boolean
     with Pre => A'Length (1) = A'Length (2) and then Tol >= 0.0,
          Global => null;

   ---------------------------------------------------------------------------
   -- Residuals: r = b − A x
   ---------------------------------------------------------------------------

   function Residual (A : Matrix; X, B : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length = B'Length
            and then X'Length >= 1,
          Global => null;

   function Residual_Norm (A : Matrix; X, B : Vector) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length = B'Length
            and then X'Length >= 1,
          Global => null;
   --  ‖b − A x‖₂

   ---------------------------------------------------------------------------
   -- Builders (Identity, DD, Poisson 1D, nonsym, singular, …)
   ---------------------------------------------------------------------------

   function Zero_Vector (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Ones_Vector (N : Dimension; Value : Float := 1.0) return Vector
     with Pre => N >= 1, Global => null;

   function Identity (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   --  Strictly row-DD: A_ii = N, A_ij = 1 (i≠j). Also symmetric / SPD-ish.
   function Make_Diagonally_Dominant (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   --  Dense (−1, 2, −1) Poisson 1-D Laplacian (tridiagonal stored densely).
   function Make_Poisson_1D (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   --  Upper-triangular-ish nonsymmetric: A_ii = N, A_ij = 1 for j > i,
   --  A_ij = 0.5 for j < i. Strictly DD, not symmetric.
   function Make_Nonsymmetric_DD (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   --  Rank-deficient: first two rows identical (educational singular).
   function Make_Singular (N : Dimension) return Matrix
     with Pre => N >= 2, Global => null;

   --  A = diag(N+1) + ones (SPD, DD).
   function Make_Diagonal_Plus_Ones (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   function Make_RHS_Ones (N : Dimension; Value : Float := 1.0) return Vector
     with Pre => N >= 1, Global => null;

   --  b := A x*  (manufacture exact solutions).
   function Make_RHS_From_Solution
     (A : Matrix; X_Star : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X_Star'Length
            and then X_Star'Length >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- Taxonomy helpers
   ---------------------------------------------------------------------------

   function Classify_Matrix
     (A : Matrix; Tol : Float := 1.0E-6) return Matrix_Properties
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N
            and then Tol >= 0.0,
          Global => null;

   function Recommend_Method (P : Matrix_Properties) return Method_Kind
     with Global => null;
   --  Heuristic:
   --    singular heuristic → Gaussian_Elimination (will report Singular)
   --    tridiagonal        → Thomas
   --    SPD heuristic      → Conjugate_Gradient (or GE if tiny)
   --    strictly DD        → Gauss_Seidel
   --    else               → Gaussian_Elimination

   function Classify_Method (K : Method_Kind) return Method_Info
     with Global => null;

   function Method_Name (K : Method_Kind) return String
     with Global => null;

   function Method_Count return Positive
     with Global => null;

   ---------------------------------------------------------------------------
   -- Direct dense: Gaussian elimination with partial pivoting + back-sub
   ---------------------------------------------------------------------------

   function Solve_GE (A : Matrix; B : Vector) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N;
   --  Copy A|b; GEPP forward elimination; back substitution.
   --  Singular / Zero_Pivot on tiny pivots.

   ---------------------------------------------------------------------------
   -- Direct structured: Thomas (tridiagonal) forward / back
   ---------------------------------------------------------------------------

   function Solve_Thomas (A : Matrix; B : Vector) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N;
   --  Extracts sub/diag/super from dense A; requires Is_Tridiagonal.
   --  Not_Tridiagonal / Zero_Pivot / Singular on failure.

   ---------------------------------------------------------------------------
   -- Stationary iterative: Jacobi and Gauss–Seidel
   ---------------------------------------------------------------------------

   function Solve_Jacobi
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N
            and then (X0'Length = 0 or else X0'Length = B'Length);
   --  x^{k+1} = D⁻¹ (b − (L+U) x^k). Empty X0 ⇒ zero start.
   --  Requires nonzero diagonals. Strict DD ⇒ convergence.

   function Solve_Gauss_Seidel
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N
            and then (X0'Length = 0 or else X0'Length = B'Length);
   --  In-place successive displacement (≡ SOR with ω = 1).

   ---------------------------------------------------------------------------
   -- Krylov sketch: CG for SPD (BiCG catalogued, not implemented)
   ---------------------------------------------------------------------------

   function Solve_CG
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N
            and then (X0'Length = 0 or else X0'Length = B'Length);
   --  Classical Hestenes–Stiefel CG for SPD Ax = b.
   --  Max_Iter = 0 ⇒ budget N. BiCG for nonsymmetric: see sibling.

   ---------------------------------------------------------------------------
   -- Dispatcher
   ---------------------------------------------------------------------------

   function Solve
     (A      : Matrix;
      B      : Vector;
      Kind   : Method_Kind := Gaussian_Elimination;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N
            and then (X0'Length = 0 or else X0'Length = B'Length);
   --  Dispatch to Solve_GE / Thomas / Jacobi / GS / CG.
   --  BiCG → Ill_Started (catalogued only; use Ada-Biconjugate-Gradient).

   function Solve_Auto
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N
            and then (X0'Length = 0 or else X0'Length = B'Length);
   --  Classify_Matrix → Recommend_Method → Solve.

end System_Of_Linear_Equations;
