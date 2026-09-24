--  Cannon's algorithm — Ada 2023 educational package for Wikipedia
--  "Cannon's algorithm": distributed / 2D-mesh matrix multiplication
--  (Lynn Elliot Cannon, 1969). Sequential single-threaded simulation of
--  the systolic P×P PE mesh: initial circular alignment of A (left by
--  row) and B (up by column), then P steps of local multiply-accumulate
--  plus neighbour shifts. Storage/shifts are kept explicit for teaching.
--  Cap n ≤ 32; educational Float; Multiply_Classical as residual oracle.
--  Primary source:
--  https://en.wikipedia.org/wiki/Cannon's_algorithm
--  Siblings (README links only — no package deps):
--  Ada-Strassen, Ada-Freivalds, Ada-Coppersmith-Winograd (upcoming),
--  Matrix Multiplication survey (upcoming)

pragma Ada_2022;

package Cannons_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   Max_N : constant := 32;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   type Matrix is array (Positive range <>, Positive range <>) of Float;

   --  Grid_P = 0 in Multiply_Cannon means default P = n (element-per-PE).
   Default_Grid_P : constant Natural := 0;

   type Status is (Ok, Dimension_Error, Ill_Started);

   --  Product result: leading N×N of C is meaningful when Success.
   type Multiply_Result is record
      C           : Matrix (1 .. Max_N, 1 .. Max_N) :=
                      [others => [others => 0.0]];
      N           : Dimension := 0;
      Stat        : Status := Ill_Started;
      Success     : Boolean := False;
      Grid_P      : Natural := 0;  -- processors on a side (used for Cannon)
      Block_Size  : Natural := 0;  -- n / Grid_P
      Shift_Count : Natural := 0;  -- systolic steps (= Grid_P for Cannon)
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-5;
   --  Educational Float residual tolerance (Cannon ≡ classical).

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

   function Divides (P, N : Natural) return Boolean
     with Global => null;
   --  True iff P > 0 and N mod P = 0.

   function Is_Valid_Grid (N, P : Natural) return Boolean
     with Global => null;
   --  True iff 1 ≤ P ≤ N ≤ Max_N and N mod P = 0.

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
   --  Grid_P / Block_Size / Shift_Count remain 0.

   ---------------------------------------------------------------------------
   -- Cannon multiply (sequential simulation of 2D-mesh systolic MM)
   ---------------------------------------------------------------------------

   function Multiply_Cannon
     (A      : Matrix;
      B      : Matrix;
      Grid_P : Natural := Default_Grid_P) return Multiply_Result
     with Pre =>
       Is_Square (A)
       and then Is_Square (B)
       and then A'Length (1) = B'Length (1),
          Global => null;
   --  Educational sequential simulation of Cannon (1969) on a P×P PE mesh:
   --    1. Partition A,B into P×P blocks of size BS×BS (BS = n/P).
   --    2. Initial alignment: circular-shift row i of A left by i blocks;
   --       circular-shift column j of B up by j blocks.
   --    3. For s = 1 .. P: C_ij += A_ij * B_ij (block GEMM); then shift A
   --       left by 1 block and B up by 1 block (toroidal).
   --  Grid_P = 0 defaults to P = n (element-per-PE, BS = 1).
   --  Requires 1 ≤ n ≤ Max_N and Is_Valid_Grid (n, P); else Dimension_Error.
   --  Shift_Count = P on success. Inputs are not modified.

   ---------------------------------------------------------------------------
   -- Convenience: extract leading N×N from a Multiply_Result
   ---------------------------------------------------------------------------

   function Product_Matrix (R : Multiply_Result) return Matrix
     with Pre => R.Success and then R.N >= 1, Global => null;

end Cannons_Algorithm;
