--  Gram_Schmidt — Ada 2023 educational package for Wikipedia
--  "Gram–Schmidt process": classical and modified orthonormalization
--  of k vectors in R^n (columns of an n×k matrix). Detects rank drop
--  when a residual norm is near zero. Cap n,k ≤ 32; dense Float.
--  Primary source:
--  https://en.wikipedia.org/wiki/Gram%E2%80%93Schmidt_process
--  Siblings: Ada-Gaussian-Elimination; upcoming QR / Rayleigh / Power /
--  Lanczos / Arnoldi / Eigenvalue survey (README links).

pragma Ada_2022;

package Gram_Schmidt
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   Max_N : constant := 32;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   type Vector is array (Positive range <>) of Float;
   --  Matrix: rows = ambient dimension n, columns = input / output vectors.
   type Matrix is array (Positive range <>, Positive range <>) of Float;

   type Status is
     (Ok, Rank_Deficient, Dimension_Error, Ill_Started, Zero_Vector);

   type Method_Kind is (Classical, Modified);

   --  Q holds the orthonormal columns in its leading N×Rank block.
   type Result is record
      Q       : Matrix (1 .. Max_N, 1 .. Max_N) :=
                  [others => [others => 0.0]];
      N       : Dimension := 0;   -- ambient dimension (rows)
      K       : Dimension := 0;   -- number of input columns
      Rank    : Natural := 0;     -- number of orthonormal columns produced
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
      Method  : Method_Kind := Classical;
   end record;

   type Example_Kind is
     (Identity_Basis, Independent_Set, Dependent_Set, Hilbert_Columns,
      Orthogonal_Already, Nearly_Dependent);

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-10;
   Rank_Tol    : constant Float := 1.0E-6;  -- near-zero residual → drop

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

   --  proj_U(V) = (<V,U>/<U,U>) U  for nonzero U.
   function Proj (U, V : Vector) return Vector
     with Pre => U'Length = V'Length and then U'Length >= 1,
          Global => null;

   function Column (A : Matrix; J : Positive) return Vector
     with Pre => J in A'Range (2), Global => null;

   procedure Set_Column
     (A : in out Matrix; J : Positive; V : Vector)
     with Pre => J in A'Range (2)
            and then V'Length = A'Length (1);

   --  Max | (Qᵀ Q)_ij − δ_ij | over the leading Rank columns.
   function Orthonormality_Residual
     (Q : Matrix; N, Rank : Dimension; Tol : Float := Epsilon_Tol)
      return Float
     with Pre => N >= 1 and then Rank >= 0
            and then N <= Max_N and then Rank <= Max_N
            and then Tol >= 0.0,
          Global => null;

   function Is_Orthonormal
     (Q : Matrix; N, Rank : Dimension; Tol : Float := 1.0E-5)
      return Boolean
     with Pre => N >= 1 and then Rank >= 0
            and then N <= Max_N and then Rank <= Max_N
            and then Tol >= 0.0,
          Global => null;
   --  True when Rank = 0, or Qᵀ Q ≈ I_Rank within Tol.

   ---------------------------------------------------------------------------
   -- Builders (columns = vectors)
   ---------------------------------------------------------------------------

   function Zero_Vector (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Ones_Vector (N : Dimension; Value : Float := 1.0) return Vector
     with Pre => N >= 1, Global => null;

   --  Standard basis e_1..e_N as columns of the N×N identity.
   function Standard_Basis (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   --  Deterministic “random-ish” linearly independent set: lower-triangular
   --  with positive diagonal plus small upper fill from a hash of (i,j).
   function Make_Independent (N, K : Dimension) return Matrix
     with Pre => N >= 1 and then K >= 1 and then K <= N, Global => null;

   --  Dependent set: first K−1 independent, last column = sum of earlier.
   function Make_Dependent (N, K : Dimension) return Matrix
     with Pre => N >= 1 and then K >= 2 and then K <= N, Global => null;

   --  First K columns of the Hilbert matrix H_ij = 1/(i+j−1).
   function Make_Hilbert_Columns (N, K : Dimension) return Matrix
     with Pre => N >= 1 and then K >= 1 and then K <= N, Global => null;

   --  Already orthonormal: first K standard basis vectors in R^N.
   function Make_Orthogonal_Already (N, K : Dimension) return Matrix
     with Pre => N >= 1 and then K >= 1 and then K <= N, Global => null;

   --  Nearly dependent: columns of Make_Independent with last ≈ previous.
   function Make_Nearly_Dependent (N, K : Dimension) return Matrix
     with Pre => N >= 1 and then K >= 2 and then K <= N, Global => null;

   function Make_Example
     (Kind : Example_Kind; N : Dimension; K : Dimension := 0) return Matrix
     with Global => null;
   --  K defaults to N when K = 0. Dependent_Set / Nearly_Dependent need K≥2.

   ---------------------------------------------------------------------------
   -- Orthonormalization
   ---------------------------------------------------------------------------

   --  Classical Gram–Schmidt: subtract all prior projections of the
   --  *original* column, then normalize. Numerically less stable.
   function Classical_GS
     (V : Matrix; Tol : Float := Rank_Tol) return Result
     with Pre => V'Length (1) >= 1
            and then V'Length (2) >= 1
            and then V'Length (1) <= Max_N
            and then V'Length (2) <= Max_N
            and then Tol >= 0.0;

   --  Modified Gram–Schmidt: subtract projections one-by-one against the
   --  *updated* residual. Better numerical behaviour for educational Float.
   function Modified_GS
     (V : Matrix; Tol : Float := Rank_Tol) return Result
     with Pre => V'Length (1) >= 1
            and then V'Length (2) >= 1
            and then V'Length (1) <= Max_N
            and then V'Length (2) <= Max_N
            and then Tol >= 0.0;

   --  Default entry point: Modified_GS (preferred educational default).
   function Orthonormalize
     (V      : Matrix;
      Method : Method_Kind := Modified;
      Tol    : Float := Rank_Tol) return Result
     with Pre => V'Length (1) >= 1
            and then V'Length (2) >= 1
            and then V'Length (1) <= Max_N
            and then V'Length (2) <= Max_N
            and then Tol >= 0.0;

end Gram_Schmidt;
