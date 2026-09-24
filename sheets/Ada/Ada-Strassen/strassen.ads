--  Strassen — Ada 2023 educational package for Wikipedia "Strassen algorithm":
--  fast square matrix multiplication via the classic 7-product recursive
--  block scheme (Volker Strassen, 1969). Complexity O(n^{log_2 7}) ≈ O(n^{2.807})
--  versus classical O(n^3). Cap n ≤ 32; educational Float; pad-and-trim for
--  non-power-of-2 sizes. Also provides Multiply_Classical for comparison /
--  residual checks, and optional scalar-multiply / recursion-depth counters.
--  Primary source:
--  https://en.wikipedia.org/wiki/Strassen_algorithm
--  Siblings (README links only — no package deps):
--  Ada-Coppersmith-Winograd (upcoming), Ada-Freivalds (upcoming),
--  Ada-System-of-Linear-Equations

pragma Ada_2022;

package Strassen
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   Max_N : constant := 32;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   type Matrix is array (Positive range <>, Positive range <>) of Float;

   --  Leaf threshold for recursion: when block size ≤ Leaf, use classical
   --  multiply. Leaf = 1 is pure Strassen (educational).
   Default_Leaf : constant Positive := 1;

   type Status is (Ok, Dimension_Error, Ill_Started);

   --  Product result: leading N×N of C is meaningful when Success.
   type Multiply_Result is record
      C                 : Matrix (1 .. Max_N, 1 .. Max_N) :=
                            [others => [others => 0.0]];
      N                 : Dimension := 0;
      Stat              : Status := Ill_Started;
      Success           : Boolean := False;
      Scalar_Multiplies : Natural := 0;
      Recursion_Depth   : Natural := 0;
      Padded_N          : Dimension := 0;  -- working power-of-2 size (0 if unused)
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-5;
   --  Slightly looser than GE siblings: Strassen accumulates more Float
   --  roundoff than classical multiply on the same data.

   ---------------------------------------------------------------------------
   -- Numeric / structural helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Mat_Near
     (A, B : Matrix; Tol : Float := Epsilon_Tol) return Boolean
     with Pre =>
       A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2)
       and then Tol >= 0.0,
          Global => null;

   function Norm_Frobenius (A : Matrix) return Float
     with Global => null;
   --  ‖A‖_F = sqrt(Σ_{i,j} A_{ij}^2)

   function Diff_Frobenius (A, B : Matrix) return Float
     with Pre =>
       A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2),
          Global => null;
   --  ‖A − B‖_F

   function Is_Square (A : Matrix) return Boolean
     with Global => null;

   function Is_Power_Of_Two (N : Natural) return Boolean
     with Global => null;

   function Next_Power_Of_Two (N : Natural) return Natural
     with Pre => N <= Max_N, Global => null;
   --  Smallest 2^k ≥ N (for N = 0 returns 0). Requires result ≤ Max_N.

   function Mat_Add (A, B : Matrix) return Matrix
     with Pre =>
       A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2),
          Global => null;

   function Mat_Sub (A, B : Matrix) return Matrix
     with Pre =>
       A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2),
          Global => null;

   function Mat_Scale (A : Matrix; S : Float) return Matrix
     with Global => null;

   ---------------------------------------------------------------------------
   -- Padding / trimming (educational pad-and-trim)
   ---------------------------------------------------------------------------

   function Pad_To_Power_Of_Two (A : Matrix) return Matrix
     with Pre =>
       Is_Square (A)
       and then A'Length (1) <= Max_N
       and then A'Length (1) >= 1,
          Global => null;
   --  Zero-pad leading N×N into next power-of-2 square (or copy if already).

   function Trim (A : Matrix; N : Dimension) return Matrix
     with Pre =>
       Is_Square (A)
       and then N >= 1
       and then N <= A'Length (1),
          Global => null;
   --  Extract leading N×N block.

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Zeros (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   function Ones (N : Dimension; Value : Float := 1.0) return Matrix
     with Pre => N >= 1, Global => null;

   function Identity (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   function Sequential_Fill (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  A(i,j) = Float ((i - 1) * N + j)  (1-based row-major)

   function Deterministic (N : Dimension; Seed : Natural := 1) return Matrix
     with Pre => N >= 1, Global => null;
   --  Pseudo-random-ish but fully deterministic in [0,1):
   --  A(i,j) = frac((Seed + 17*i + 31*j) * 0.6180339887)

   function Make_Hilbert (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  H_{ij} = 1 / (i + j - 1) — ill-conditioned teaching matrix

   ---------------------------------------------------------------------------
   -- Classical multiply (baseline / residual oracle)
   ---------------------------------------------------------------------------

   function Multiply_Classical (A, B : Matrix) return Multiply_Result
     with Pre =>
       Is_Square (A)
       and then Is_Square (B)
       and then A'Length (1) = B'Length (1),
          Global => null;
   --  Standard O(n^3) product. Requires 1 ≤ n ≤ Max_N; else Dimension_Error.
   --  Scalar_Multiplies = n^3; Recursion_Depth = 0.

   ---------------------------------------------------------------------------
   -- Strassen multiply (7-product recursion + pad-and-trim)
   ---------------------------------------------------------------------------

   function Multiply_Strassen
     (A    : Matrix;
      B    : Matrix;
      Leaf : Positive := Default_Leaf) return Multiply_Result
     with Pre =>
       Is_Square (A)
       and then Is_Square (B)
       and then A'Length (1) = B'Length (1)
       and then Leaf >= 1,
          Global => null;
   --  Pad both factors to next power of 2 (if needed), run Strassen
   --  recursion with classical base case when block size ≤ Leaf, then
   --  trim the product back to n×n. Requires 1 ≤ n ≤ Max_N.

   ---------------------------------------------------------------------------
   -- Convenience: extract leading N×N from a Multiply_Result
   ---------------------------------------------------------------------------

   function Product_Matrix (R : Multiply_Result) return Matrix
     with Pre => R.Success and then R.N >= 1, Global => null;

end Strassen;
