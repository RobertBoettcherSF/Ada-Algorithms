--  Rayleigh_Ritz_Method — Ada 2023 educational package for the classical
--  matrix Rayleigh–Ritz (Ritz) procedure: Rayleigh quotient, modified
--  Gram–Schmidt orthonormalization, projected eigenproblem T = Qᵀ A Q,
--  small dense symmetric Jacobi eigensolver, Ritz pairs, optional
--  generalized A x = λ B x via Cholesky on S = Qᵀ B Q, residuals, and a
--  1-D discrete Laplacian / spring-mass demo subspace.
--  Based on Wikipedia "Ritz method" / "Rayleigh–Ritz method".

pragma Ada_2022;

package Rayleigh_Ritz_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Educational dense bound (matrix problems up to Max_N × Max_N).
   Max_N : constant Positive := 32;
   --  Projected eigenproblems stay small (Jacobi is fine for k ≤ Max_K).
   Max_K : constant Positive := 8;

   subtype Dim_N is Natural range 0 .. Max_N;
   subtype Index_N is Positive range 1 .. Max_N;
   subtype Dim_K is Natural range 0 .. Max_K;
   subtype Index_K is Positive range 1 .. Max_K;

   --  Column vectors of length N (1-based).
   type Vector is array (Index_N range <>) of Real;

   --  Dense matrices stored as 1-based 2-D arrays: A (I, J).
   type Matrix is array (Index_N range <>, Index_N range <>) of Real;

   --  Small projected matrices / eigenvector bases (k × k or n × k).
   type Small_Matrix is array (Index_K range <>, Index_K range <>) of Real;
   type Small_Vector is array (Index_K range <>) of Real;

   --  Tall thin bases: rows 1 .. N, columns 1 .. K.
   type Basis is array (Index_N range <>, Index_K range <>) of Real;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;
   Rank_Deficient    : exception;
   Degenerate        : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;
   Jacobi_Tol  : constant Real := 1.0E-14;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Dot (X, Y : Vector) return Real
     with Pre => X'First = Y'First and then X'Last = Y'Last, Global => null;

   function Norm (X : Vector) return Non_Negative
     with Global => null;

   function Norm2 (X : Vector) return Non_Negative
     with Global => null;
   --  Squared Euclidean norm (avoids an extra sqrt).

   procedure Scale (X : in out Vector; Alpha : Real)
     with Global => null;

   procedure Axpy (Y : in out Vector; Alpha : Real; X : Vector)
     with Pre => Y'First = X'First and then Y'Last = X'Last, Global => null;
   --  Y := Y + Alpha * X.

   function Mat_Vec (A : Matrix; X : Vector) return Vector
     with Pre => A'First (1) = X'First
                 and then A'Last (1) = X'Last
                 and then A'First (2) = X'First
                 and then A'Last (2) = X'Last,
          Global => null;
   --  y = A x for square A matching X's length.

   function Residual_Norm (A : Matrix; X : Vector; Theta : Real)
     return Non_Negative
     with Pre => A'First (1) = X'First
                 and then A'Last (1) = X'Last
                 and then A'First (2) = X'First
                 and then A'Last (2) = X'Last,
          Global => null;
   --  ||A x − θ x||₂.

   ---------------------------------------------------------------------------
   -- Identity / fill helpers
   ---------------------------------------------------------------------------

   function Zero_Matrix (N : Dim_N) return Matrix
     with Pre => N >= 1, Global => null;

   function Identity (N : Dim_N) return Matrix
     with Pre => N >= 1, Global => null;

   function Column (Q : Basis; Col : Index_K) return Vector
     with Pre => Col in Q'Range (2), Global => null;

   procedure Set_Column (Q : in out Basis; Col : Index_K; V : Vector)
     with Pre => Col in Q'Range (2)
                 and then V'First = Q'First (1)
                 and then V'Last = Q'Last (1),
          Global => null;

   ---------------------------------------------------------------------------
   -- Rayleigh quotient
   ---------------------------------------------------------------------------

   function Rayleigh_Quotient (A : Matrix; X : Vector) return Real
     with Pre => A'First (1) = X'First
                 and then A'Last (1) = X'Last
                 and then A'First (2) = X'First
                 and then A'Last (2) = X'Last,
          Global => null;
   --  R(A, x) = (xᵀ A x) / (xᵀ x). Raises Degenerate if ||x|| = 0.

   ---------------------------------------------------------------------------
   -- Orthonormalization (modified Gram–Schmidt)
   ---------------------------------------------------------------------------

   procedure Orthonormalize
     (Q          : in out Basis;
      Rank       : out Dim_K;
      Tol        : Real := Epsilon_Tol;
      Raise_Rank : Boolean := False)
     with Pre => Q'Length (1) >= 1 and then Q'Length (2) >= 1
                 and then Tol >= 0.0,
          Global => null;
   --  Modified Gram–Schmidt on columns of Q. On exit Rank is the number of
   --  retained orthonormal columns (leading Rank columns of Q). If
   --  Raise_Rank and a column is dropped, raises Rank_Deficient.

   function Is_Orthonormal
     (Q   : Basis;
      K   : Dim_K;
      Tol : Real := 1.0E-8) return Boolean
     with Pre => K <= Q'Length (2) and then Tol >= 0.0, Global => null;
   --  Check Q(:, 1 .. K)ᵀ Q(:, 1 .. K) ≈ I.

   ---------------------------------------------------------------------------
   -- Projection T = Qᵀ A Q
   ---------------------------------------------------------------------------

   function Project_QtAQ
     (A : Matrix;
      Q : Basis;
      K : Dim_K) return Small_Matrix
     with Pre => K >= 1
                 and then K <= Q'Length (2)
                 and then A'First (1) = Q'First (1)
                 and then A'Last (1) = Q'Last (1)
                 and then A'First (2) = Q'First (1)
                 and then A'Last (2) = Q'Last (1),
          Global => null;

   function Project_QtBQ
     (B : Matrix;
      Q : Basis;
      K : Dim_K) return Small_Matrix
     with Pre => K >= 1
                 and then K <= Q'Length (2)
                 and then B'First (1) = Q'First (1)
                 and then B'Last (1) = Q'Last (1)
                 and then B'First (2) = Q'First (1)
                 and then B'Last (2) = Q'Last (1),
          Global => null;
   --  Same layout helper for mass / SPD matrices in the generalized problem.

   ---------------------------------------------------------------------------
   -- Small dense symmetric eigensolver (Jacobi)
   ---------------------------------------------------------------------------

   procedure Jacobi_Symmetric
     (T         : in out Small_Matrix;
      Y         : out Small_Matrix;
      Eigenvals : out Small_Vector;
      K         : Dim_K;
      Tol       : Real := Jacobi_Tol)
     with Pre => K >= 1
                 and then K <= T'Length (1)
                 and then K <= T'Length (2)
                 and then K <= Y'Length (1)
                 and then K <= Y'Length (2)
                 and then K <= Eigenvals'Length
                 and then Tol > 0.0,
          Global => null;
   --  Symmetric Jacobi eigenvalue algorithm on the leading K × K block of T.
   --  Overwrites T with (approx.) diagonal; Y holds orthonormal eigenvectors;
   --  Eigenvals (1 .. K) are eigenvalues sorted ascending.

   procedure Eigen_2x2
     (A11, A12, A22 : Real;
      Lam1, Lam2    : out Real;
      V1x, V1y      : out Real;
      V2x, V2y      : out Real)
     with Global => null;
   --  Analytic 2 × 2 symmetric eigenpairs; Lam1 ≤ Lam2; columns orthonormal.

   ---------------------------------------------------------------------------
   -- Standard Rayleigh–Ritz extraction
   ---------------------------------------------------------------------------

   procedure Ritz_Extract
     (A         : Matrix;
      Q         : in out Basis;
      K         : in out Dim_K;
      Ritz_Vals : out Small_Vector;
      Ritz_Vecs : out Basis;
      Tol       : Real := Epsilon_Tol)
     with Pre => K >= 1
                 and then K <= Q'Length (2)
                 and then K <= Ritz_Vals'Length
                 and then Ritz_Vecs'Length (1) = Q'Length (1)
                 and then Ritz_Vecs'Length (2) >= K
                 and then A'First (1) = Q'First (1)
                 and then A'Last (1) = Q'Last (1)
                 and then A'First (2) = Q'First (1)
                 and then A'Last (2) = Q'Last (1),
          Global => null;
   --  Orthonormalize Q (updates K to retained rank), form T = Qᵀ A Q,
   --  solve T Y = Θ Y, set Ritz_Vals = Θ and Ritz_Vecs = Q Y.
   --  For K = 1 this reduces to the Rayleigh quotient on the single column.
   --  Raises Rank_Deficient if no column survives orthonormalization.

   ---------------------------------------------------------------------------
   -- Generalized Rayleigh–Ritz: A x = λ B x (B SPD)
   ---------------------------------------------------------------------------

   procedure Ritz_Extract_Generalized
     (A         : Matrix;
      B         : Matrix;
      Q         : in out Basis;
      K         : in out Dim_K;
      Ritz_Vals : out Small_Vector;
      Ritz_Vecs : out Basis;
      Tol       : Real := Epsilon_Tol)
     with Pre => K >= 1
                 and then K <= Q'Length (2)
                 and then K <= Ritz_Vals'Length
                 and then Ritz_Vecs'Length (1) = Q'Length (1)
                 and then Ritz_Vecs'Length (2) >= K
                 and then A'First (1) = Q'First (1)
                 and then A'Last (1) = Q'Last (1)
                 and then B'First (1) = Q'First (1)
                 and then B'Last (1) = Q'Last (1),
          Global => null;
   --  T = Qᵀ A Q, S = Qᵀ B Q; Cholesky S = L Lᵀ; solve standard eigenproblem
   --  on L⁻¹ T L⁻ᵀ; map eigenvectors back. Raises Degenerate if S not SPD.

   function Identity_Basis (N : Dim_N; K : Dim_K) return Basis
     with Pre => N >= 1 and then K >= 1 and then K <= N, Global => null;
   --  First K columns of the N × N identity (embedded as an n × k basis).

   ---------------------------------------------------------------------------
   -- Discrete 1-D Laplacian / spring-mass helpers (demo + tests)
   ---------------------------------------------------------------------------

   function Discrete_Laplacian (N : Dim_N) return Matrix
     with Pre => N >= 2, Global => null;
   --  Tridiagonal (−1, 2, −1) Dirichlet Laplacian on N interior points.
   --  Exact eigenvalues: λ_j = 2 − 2 cos(π j / (N + 1)), j = 1 .. N.

   function Laplacian_Exact_Eigenvalue (N : Dim_N; J : Index_N) return Real
     with Pre => N >= 2 and then J <= N, Global => null;

   function Laplacian_Exact_Eigenvector (N : Dim_N; J : Index_N) return Vector
     with Pre => N >= 2 and then J <= N, Global => null;
   --  sin(π j i / (N + 1)), i = 1 .. N (unnormalized).

   function Fourier_Trial_Basis (N : Dim_N; K : Dim_K) return Basis
     with Pre => N >= 2 and then K >= 1 and then K <= N, Global => null;
   --  First K discrete sine modes (exact eigenbasis columns) — useful as a
   --  rich trial subspace; after RR on full space recovers exact spectrum.

   function Polynomial_Trial_Basis (N : Dim_N; K : Dim_K) return Basis
     with Pre => N >= 2 and then K >= 1 and then K <= N, Global => null;
   --  Columns t^{p} on the grid t_i = i/(N+1), p = 0 .. K-1 (then MGS).

end Rayleigh_Ritz_Method;
