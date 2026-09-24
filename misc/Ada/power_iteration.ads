--  Power_Iteration — Ada 2023 educational package for Wikipedia
--  "Power iteration" (von Mises iteration): dominant eigenpair of a
--  diagonalizable matrix A via repeated multiply-and-normalize.
--  Cap n ≤ 32; dense educational Float; Rayleigh quotient for λ.
--  Primary source:
--  https://en.wikipedia.org/wiki/Power_iteration
--  Siblings: Ada-Rayleigh-Quotient-Iteration / Ada-QR-Algorithm;
--  upcoming Inverse / Lanczos / Arnoldi / Jacobi eigenvalue /
--  Eigenvalue survey (README links).

pragma Ada_2022;

package Power_Iteration
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   Max_N : constant := 32;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   type Vector is array (Positive range <>) of Float;
   type Matrix is array (Positive range <>, Positive range <>) of Float;

   --  Tol      : stop when ‖A x − λ x‖₂ ≤ Tol
   --  Max_Iter : hard iteration budget (default 200)
   type Parameters is record
      Tol      : Float   := 1.0E-6;
      Max_Iter : Natural := 200;
   end record;

   Default_Parameters : constant Parameters :=
     (Tol => 1.0E-6, Max_Iter => 200);

   type Status is
     (Converged,
      Iteration_Limit,
      Breakdown,
      Ill_Started,
      Dimension_Error);

   --  Eigenvalue / Eigenvector hold the approximate dominant eigenpair;
   --  Residual = ‖A x − λ x‖₂.
   type Result is record
      Eigenvalue  : Float := 0.0;
      Eigenvector : Vector (1 .. Max_N) := [others => 0.0];
      N           : Dimension := 0;
      Iterations  : Natural := 0;
      Residual    : Float := 0.0;
      Stat        : Status := Ill_Started;
      Success     : Boolean := False;
   end record;

   type Example_Kind is
     (Diagonal_Dominant,
      Scaled_Identity,
      Poisson_1D,
      Known_Spectrum_Symmetric);

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-10;
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
   -- Example / builder matrices
   ---------------------------------------------------------------------------

   function Make_Diagonal (Eigs : Vector) return Matrix
     with Pre => Eigs'Length >= 1 and then Eigs'Length <= Max_N,
          Global => null;
   --  diag(Eigs); known eigenvalues = Eigs; std basis eigenvectors.

   function Make_Scaled_Identity
     (N : Dimension; Scale : Float := 1.0) return Matrix
     with Pre => N >= 1, Global => null;
   --  Scale · I_N (every eigenvalue = Scale; any unit vector is an
   --  eigenvector — power method converges in one step to λ = Scale).

   function Make_Poisson_1D (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  SPD tridiagonal (−1, 2, −1) Dirichlet Laplacian; eigenvalues
   --  λ_k = 2 - 2 cos(kπ/(N+1)) ∈ (0, 4); dominant near 4.

   function Make_Known_Spectrum_Symmetric
     (Eigs : Vector) return Matrix
     with Pre => Eigs'Length >= 1 and then Eigs'Length <= Max_N,
          Global => null;
   --  Orthogonal similarity Q diag(Eigs) Qᵀ with a fixed Householder-
   --  ish dense Q (deterministic). Spectrum = Eigs (up to Float).

   function Make_Example
     (Kind : Example_Kind; N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  Diagonal_Dominant      : diag(1, 2, …, N) — clear dominant λ = N
   --  Scaled_Identity        : I_N
   --  Poisson_1D             : Make_Poisson_1D (N)
   --  Known_Spectrum_Symmetric : spectrum 1..N via similarity

   function Make_Ones_Vector (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Make_Unit_Vector
     (N : Dimension; K : Dim_Index) return Vector
     with Pre => N >= 1 and then K <= N, Global => null;

   function Make_Perturbed_Basis
     (N : Dimension; K : Dim_Index; Eps : Float := 0.1) return Vector
     with Pre => N >= 1 and then K <= N, Global => null;
   --  Normalize(e_K + Eps · ones).

   ---------------------------------------------------------------------------
   -- Power iteration (dominant eigenpair)
   ---------------------------------------------------------------------------

   function Iterate
     (A      : Matrix;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X0'Length
            and then X0'Length >= 1
            and then X0'Length <= Max_N;
   --  Normalize x₀; repeatedly y ← A x, x ← y/‖y‖, λ ← R(A, x)
   --  until residual ≤ Tol, Max_Iter, or breakdown (‖y‖ ≈ 0).

   function Dominant_Eigenpair
     (A      : Matrix;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X0'Length
            and then X0'Length >= 1
            and then X0'Length <= Max_N;
   --  Alias for Iterate.

   function Dominant_Eigenpair
     (A      : Matrix;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) <= Max_N and then A'Length (2) <= Max_N;
   --  Default start x₀ = ones / ‖ones‖. Returns Dimension_Error if A
   --  is empty or not square (Pre does not require squareness).

end Power_Iteration;
