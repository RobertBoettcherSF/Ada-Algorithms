--  Smawk — Ada 2023 educational package for the SMAWK algorithm:
--  row minima of an implicitly defined totally monotone matrix.
--  Caps n, m ≤ 64. Primary source:
--  https://en.wikipedia.org/wiki/SMAWK_algorithm
--  Siblings: Ada-Dynamic-Programming / Ada-Hungarian-Method /
--  Ada-Chain-Matrix-Multiplication (README links).

pragma Ada_2022;

package Smawk
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / domain types
   ---------------------------------------------------------------------------

   Max_N : constant := 64;  -- rows
   Max_M : constant := 64;  -- columns

   subtype Dim_N is Natural  range 0 .. Max_N;
   subtype Dim_M is Natural  range 0 .. Max_M;
   subtype Row_Index is Positive range 1 .. Max_N;
   subtype Col_Index is Positive range 1 .. Max_M;

   type Dense_Matrix is
     array (Positive range <>, Positive range <>) of Float;

   --  Argmin column index for each row (1-based). Length = number of rows.
   type Argmin_Array is array (Positive range <>) of Col_Index;

   --  Implicit matrix: evaluate entry A(i, j) in O(1).
   type Matrix_Lookup is
     access function (Row, Col : Positive) return Float;

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Dense helpers
   ---------------------------------------------------------------------------

   function Zero_Dense (Rows, Cols : Natural) return Dense_Matrix
     with Pre => Rows <= Max_N and then Cols <= Max_M, Global => null;

   function Get
     (A : Dense_Matrix; Row, Col : Positive) return Float
     with Pre => Row in A'Range (1) and then Col in A'Range (2),
          Global => null;

   procedure Set
     (A : in out Dense_Matrix; Row, Col : Positive; Value : Float)
     with Pre => Row in A'Range (1) and then Col in A'Range (2),
          Global => null;

   function Near (X, Y : Float; Tol : Float := 1.0E-5) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Totally monotone / Monge checkers (small dense only)
   ---------------------------------------------------------------------------

   --  For minima with leftmost-tie policy: for all i < i', j < j',
   --  A(i,j) > A(i,j') implies A(i',j) >= A(i',j'). Equivalent to: no 2×2
   --  submatrix whose row minima sit at the top-right and bottom-left.
   function Is_Totally_Monotone (A : Dense_Matrix) return Boolean
     with Pre => A'Length (1) <= Max_N and then A'Length (2) <= Max_M,
          Global => null;

   --  Monge: A(i,j) + A(i',j') <= A(i,j') + A(i',j) for i < i', j < j'.
   --  Every Monge matrix is totally monotone (for row minima).
   function Is_Monge (A : Dense_Matrix) return Boolean
     with Pre => A'Length (1) <= Max_N and then A'Length (2) <= Max_M,
          Global => null;

   --  Weaker: argmin columns of consecutive rows are nondecreasing
   --  (leftmost ties). Implies monotone; totally monotone ⇒ monotone.
   function Is_Row_Minima_Monotone (A : Dense_Matrix) return Boolean
     with Pre => A'Length (1) <= Max_N and then A'Length (2) <= Max_M,
          Global => null;

   ---------------------------------------------------------------------------
   -- Naive baseline and SMAWK
   ---------------------------------------------------------------------------

   --  Leftmost column of the minimum in each row. O(n m) lookups.
   function Naive_Row_Minima (A : Dense_Matrix) return Argmin_Array
     with Pre => A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_N
            and then A'Length (2) <= Max_M,
          Global => null;

   function Naive_Row_Minima
     (Lookup     : not null Matrix_Lookup;
      Rows, Cols : Positive) return Argmin_Array
     with Pre => Rows <= Max_N and then Cols <= Max_M;

   --  Classic SMAWK reduce / interpolate recursion on a totally monotone
   --  matrix. Educational O(n + m) comparison bound when the matrix is
   --  totally monotone (caller responsibility). Leftmost ties.
   function SMAWK_Row_Minima (A : Dense_Matrix) return Argmin_Array
     with Pre => A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_N
            and then A'Length (2) <= Max_M;

   function SMAWK_Row_Minima
     (Lookup     : not null Matrix_Lookup;
      Rows, Cols : Positive) return Argmin_Array
     with Pre => Rows <= Max_N and then Cols <= Max_M;

   ---------------------------------------------------------------------------
   -- Bind dense matrix for library-level Matrix_Lookup demos
   ---------------------------------------------------------------------------

   --  Copy A into an internal scratch buffer. Bound_Lookup then implements
   --  Matrix_Lookup over that buffer (educational; not task-safe).
   procedure Bind_Dense (A : Dense_Matrix)
     with Pre => A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_N
            and then A'Length (2) <= Max_M;

   function Bound_Rows return Dim_N;
   function Bound_Cols return Dim_M;

   function Bound_Lookup (Row, Col : Positive) return Float
     with Pre => Row <= Max_N and then Col <= Max_M;

   ---------------------------------------------------------------------------
   -- Monge / totally monotone builders
   ---------------------------------------------------------------------------

   --  A(i,j) = F(i) + G(j) + C * i * j with C <= 0 (Monge / totally
   --  monotone for minima). Default F(i)=i, G(j)=j, C=-1.
   function Build_Monge_Product
     (Rows, Cols : Positive;
      C          : Float := -1.0) return Dense_Matrix
     with Pre => Rows <= Max_N and then Cols <= Max_M
            and then C <= 0.0,
          Global => null;

   --  A(i,j) = (i - j)^2  (discrete convex / Monge).
   function Build_Squared_Distance
     (Rows, Cols : Positive) return Dense_Matrix
     with Pre => Rows <= Max_N and then Cols <= Max_M, Global => null;

   --  A(i,j) = X(i) * Y(j) with X increasing, Y decreasing ⇒ Monge-like
   --  product form used in textbooks (here X(i)=i, Y(j)=-(j)).
   function Build_Antitone_Product
     (Rows, Cols : Positive) return Dense_Matrix
     with Pre => Rows <= Max_N and then Cols <= Max_M, Global => null;

   --  Deliberately non-totally-monotone 2×2 / larger examples for checkers.
   function Build_Non_Monotone_Example return Dense_Matrix
     with Global => null;

end Smawk;
