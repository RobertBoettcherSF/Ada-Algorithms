--  QR_Algorithm — Ada 2023 educational package for Wikipedia
--  "QR algorithm": unshifted QR iteration for eigenvalues of real
--  dense matrices (prefer symmetric / SPD test cases). Cap n ≤ 16;
--  educational Float; QR via Modified Gram–Schmidt.
--  Primary source:
--  https://en.wikipedia.org/wiki/QR_algorithm
--  Siblings: Ada-Gram-Schmidt, Ada-Rayleigh-Quotient-Iteration;
--  upcoming Power / Lanczos / Arnoldi / Jacobi / Inverse /
--  Eigenvalue survey (README links).

pragma Ada_2022;

package QR_Algorithm
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

   --  Tol      : stop when Off_Diag_Norm(A_k) ≤ Tol
   --  Max_Iter : hard iteration budget (default 200)
   --  Use_Shift: educational flag — Iterate remains unshifted (reliable
   --             dense MGS path); when True, still evaluates Wilkinson_Shift
   --             each step as a sketch. Apply shifts via QR_Step (A, σ).
   --  Accumulate_Q: if True, form V ≈ product of Q_k (eigenvector sketch)
   type Parameters is record
      Tol          : Float   := 1.0E-6;
      Max_Iter     : Natural := 200;
      Use_Shift    : Boolean := False;
      Accumulate_Q : Boolean := False;
   end record;

   Default_Parameters : constant Parameters :=
     (Tol => 1.0E-6, Max_Iter => 200,
      Use_Shift => False, Accumulate_Q => False);

   type Status is
     (Converged,
      Iteration_Limit,
      Ill_Started,
      Dimension_Error,
      Rank_Issue);

   --  Eigenvalues from the diagonal of the final iterate; optional V
   --  accumulates Q-products when Params.Accumulate_Q is True.
   type Result is record
      Eigenvalues : Vector (1 .. Max_N) := [others => 0.0];
      V           : Matrix (1 .. Max_N, 1 .. Max_N) :=
                      [others => [others => 0.0]];
      Final_A     : Matrix (1 .. Max_N, 1 .. Max_N) :=
                      [others => [others => 0.0]];
      N           : Dimension := 0;
      Iterations  : Natural := 0;
      Off_Diag    : Float := 0.0;
      Stat        : Status := Ill_Started;
      Success     : Boolean := False;
      Has_V       : Boolean := False;
   end record;

   type QR_Status is (Ok, Rank_Deficient, Dimension_Error, Ill_Started);

   type QR_Result is record
      Q       : Matrix (1 .. Max_N, 1 .. Max_N) :=
                  [others => [others => 0.0]];
      R       : Matrix (1 .. Max_N, 1 .. Max_N) :=
                  [others => [others => 0.0]];
      N       : Dimension := 0;
      Stat    : QR_Status := Ill_Started;
      Success : Boolean := False;
   end record;

   type Example_Kind is
     (Diagonal_Known, Poisson_1D, Hilbert_Tiny, Symmetric_Known,
      Symmetric_Randomish);

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-10;
   Rank_Tol    : constant Float := 1.0E-10;
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

   function Mat_Mul (A, B : Matrix) return Matrix
     with Pre => A'Length (2) = B'Length (1)
            and then A'Length (1) <= Max_N
            and then B'Length (2) <= Max_N,
          Global => null;
   --  C = A B (dense, leading blocks sized by A rows × B cols).

   function Mat_Transpose (A : Matrix) return Matrix
     with Pre => A'Length (1) <= Max_N and then A'Length (2) <= Max_N,
          Global => null;

   function Is_Square (A : Matrix) return Boolean
     with Global => null;

   function Is_Symmetric
     (A : Matrix; Tol : Float := 1.0E-6) return Boolean
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
   --  sqrt(Σ_{i≠j} A_ij²). For symmetric matrices this measures
   --  departure from diagonal form under QR iteration.
   function Off_Diag_Norm (A : Matrix) return Float
     with Pre => A'Length (1) = A'Length (2) and then A'Length (1) >= 1,
          Global => null;

   function Trace (A : Matrix) return Float
     with Pre => A'Length (1) = A'Length (2) and then A'Length (1) >= 1,
          Global => null;

   function Frobenius_Norm (A : Matrix) return Float
     with Pre => A'Length (1) >= 1 and then A'Length (2) >= 1,
          Global => null;

   --  Max | (Qᵀ Q)_ij − δ_ij | over the leading N×N block.
   function Orthogonality_Residual
     (Q : Matrix; N : Dimension) return Float
     with Pre => N >= 1 and then N <= Max_N, Global => null;

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
   --  H_ij = 1/(i+j−1).

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
   -- QR factorization (Modified Gram–Schmidt)
   ---------------------------------------------------------------------------

   function QR_Factor (A : Matrix) return QR_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N;
   --  Thin square QR via Modified Gram–Schmidt: A = Q R with Q
   --  orthonormal and R upper triangular. Rank_Deficient / Rank_Issue
   --  when a column residual is near zero.

   ---------------------------------------------------------------------------
   -- QR iteration (eigenvalues)
   ---------------------------------------------------------------------------

   function Iterate
     (A      : Matrix;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N;
   --  Unshifted (or optional Wilkinson-shifted) QR iteration:
   --  A_{k+1} = R_k Q_k until Off_Diag_Norm ≤ Tol or Max_Iter.
   --  Eigenvalues read from the diagonal of the final A_k.

   function Eigenvalues
     (A      : Matrix;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N;
   --  Alias for Iterate.

   --  One educational QR step: factor A = Q R, return R Q (and Q, R).
   type Step_Result is record
      Next    : Matrix (1 .. Max_N, 1 .. Max_N) :=
                  [others => [others => 0.0]];
      Q       : Matrix (1 .. Max_N, 1 .. Max_N) :=
                  [others => [others => 0.0]];
      R       : Matrix (1 .. Max_N, 1 .. Max_N) :=
                  [others => [others => 0.0]];
      N       : Dimension := 0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   function QR_Step (A : Matrix; Shift : Float := 0.0) return Step_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N;
   --  Explicit shifted step: factor (A − σ I) = Q R, return
   --  A' = R Q + σ I. Shift = 0 is the classical unshifted step.

   function Wilkinson_Shift (A : Matrix) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 2
            and then A'Length (1) <= Max_N,
          Global => null;
   --  Educational Wilkinson shift from the trailing 2×2 block:
   --  eigenvalue of [[a,b],[b,c]] closer to c.

end QR_Algorithm;
