--  Gaussian_Elimination — Ada 2023 educational package for Wikipedia
--  "Gaussian elimination" / row reduction with partial pivoting (GEPP):
--  forward elimination + back substitution for dense Ax = b, plus
--  determinant (product of pivots with swap sign) and rank estimate.
--  Cap n ≤ 32; dense educational Float. Not complete/rook pivoting.
--  Primary source:
--  https://en.wikipedia.org/wiki/Gaussian_elimination
--  Siblings: Ada-Thomas-Algorithm, Ada-Gauss-Seidel (upcoming),
--  Ada-Conjugate-Gradient, Ada-Levinson-Recursion (README links).

pragma Ada_2022;

package Gaussian_Elimination
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   Max_N : constant := 32;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   type Vector is array (Positive range <>) of Float;
   type Matrix is array (Positive range <>, Positive range <>) of Float;

   type Status is
     (Ok, Singular, Zero_Pivot, Dimension_Error, Ill_Started);

   type Result is record
      X          : Vector (1 .. Max_N) := [others => 0.0];
      N          : Dimension := 0;
      Stat       : Status := Ill_Started;
      Success    : Boolean := False;
      Swap_Count : Natural := 0;
   end record;

   --  Upper-triangular factor U and permuted RHS after GEPP.
   --  Only the leading N×N block and B(1..N) are meaningful.
   type Factor_Result is record
      U          : Matrix (1 .. Max_N, 1 .. Max_N) :=
                     [others => [others => 0.0]];
      B          : Vector (1 .. Max_N) := [others => 0.0];
      N          : Dimension := 0;
      Stat       : Status := Ill_Started;
      Success    : Boolean := False;
      Swap_Count : Natural := 0;
      Det_Sign   : Integer := 1;  --  (+1) or (−1) from row swaps
   end record;

   type Example_Kind is
     (Identity, Diag_Dominant, Hilbert_Tiny, Poisson_1D, Example_2x2,
      Example_3x3, Needs_Pivot);

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-10;
   Pivot_Tol   : constant Float := 1.0E-12;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vec_Near
     (A, B : Vector; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   function Norm2 (V : Vector) return Float
     with Global => null;

   function Max_Abs (V : Vector) return Float
     with Global => null;

   function Dot (U, V : Vector) return Float
     with Pre => U'Length = V'Length, Global => null;

   function Mat_Vec (A : Matrix; X : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length,
          Global => null;

   function Is_Square (A : Matrix) return Boolean
     with Global => null;

   function Is_Diagonally_Dominant (A : Matrix) return Boolean
     with Pre => A'Length (1) = A'Length (2), Global => null;
   --  |A_ii| ≥ Σ_{j≠i} |A_ij| for every row.

   function Is_Strictly_Diagonally_Dominant (A : Matrix) return Boolean
     with Pre => A'Length (1) = A'Length (2), Global => null;

   ---------------------------------------------------------------------------
   -- Residual: r = b − A x
   ---------------------------------------------------------------------------

   function Residual (A : Matrix; X, B : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length = B'Length
            and then X'Length >= 1,
          Global => null;

   function Residual_Norm (A : Matrix; X, B : Vector) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length = B'Length
            and then X'Length >= 1,
          Global => null;
   --  ‖r‖₂

   function Residual_Max_Abs (A : Matrix; X, B : Vector) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length = B'Length
            and then X'Length >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Zero_Vector (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Ones_Vector (N : Dimension; Value : Float := 1.0) return Vector
     with Pre => N >= 1, Global => null;

   function Identity (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   --  Row-diagonally-dominant: off-diagonals from a deterministic hash of
   --  (i,j), diagonal = row off-sum + Extra (default 1).
   function Make_Diagonally_Dominant
     (N : Dimension; Extra : Float := 1.0) return Matrix
     with Pre => N >= 1 and then Extra >= 0.0, Global => null;

   --  Hilbert H_ij = 1/(i+j−1); tiny / notoriously ill-conditioned.
   function Make_Hilbert (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   --  Dense (−1,2,−1) Poisson 1-D Laplacian (tridiagonal stored densely).
   function Make_Poisson_1D (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   --  Classic teaching examples / pivot-swap case.
   function Make_Example (Kind : Example_Kind; N : Dimension := 0)
     return Matrix
     with Global => null;
   --  Identity / Diag_Dominant / Hilbert_Tiny / Poisson_1D use N (≥1).
   --  Example_2x2 / Example_3x3 / Needs_Pivot ignore N (fixed size).

   function Make_RHS_Ones (N : Dimension; Value : Float := 1.0) return Vector
     with Pre => N >= 1, Global => null;

   --  b := A x  (for manufacturing exact solutions).
   function Make_RHS_From_Solution (A : Matrix; X : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- Factorization (forward elimination with partial pivoting)
   ---------------------------------------------------------------------------

   --  Copy A|b, GEPP → upper-triangular U and permuted RHS in Factor_Result.
   --  Does not modify inputs. Zero / tiny pivot → Singular / Zero_Pivot.
   function Factor (A : Matrix; B : Vector) return Factor_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N;

   --  Alias of Factor.
   function Eliminate (A : Matrix; B : Vector) return Factor_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N;

   --  Factor A alone (RHS treated as zeros) — useful for det / rank.
   function Factor_Matrix (A : Matrix) return Factor_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N;

   ---------------------------------------------------------------------------
   -- Back substitution and solve
   ---------------------------------------------------------------------------

   function Back_Substitute (F : Factor_Result) return Result
     with Pre => F.N >= 1 and then F.N <= Max_N;

   --  GEPP solve: copies A internally; partial pivoting; back-sub.
   function Solve (A : Matrix; B : Vector) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N;

   ---------------------------------------------------------------------------
   -- Determinant and rank
   ---------------------------------------------------------------------------

   --  det(A) = Det_Sign * Π U_ii after GEPP. Returns 0 on singular.
   --  Status out-parameter reports Ok / Singular / Zero_Pivot / …
   procedure Determinant
     (A    : Matrix;
      Det  : out Float;
      Stat : out Status)
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N;

   function Determinant (A : Matrix) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N;

   --  Number of pivots with |U_ii| > Tol after GEPP (rank estimate).
   function Rank
     (A : Matrix; Tol : Float := Pivot_Tol) return Natural
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N
            and then Tol >= 0.0;

end Gaussian_Elimination;
