--  Jacobi_Eigenvalue — Ada 2023 educational package for Wikipedia
--  "Jacobi eigenvalue algorithm": plane-rotation diagonalization of a
--  real symmetric matrix S. Cap n ≤ 16; dense educational Float.
--  NOT the Jacobi iterative solver for Ax=b (that is a different method;
--  see Ada-System-of-Linear-Equations / Gauss–Seidel family).
--  Primary source:
--  https://en.wikipedia.org/wiki/Jacobi_eigenvalue_algorithm
--  Siblings: Ada-QR-Algorithm, Ada-Lanczos, Ada-Power-Iteration,
--  Ada-Rayleigh-Quotient-Iteration; upcoming Inverse / Arnoldi /
--  Eigenvalue survey (README links).

pragma Ada_2022;

package Jacobi_Eigenvalue
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

   --  Cyclic    : each sweep rotates every upper-triangle pair (i,j)
   --              once in row-major order (standard educational path).
   --  Classical : each rotation zeros the current largest |s_ij|.
   type Sweep_Mode is (Cyclic, Classical);

   --  Tol         : stop when Off_Diag_Norm(S) ≤ Tol
   --  Max_Sweeps  : hard sweep budget (default 50)
   --  Mode        : Cyclic (default) or Classical pivot search
   --  Sort_Eigs   : if True, sort eigenvalues ascending and permute V
   type Parameters is record
      Tol        : Float      := 1.0E-8;
      Max_Sweeps : Natural    := 50;
      Mode       : Sweep_Mode := Cyclic;
      Sort_Eigs  : Boolean    := True;
   end record;

   Default_Parameters : constant Parameters :=
     (Tol => 1.0E-8, Max_Sweeps => 50,
      Mode => Cyclic, Sort_Eigs => True);

   type Status is
     (Converged,
      Iteration_Limit,
      Not_Symmetric,
      Ill_Started,
      Dimension_Error);

   --  Eigenvalues = diagonal of final S; eigenvectors = columns of V.
   --  Final_S holds the nearly-diagonal similar matrix.
   type Result is record
      Eigenvalues   : Vector (1 .. Max_N) := [others => 0.0];
      Eigenvectors  : Matrix (1 .. Max_N, 1 .. Max_N) :=
                        [others => [others => 0.0]];
      Final_S       : Matrix (1 .. Max_N, 1 .. Max_N) :=
                        [others => [others => 0.0]];
      N             : Dimension := 0;
      Sweeps        : Natural := 0;
      Rotations     : Natural := 0;
      Off_Diag_Norm : Float := 0.0;
      Stat          : Status := Ill_Started;
      Success       : Boolean := False;
   end record;

   type Example_Kind is
     (Diagonal_Known,
      Poisson_1D,
      Hilbert_Tiny,
      Symmetric_Known,
      Symmetric_Randomish);

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-10;
   Norm_Tol    : constant Float := 1.0E-14;
   Sym_Tol     : constant Float := 1.0E-5;

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

   function Mat_Mul (A, B : Matrix) return Matrix
     with Pre => A'Length (2) = B'Length (1)
            and then A'Length (1) <= Max_N
            and then B'Length (2) <= Max_N,
          Global => null;
   --  C = A B (dense).

   function Mat_Transpose (A : Matrix) return Matrix
     with Pre => A'Length (1) <= Max_N and then A'Length (2) <= Max_N,
          Global => null;

   function Is_Square (A : Matrix) return Boolean
     with Global => null;

   function Is_Symmetric
     (A : Matrix; Tol : Float := Sym_Tol) return Boolean
     with Pre => A'Length (1) = A'Length (2) and then Tol >= 0.0,
          Global => null;

   function Identity (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   function Column (A : Matrix; J : Positive) return Vector
     with Pre => J in A'Range (2), Global => null;

   procedure Set_Column
     (A : in out Matrix; J : Positive; V : Vector)
     with Pre => J in A'Range (2)
            and then V'Length = A'Length (1);

   --  Frobenius norm of strictly off-diagonal entries:
   --  sqrt(Σ_{i≠j} S_ij²). Measures departure from diagonal form.
   function Off_Diag_Norm (A : Matrix) return Float
     with Pre => A'Length (1) = A'Length (2) and then A'Length (1) >= 1,
          Global => null;

   function Trace (A : Matrix) return Float
     with Pre => A'Length (1) = A'Length (2) and then A'Length (1) >= 1,
          Global => null;

   function Frobenius_Norm (A : Matrix) return Float
     with Pre => A'Length (1) >= 1 and then A'Length (2) >= 1,
          Global => null;

   --  Max | (Vᵀ V)_ij − δ_ij | over the leading N×N block of columns.
   function Orthogonality_Residual
     (V : Matrix; N : Dimension) return Float
     with Pre => N >= 1 and then N <= Max_N, Global => null;

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

   --  Frobenius ‖A V − V Λ‖_F over leading N columns (Λ = diag(Eigs)).
   function Mat_Eigen_Residual
     (A    : Matrix;
      V    : Matrix;
      Eigs : Vector;
      N    : Dimension) return Float
     with Pre => N >= 1 and then N <= Max_N
            and then A'Length (1) = A'Length (2)
            and then A'Length (1) >= N
            and then Eigs'Length >= N,
          Global => null;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Make_Diagonal (Eigs : Vector) return Matrix
     with Pre => Eigs'Length >= 1 and then Eigs'Length <= Max_N,
          Global => null;
   --  diag(Eigs); known eigenvalues = Eigs entries.

   function Make_Symmetric_Known (Eigs : Vector) return Matrix
     with Pre => Eigs'Length >= 1 and then Eigs'Length <= Max_N,
          Global => null;
   --  Dense symmetric A = Q D Qᵀ with the same spectrum as Eigs,
   --  where Q comes from MGS of a deterministic full-rank recipe.

   function Make_Poisson_1D (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  Tridiagonal (−1, 2, −1) Dirichlet Laplacian; eigenvalues
   --  λ_k = 2 − 2 cos(k π / (N+1)), k = 1..N.

   function Make_Hilbert (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  H_ij = 1/(i+j−1). Ill-conditioned; use looser Tol for n > 4.

   function Make_Symmetric_Randomish (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  Deterministic dense SPD-ish symmetric (Float hash recipe).

   function Make_Example
     (Kind : Example_Kind; N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  Diagonal_Known      : diag(1, 2, …, N)
   --  Poisson_1D          : Make_Poisson_1D
   --  Hilbert_Tiny        : Make_Hilbert
   --  Symmetric_Known     : Make_Symmetric_Known([1..N])
   --  Symmetric_Randomish : Make_Symmetric_Randomish

   function Poisson_Eigenvalue
     (N : Dimension; K : Dim_Index) return Float
     with Pre => N >= 1 and then K <= N, Global => null;
   --  Exact λ_k for the 1-D Poisson stencil.

   ---------------------------------------------------------------------------
   -- Jacobi diagonalization
   ---------------------------------------------------------------------------

   function Diagonalize
     (S      : Matrix;
      Params : Parameters := Default_Parameters) return Result
     with Pre => S'Length (1) = S'Length (2)
            and then S'Length (1) >= 1
            and then S'Length (1) <= Max_N;
   --  Symmetric Jacobi: repeatedly apply plane rotations G(i,j,θ)
   --  so that S ← Gᵀ S G until Off_Diag_Norm ≤ Tol or Max_Sweeps.
   --  Accumulates eigenvectors V ← V G (V starts as I).
   --  Rejects nonsymmetric input (Status = Not_Symmetric).
   --  Dense method; destroys sparsity / banding.

   function Eigenpairs
     (S      : Matrix;
      Params : Parameters := Default_Parameters) return Result
     with Pre => S'Length (1) = S'Length (2)
            and then S'Length (1) >= 1
            and then S'Length (1) <= Max_N;
   --  Alias for Diagonalize.

   --  One educational Jacobi rotation on pivot (P,Q): update S and V
   --  in place. Returns False if |S_PQ| is already negligible.
   function Apply_Rotation
     (S      : in out Matrix;
      V      : in out Matrix;
      P, Q   : Dim_Index;
      N      : Dimension) return Boolean
     with Pre => N >= 2 and then N <= Max_N
            and then P < Q and then Q <= N;

end Jacobi_Eigenvalue;
