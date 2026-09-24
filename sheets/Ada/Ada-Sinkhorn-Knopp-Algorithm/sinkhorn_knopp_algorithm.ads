--  Sinkhorn_Knopp_Algorithm — Ada 2023 educational package for Wikipedia
--  Sinkhorn's theorem / Sinkhorn–Knopp algorithm: alternate row and column
--  scaling of a nonnegative matrix to approach a doubly stochastic matrix
--  (or a matrix with prescribed positive marginals). Result has the form
--  D1 A D2 with positive diagonal D1, D2. Cap n ≤ 32; Long_Float.
--  Primary sources:
--  https://en.wikipedia.org/wiki/Sinkhorn%27s_theorem
--  https://www.emergentmind.com/topics/sinkhorn-knopp-algorithm
--  Sibling (README only): Ada-Birkhoff-von-Neumann. Series at
--  https://github.com/RobertBoettcherSF/

pragma Ada_2022;

package Sinkhorn_Knopp_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Long_Float)
   ---------------------------------------------------------------------------

   Max_N : constant := 32;
   --  Classroom demos; dense n×n Sinkhorn is fine at this size.

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   type Real is new Long_Float;
   type Matrix is array (Positive range <>, Positive range <>) of Real;
   type Vector is array (Positive range <>) of Real;

   --  Packed result of Solve (scaled / scales stored in 1 .. Rows/Cols).
   type Sinkhorn_Result is record
      Scaled     : Matrix (1 .. Max_N, 1 .. Max_N) :=
        [others => [others => 0.0]];
      Row_Scale  : Vector (1 .. Max_N) := [others => 1.0];
      Col_Scale  : Vector (1 .. Max_N) := [others => 1.0];
      Rows       : Dimension := 0;
      Cols       : Dimension := 0;
      Iterations : Natural := 0;
      Residual   : Real := 0.0;
      Converged  : Boolean := False;
   end record;

   Invalid_Argument : exception;

   Zero_Tol         : constant Real := 1.0E-12;
   --  Entries |a| ≤ Zero_Tol treated as zero for nonnegativity / support.
   Default_Eps      : constant Real := 1.0E-10;
   --  Stop when max |rowSum_i − target_i| and |colSum_j − target_j| ≤ Eps.
   Default_Max_Iter : constant Natural := 10_000;
   Sum_Tol          : constant Real := 1.0E-8;
   --  Default tolerance for Is_Nearly_Doubly_Stochastic.

   ---------------------------------------------------------------------------
   -- Predicates / numeric helpers
   ---------------------------------------------------------------------------

   function Is_Square (A : Matrix) return Boolean
     with Global => null;
   --  True iff A'Length (1) = A'Length (2).

   function Near (X, Y : Real; Tol : Real := Zero_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Is_Nonnegative (A : Matrix; Tol : Real := Zero_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  Every entry ≥ −Tol (tiny negatives from float noise allowed).

   function Is_Strictly_Positive
     (A : Matrix; Tol : Real := Zero_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  Every entry > Tol (Sinkhorn theorem hypothesis).

   function Has_Positive_Row_Sums
     (A : Matrix; Tol : Real := Zero_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Has_Positive_Col_Sums
     (A : Matrix; Tol : Real := Zero_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Row_Sum (A : Matrix; I : Positive) return Real
     with Pre => I in A'Range (1), Global => null;

   function Col_Sum (A : Matrix; J : Positive) return Real
     with Pre => J in A'Range (2), Global => null;

   function Row_Sums (A : Matrix) return Vector
     with Global => null;
   --  Length = A'Length (1); result'First = 1.

   function Col_Sums (A : Matrix) return Vector
     with Global => null;
   --  Length = A'Length (2); result'First = 1.

   function Max_Marginal_Residual
     (A           : Matrix;
      Row_Targets : Vector;
      Col_Targets : Vector) return Real
     with Pre => Row_Targets'Length = A'Length (1)
            and then Col_Targets'Length = A'Length (2),
          Global => null;
   --  max_i |rowSum_i − r_i| and max_j |colSum_j − c_j|.

   function Is_Nearly_Doubly_Stochastic
     (A : Matrix; Tol : Real := Sum_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  Square, nonnegative, every row and column sums to ≈ 1 within Tol.
   --  Empty 0×0 treated as nearly DS (vacuous).

   function Matrices_Near
     (A, B : Matrix; Tol : Real := Sum_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Frobenius_Distance (A, B : Matrix) return Real
     with Pre => A'Length (1) = B'Length (1)
            and then A'Length (2) = B'Length (2),
          Global => null;

   function Ones_Vector (N : Dimension; Value : Real := 1.0) return Vector
     with Pre => N <= Max_N, Global => null;
   --  N = 0 yields empty vector.

   ---------------------------------------------------------------------------
   -- Constructors / toy matrices
   ---------------------------------------------------------------------------

   function Zero_Matrix (N : Dimension) return Matrix
     with Pre => N <= Max_N, Global => null;
   --  N×N zeros; N = 0 yields empty matrix.

   function Ones_Matrix (N : Dimension) return Matrix
     with Pre => N >= 1 and then N <= Max_N, Global => null;
   --  All entries 1 (already positive; Sinkhorn → uniform 1/N).

   function Identity (N : Dimension) return Matrix
     with Pre => N >= 1 and then N <= Max_N, Global => null;

   function Uniform (N : Dimension) return Matrix
     with Pre => N >= 1 and then N <= Max_N, Global => null;
   --  All entries 1/N (already doubly stochastic).

   --  Deterministic “random-ish” strictly positive matrix for demos:
   --  A_ij = 1 + ((i * 17 + j * 31) mod 97) / 100.
   function Positive_Toy (N : Dimension) return Matrix
     with Pre => N >= 1 and then N <= Max_N, Global => null;

   --  Hilbert-ish: A_ij = 1 / (i + j − 1) (positive; small classroom n).
   function Hilbert_Like (N : Dimension) return Matrix
     with Pre => N >= 1 and then N <= Max_N, Global => null;

   --  Transportation / Gibbs kernel: A_ij = exp(−Cost_ij / Eps) with
   --  Cost_ij = (i − j)^2 (positive; entropic OT flavour).
   function Transportation_Kernel
     (N : Dimension; Eps : Real := 1.0) return Matrix
     with Pre => N >= 1 and then N <= Max_N and then Eps > 0.0,
          Global => null;

   function Example_2x2 return Matrix
     with Global => null;
   --  [[1, 2], [3, 4]]

   function Example_3x3 return Matrix
     with Global => null;
   --  [[1, 2, 3], [4, 5, 6], [7, 8, 9]] (strictly positive).

   function Scale (A : Matrix; S : Real) return Matrix
     with Global => null;

   function Add (A, B : Matrix) return Matrix
     with Pre => A'Length (1) = B'Length (1)
            and then A'Length (2) = B'Length (2),
          Global => null;

   ---------------------------------------------------------------------------
   -- Row / column normalization (one Sinkhorn half-step)
   ---------------------------------------------------------------------------

   function Normalize_Rows (A : Matrix) return Matrix
     with Global => null;
   --  Each row scaled to sum to 1. Raises Invalid_Argument if empty,
   --  not nonnegative, or any row sum ≤ Zero_Tol.

   function Normalize_Rows (A : Matrix; Targets : Vector) return Matrix
     with Pre => Targets'Length = A'Length (1), Global => null;
   --  Each row i scaled so sum = Targets (corresponding index).
   --  Targets must be > Zero_Tol. Raises Invalid_Argument on empty,
   --  negatives, zero row, or nonpositive target.

   function Normalize_Columns (A : Matrix) return Matrix
     with Global => null;
   --  Each column scaled to sum to 1.

   function Normalize_Columns (A : Matrix; Targets : Vector) return Matrix
     with Pre => Targets'Length = A'Length (2), Global => null;

   ---------------------------------------------------------------------------
   -- Sinkhorn–Knopp iteration
   ---------------------------------------------------------------------------

   function Iterate
     (A : Matrix; Steps : Natural) return Matrix
     with Global => null;
   --  Apply Steps pairs of (Normalize_Rows, Normalize_Columns) toward
   --  all-ones marginals. Steps = 0 returns a copy after validating
   --  nonnegativity / nonempty. Raises Invalid_Argument if empty, not
   --  nonnegative, or a zero row/column appears.

   function Iterate
     (A           : Matrix;
      Steps       : Natural;
      Row_Targets : Vector;
      Col_Targets : Vector) return Matrix
     with Pre => Row_Targets'Length = A'Length (1)
            and then Col_Targets'Length = A'Length (2),
          Global => null;
   --  Same with prescribed positive marginals.

   --  Full solve toward doubly stochastic (all-ones marginals).
   function Solve
     (A        : Matrix;
      Epsilon  : Real := Default_Eps;
      Max_Iter : Natural := Default_Max_Iter) return Sinkhorn_Result
     with Pre => Epsilon > 0.0;
   --  Alternating row/column scaling until residual ≤ Epsilon or
   --  Max_Iter pairs exhausted. Fills Scaled, Row_Scale, Col_Scale so
   --  Scaled ≈ diag(Row_Scale) * A * diag(Col_Scale) on 1 .. Rows/Cols.
   --  Raises Invalid_Argument if empty, not square, not nonnegative,
   --  dimension > Max_N, or a zero row/column breaks scaling.

   --  Full solve with prescribed positive marginals (rectangular OK).
   function Solve
     (A           : Matrix;
      Row_Targets : Vector;
      Col_Targets : Vector;
      Epsilon     : Real := Default_Eps;
      Max_Iter    : Natural := Default_Max_Iter) return Sinkhorn_Result
     with Pre => Row_Targets'Length = A'Length (1)
            and then Col_Targets'Length = A'Length (2)
            and then Epsilon > 0.0;
   --  Raises Invalid_Argument if empty, not nonnegative, dim > Max_N,
   --  nonpositive targets, or zero row/column.

   --  Extract the Rows×Cols scaled block as an unconstrained Matrix.
   function Scaled_Matrix (R : Sinkhorn_Result) return Matrix
     with Pre => R.Rows <= Max_N and then R.Cols <= Max_N, Global => null;

end Sinkhorn_Knopp_Algorithm;
