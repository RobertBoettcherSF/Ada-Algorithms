--  Inverse_Iteration — Ada 2023 educational package for Wikipedia
--  "Inverse iteration" (inverse power method): find an eigenpair near a
--  fixed shift μ by repeatedly solving (A − μ I) y = x and normalizing.
--  Cap n ≤ 16; dense educational Float; self-contained GEPP each step.
--  Sibling of Rayleigh quotient iteration (which updates μ each step) —
--  here μ stays fixed.
--  Primary source:
--  https://en.wikipedia.org/wiki/Inverse_iteration
--  Siblings: Ada-Power-Iteration, Ada-Rayleigh-Quotient-Iteration,
--  Ada-QR-Algorithm, Ada-Lanczos, Ada-Jacobi-Eigenvalue; upcoming
--  Arnoldi / Eigenvalue survey (README links).

pragma Ada_2022;

package Inverse_Iteration
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

   --  Tol      : stop when ‖A x − λ x‖₂ ≤ Tol
   --  Max_Iter : hard iteration budget (default 100)
   --  Mu       : fixed shift near the desired eigenvalue
   type Parameters is record
      Tol      : Float   := 1.0E-6;
      Max_Iter : Natural := 100;
      Mu       : Float   := 0.0;
   end record;

   Default_Parameters : constant Parameters :=
     (Tol => 1.0E-6, Max_Iter => 100, Mu => 0.0);

   type Status is
     (Converged,
      Iteration_Limit,
      Singular_Shift,
      Breakdown,
      Ill_Started,
      Dimension_Error);

   --  Eigenvalue / Eigenvector hold the approximate eigenpair nearest Mu;
   --  Residual = ‖A x − λ x‖₂; Mu echoes the fixed shift used.
   type Result is record
      Eigenvalue  : Float := 0.0;
      Eigenvector : Vector (1 .. Max_N) := [others => 0.0];
      N           : Dimension := 0;
      Iterations  : Natural := 0;
      Residual    : Float := 0.0;
      Mu          : Float := 0.0;
      Stat        : Status := Ill_Started;
      Success     : Boolean := False;
   end record;

   type Example_Kind is
     (Diagonal_Known,
      Poisson_1D,
      Known_Spectrum_Symmetric);

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-10;
   Pivot_Tol   : constant Float := 1.0E-12;
   Norm_Tol    : constant Float := 1.0E-14;

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

   function Normalize (V : Vector) return Vector
     with Pre => V'Length >= 1, Global => null;
   --  V / ‖V‖₂. Raises Invalid_Argument if ‖V‖ ≤ Norm_Tol.

   ---------------------------------------------------------------------------
   -- Rayleigh quotient and eigen residual
   ---------------------------------------------------------------------------

   function Rayleigh_Quotient (A : Matrix; X : Vector) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length >= 1,
          Global => null;
   --  R(A, x) = (xᵀ A x) / (xᵀ x). Raises Invalid_Argument if ‖x‖ = 0.

   function Eigen_Residual
     (A : Matrix; X : Vector; Lambda : Float) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length >= 1,
          Global => null;
   --  r = A x − λ x

   function Eigen_Residual_Norm
     (A : Matrix; X : Vector; Lambda : Float) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length >= 1,
          Global => null;
   --  ‖A x − λ x‖₂

   ---------------------------------------------------------------------------
   -- Internal dense shift solve (educational GEPP) — public for tests
   ---------------------------------------------------------------------------

   type Solve_Status is (Ok, Singular, Zero_Pivot);

   type Linear_Result is record
      Y       : Vector (1 .. Max_N) := [others => 0.0];
      N       : Dimension := 0;
      Stat    : Solve_Status := Singular;
      Success : Boolean := False;
   end record;

   function Solve_Shifted
     (A : Matrix; Mu : Float; X : Vector) return Linear_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length >= 1
            and then X'Length <= Max_N,
          Global => null;
   --  Solve (A − μ I) y = x with dense GEPP. Singular / Zero_Pivot on
   --  tiny pivots (typical when μ is already an exact eigenvalue).

   ---------------------------------------------------------------------------
   -- Example / builder matrices
   ---------------------------------------------------------------------------

   function Make_Diagonal (Eigs : Vector) return Matrix
     with Pre => Eigs'Length >= 1 and then Eigs'Length <= Max_N,
          Global => null;
   --  diag(Eigs); known eigenvalues = Eigs; std basis eigenvectors.

   function Make_Poisson_1D (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  SPD tridiagonal (−1, 2, −1) Dirichlet Laplacian; eigenvalues
   --  λ_k = 2 − 2 cos(kπ/(N+1)) ∈ (0, 4).

   function Make_Known_Spectrum_Symmetric
     (Eigs : Vector) return Matrix
     with Pre => Eigs'Length >= 1 and then Eigs'Length <= Max_N,
          Global => null;
   --  Orthogonal similarity Q diag(Eigs) Qᵀ with a fixed dense Q
   --  (deterministic MGS). Spectrum = Eigs (up to Float).

   function Make_Example
     (Kind : Example_Kind; N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  Diagonal_Known           : diag(1, 2, …, N)
   --  Poisson_1D               : Make_Poisson_1D (N)
   --  Known_Spectrum_Symmetric : spectrum 1..N via similarity

   function Make_Ones_Vector (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Make_Unit_Vector
     (N : Dimension; K : Dim_Index) return Vector
     with Pre => N >= 1 and then K <= N, Global => null;
   --  e_K in R^N.

   function Make_Perturbed_Basis
     (N : Dimension; K : Dim_Index; Eps : Float := 0.1) return Vector
     with Pre => N >= 1 and then K <= N, Global => null;
   --  Normalize(e_K + Eps · ones) — useful nonzero start near e_K.

   ---------------------------------------------------------------------------
   -- Inverse iteration (fixed shift μ)
   ---------------------------------------------------------------------------

   function Iterate
     (A      : Matrix;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X0'Length
            and then X0'Length >= 1
            and then X0'Length <= Max_N;
   --  Normalize x₀; repeatedly solve (A − μ I) y = x with fixed μ =
   --  Params.Mu, x ← y/‖y‖, λ ← R(A, x) until residual ≤ Tol,
   --  Max_Iter, singular shift, or breakdown.

   function Eigenpair_Near
     (A      : Matrix;
      Mu     : Float;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X0'Length
            and then X0'Length >= 1
            and then X0'Length <= Max_N;
   --  Inverse iteration with explicit shift Mu (overrides Params.Mu).

   function Eigenpair_Near
     (A      : Matrix;
      Mu     : Float;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) <= Max_N and then A'Length (2) <= Max_N;
   --  Default start x₀ = ones / ‖ones‖. Returns Dimension_Error if A
   --  is empty or not square.

   function Eigenpair_Near
     (A      : Matrix;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) <= Max_N and then A'Length (2) <= Max_N;
   --  Uses Params.Mu and default ones start.

end Inverse_Iteration;
