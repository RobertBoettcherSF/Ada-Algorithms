--  Sparse_Matrix — Ada 2023 educational package for Wikipedia
--  "Sparse matrix": storage formats (COO / CSR / CSC) and sparse
--  matrix–vector products (SpMV). Caps n ≤ 64, nnz ≤ 512.
--  Primary source: https://en.wikipedia.org/wiki/Sparse_matrix
--  Siblings: Ada-Minimum-Degree / Ada-Cuthill-McKee /
--  Ada-Conjugate-Gradient (README links).

pragma Ada_2022;

package Sparse_Matrix
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / domain types
   ---------------------------------------------------------------------------

   Max_N   : constant := 64;
   Max_Nnz : constant := 512;

   subtype Dim       is Natural  range 0 .. Max_N;
   subtype Index     is Positive range 1 .. Max_N;
   subtype Nnz_Count is Natural  range 0 .. Max_Nnz;

   type Vector is array (Positive range <>) of Float;
   type Dense_Matrix is
     array (Positive range <>, Positive range <>) of Float;

   type Value_Array is array (Positive range <>) of Float;
   --  Column / row indices of nonzeros (1-based).
   type Index_Array is array (Positive range <>) of Index;
   --  CSR/CSC pointers into Values (1 .. Nnz+1 style).
   type Ptr_Array is array (Positive range <>) of Natural;

   ---------------------------------------------------------------------------
   -- Triplet / COO / CSR / CSC
   ---------------------------------------------------------------------------

   type Triplet is record
      Row   : Index := 1;
      Col   : Index := 1;
      Value : Float := 0.0;
   end record;

   type Triplet_Array is array (Positive range <>) of Triplet;

   --  Coordinate list: unsorted (row, col, value) triples.
   type COO (Nnz : Nnz_Count := 0; Rows : Dim := 0; Cols : Dim := 0) is
   record
      Entries : Triplet_Array (1 .. Nnz) :=
        [others => (Row => 1, Col => 1, Value => 0.0)];
   end record;

   --  Compressed Sparse Row (Yale / CSR / CRS), 1-based Ada convention:
   --  Row_Ptr (I) .. Row_Ptr (I+1)−1 indexes the nonzeros of row I;
   --  Row_Ptr (1) = 1 and Row_Ptr (Rows+1) = Nnz+1 (empty ⇒ both 1).
   --  Row_Ptr uses a fixed upper bound Max_N+1 because Ada forbids
   --  discriminant expressions such as Rows+1 in component constraints.
   --  Only indices 1 .. Rows+1 are meaningful (Row_Ptr(1)=1,
   --  Row_Ptr(Rows+1)=Nnz+1).
   type CSR (Nnz : Nnz_Count := 0; Rows : Dim := 0; Cols : Dim := 0) is
   record
      Values  : Value_Array (1 .. Nnz) := [others => 0.0];
      Col_Ind : Index_Array (1 .. Nnz) := [others => 1];
      Row_Ptr : Ptr_Array (1 .. Max_N + 1) := [others => 1];
   end record;

   --  Compressed Sparse Column (CSC / CCS), analogous column pointers.
   --  Only Col_Ptr indices 1 .. Cols+1 are meaningful.
   type CSC (Nnz : Nnz_Count := 0; Rows : Dim := 0; Cols : Dim := 0) is
   record
      Values  : Value_Array (1 .. Nnz) := [others => 0.0];
      Row_Ind : Index_Array (1 .. Nnz) := [others => 1];
      Col_Ptr : Ptr_Array (1 .. Max_N + 1) := [others => 1];
   end record;

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   Epsilon_Tol : constant Float := 1.0E-5;

   ---------------------------------------------------------------------------
   -- Numeric / density helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vec_Near
     (A, B : Vector; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0, Global => null;

   function Mat_Near
     (A, B : Dense_Matrix; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => A'Length (1) = B'Length (1)
            and then A'Length (2) = B'Length (2)
            and then Tol >= 0.0,
          Global => null;

   function Density (Nnz : Natural; Rows, Cols : Natural) return Float
     with Global => null;
   --  Nnz / (Rows*Cols); 0 when Rows=0 or Cols=0.

   function Sparsity (Nnz : Natural; Rows, Cols : Natural) return Float
     with Global => null;
   --  1 − Density (fraction of structural zeros).

   function Density (A : Dense_Matrix; Tol : Float := Epsilon_Tol)
     return Float
     with Pre => Tol >= 0.0, Global => null;

   function Sparsity (A : Dense_Matrix; Tol : Float := Epsilon_Tol)
     return Float
     with Pre => Tol >= 0.0, Global => null;

   function Count_Nnz (A : Dense_Matrix; Tol : Float := Epsilon_Tol)
     return Natural
     with Pre => Tol >= 0.0, Global => null;

   function Density (C : COO) return Float with Global => null;
   function Sparsity (C : COO) return Float with Global => null;
   function Density (C : CSR) return Float with Global => null;
   function Sparsity (C : CSR) return Float with Global => null;
   function Density (C : CSC) return Float with Global => null;
   function Sparsity (C : CSC) return Float with Global => null;

   ---------------------------------------------------------------------------
   -- Dense ↔ sparse construction
   ---------------------------------------------------------------------------

   function Zero_Dense (Rows, Cols : Dim) return Dense_Matrix
     with Pre => Rows <= Max_N and then Cols <= Max_N, Global => null;

   function Zero_Vector (N : Dim) return Vector
     with Pre => N <= Max_N, Global => null;

   function From_Dense
     (A : Dense_Matrix; Tol : Float := Epsilon_Tol) return COO
     with Pre => A'Length (1) <= Max_N
            and then A'Length (2) <= Max_N
            and then Tol >= 0.0;
   --  Collect |a_ij| > Tol as triplets (row-major). Raises
   --  Capacity_Exceeded if Nnz > Max_Nnz.

   function To_Dense (C : COO) return Dense_Matrix;
   --  Scatter triplets into a dense Rows×Cols matrix (duplicate
   --  positions are summed).

   function To_Dense (C : CSR) return Dense_Matrix;
   function To_Dense (C : CSC) return Dense_Matrix;

   function Dense_Mat_Vec (A : Dense_Matrix; X : Vector) return Vector
     with Pre => A'Length (2) = X'Length, Global => null;
   --  Reference dense y = A x for SpMV checks.

   ---------------------------------------------------------------------------
   -- Get / Set (dense + sparse views)
   ---------------------------------------------------------------------------

   function Get (A : Dense_Matrix; I, J : Index) return Float
     with Pre => I in A'Range (1) and then J in A'Range (2),
          Global => null;

   procedure Set (A : in out Dense_Matrix; I, J : Index; Value : Float)
     with Pre => I in A'Range (1) and then J in A'Range (2);

   function Get (C : CSR; I, J : Index) return Float
     with Pre => I in 1 .. C.Rows and then J in 1 .. C.Cols;
   --  O(row nnz) scan; missing entry → 0.

   function Get (C : CSC; I, J : Index) return Float
     with Pre => I in 1 .. C.Rows and then J in 1 .. C.Cols;

   function Get (C : COO; I, J : Index) return Float
     with Pre => I in 1 .. C.Rows and then J in 1 .. C.Cols;
   --  Sum of all triplets at (I,J); missing → 0.

   ---------------------------------------------------------------------------
   -- Format conversions
   ---------------------------------------------------------------------------

   function To_CSR (C : COO) return CSR;
   --  Sort by (row, col), coalesce duplicate positions by summing,
   --  build Row_Ptr / Col_Ind / Values.

   function To_CSC (C : COO) return CSC;
   --  Sort by (col, row), coalesce, build Col_Ptr / Row_Ind / Values.

   function To_COO (C : CSR) return COO;
   function To_COO (C : CSC) return COO;

   function To_CSC (C : CSR) return CSC;
   --  Via COO (educational; not a specialized in-place convert).

   function To_CSR (C : CSC) return CSR;

   function Is_Valid_CSR (C : CSR) return Boolean;
   function Is_Valid_CSC (C : CSC) return Boolean;
   --  Pointer monotonicity, index bounds, Row_Ptr(1)=1,
   --  Row_Ptr(Rows+1)=Nnz+1 (and CSC analogues).

   ---------------------------------------------------------------------------
   -- SpMV: y = A x
   ---------------------------------------------------------------------------

   function SpMV_CSR (A : CSR; X : Vector) return Vector
     with Pre => X'Length = A.Cols;
   --  Primary SpMV: row-wise y_i = Σ_j A_ij x_j.

   function SpMV_CSC (A : CSC; X : Vector) return Vector
     with Pre => X'Length = A.Cols;
   --  Column-wise accumulation.

   function SpMV_COO (A : COO; X : Vector) return Vector
     with Pre => X'Length = A.Cols;
   --  Scatter-add over triplets.

   ---------------------------------------------------------------------------
   -- Textbook builders
   ---------------------------------------------------------------------------

   function Diagonal (Diag : Vector) return COO
     with Pre => Diag'Length <= Max_N;
   --  Square diag(Diag); Nnz = number of nonzero Diag entries.

   function Diagonal_CSR (Diag : Vector) return CSR
     with Pre => Diag'Length <= Max_N;

   function Tridiagonal
     (Lower, Main, Upper : Vector) return COO
     with Pre => Main'Length >= 1
            and then Main'Length <= Max_N
            and then Lower'Length = Main'Length - 1
            and then Upper'Length = Main'Length - 1;
   --  Square tridiagonal; zero entries omitted from the COO.

   function Tridiagonal_CSR
     (Lower, Main, Upper : Vector) return CSR
     with Pre => Main'Length >= 1
            and then Main'Length <= Max_N
            and then Lower'Length = Main'Length - 1
            and then Upper'Length = Main'Length - 1;

   function Identity (N : Dim) return CSR
     with Pre => N <= Max_N;
   --  I_N as CSR (all ones on the diagonal).

   function Random_COO
     (Rows, Cols   : Dim;
      Target_Nnz   : Nnz_Count;
      Seed         : Natural := 42;
      Value_Scale  : Float   := 1.0) return COO
     with Pre => Rows <= Max_N
            and then Cols <= Max_N
            and then Target_Nnz <= Max_Nnz
            and then (Rows = 0 or else Cols = 0
                        or else Target_Nnz <= Rows * Cols);
   --  Deterministic LCG fill of distinct positions (fixed Seed).

   ---------------------------------------------------------------------------
   -- Taxonomy (survey of storage formats)
   ---------------------------------------------------------------------------

   type Format_Kind is
     (Coordinate_COO,
      Compressed_Row_CSR,
      Compressed_Column_CSC,
      Diagonal_DIA,
      ELLPACK_ELL,
      Blocked_BSR);

   function Format_Name (F : Format_Kind) return String;
   function Implemented (F : Format_Kind) return Boolean;
   function Forthcoming (F : Format_Kind) return Boolean;

end Sparse_Matrix;
