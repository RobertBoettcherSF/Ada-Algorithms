--  Rayleigh_Quotient_Iteration — Ada 2023 educational package for
--  Wikipedia "Rayleigh quotient iteration": inverse iteration with the
--  Rayleigh quotient shift μ_k = R(A, x_k) for Hermitian / symmetric A.
--  Cubic local convergence near an eigenpair. Cap n ≤ 16; dense Float;
--  each step solves (A − μ I) y = x via self-contained GEPP.
--  Primary source:
--  https://en.wikipedia.org/wiki/Rayleigh_quotient_iteration
--  Siblings: Ada-Gram-Schmidt; upcoming Power / Inverse / QR / Lanczos /
--  Arnoldi / Eigenvalue survey (README links).

pragma Ada_2022;

package Rayleigh_Quotient_Iteration
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

   --  Tol           : stop when ‖A x − μ x‖₂ ≤ Tol
   --  Max_Iter      : hard iteration budget (default 50)
   --  Initial_Mu    : optional starting shift (used iff Use_Initial_Mu)
   --  Use_Initial_Mu: False ⇒ μ₀ := R(A, x₀) after normalizing x₀
   type Parameters is record
      Tol            : Float   := 1.0E-6;
      Max_Iter       : Natural := 50;
      Initial_Mu     : Float   := 0.0;
      Use_Initial_Mu : Boolean := False;
   end record;

   Default_Parameters : constant Parameters :=
     (Tol => 1.0E-6, Max_Iter => 50, Initial_Mu => 0.0,
      Use_Initial_Mu => False);

   type Status is
     (Converged,
      Iteration_Limit,
      Singular_Shift,
      Breakdown,
      Ill_Started,
      Dimension_Error);

   --  Mu / X hold the approximate eigenpair; Residual = ‖A x − μ x‖₂.
   type Result is record
      Mu         : Float := 0.0;
      X          : Vector (1 .. Max_N) := [others => 0.0];
      N          : Dimension := 0;
      Iterations : Natural := 0;
      Residual   : Float := 0.0;
      Stat       : Status := Ill_Started;
      Success    : Boolean := False;
   end record;

   type Example_Kind is
     (Diagonal_Known, Poisson_1D, Hilbert_Tiny, Symmetric_Randomish);

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

   function Eigen_Residual (A : Matrix; X : Vector; Mu : Float) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length >= 1,
          Global => null;
   --  r = A x − μ x

   function Eigen_Residual_Norm
     (A : Matrix; X : Vector; Mu : Float) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length >= 1,
          Global => null;
   --  ‖A x − μ x‖₂

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
   --  diag(Eigs); known eigenvalues = Eigs entries, std basis eigenvectors.

   function Make_Symmetric_Example
     (Kind : Example_Kind; N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  Diagonal_Known      : diag(1, 2, …, N)
   --  Poisson_1D          : tridiagonal (−1, 2, −1) Dirichlet Laplacian
   --  Hilbert_Tiny        : H_ij = 1/(i+j−1)
   --  Symmetric_Randomish : deterministic dense symmetric (Float recipe)

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
   -- Rayleigh quotient iteration
   ---------------------------------------------------------------------------

   function Iterate
     (A      : Matrix;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X0'Length
            and then X0'Length >= 1
            and then X0'Length <= Max_N;
   --  Normalize x₀; set μ₀ from Params or R(A, x₀); then repeatedly
   --  solve (A − μ I) y = x, x ← y/‖y‖, μ ← R(A, x) until residual
   --  ≤ Tol, Max_Iter, singular shift, or breakdown.

   function Solve
     (A      : Matrix;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X0'Length
            and then X0'Length >= 1
            and then X0'Length <= Max_N;
   --  Alias for Iterate (eigenpair “solve”).

end Rayleigh_Quotient_Iteration;
