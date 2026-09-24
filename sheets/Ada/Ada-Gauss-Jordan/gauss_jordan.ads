--  Gauss_Jordan — Ada 2023 educational package for Wikipedia
--  "Gaussian elimination" / Gauss–Jordan elimination (RREF):
--  reduce augmented [A|b] to [I|x], or [A|I] to [I|A^{-1}], with
--  partial pivoting. Also rank via RREF and det via pivot product
--  (before scaling). Cap n ≤ 32; dense educational Float.
--  Primary source:
--  https://en.wikipedia.org/wiki/Gaussian_elimination
--  Siblings: Ada-Gaussian-Elimination (GEPP + back-sub),
--  Ada-Gauss-Seidel, Ada-Thomas-Algorithm, Ada-Conjugate-Gradient.

pragma Ada_2022;

package Gauss_Jordan
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

   --  Solve result: x from reducing [A|b] → [I|x].
   type Result is record
      X          : Vector (1 .. Max_N) := [others => 0.0];
      N          : Dimension := 0;
      Stat       : Status := Ill_Started;
      Success    : Boolean := False;
      Swap_Count : Natural := 0;
   end record;

   --  Inverse result: A^{-1} from reducing [A|I] → [I|A^{-1}].
   type Invert_Result is record
      Inv        : Matrix (1 .. Max_N, 1 .. Max_N) :=
                     [others => [others => 0.0]];
      N          : Dimension := 0;
      Stat       : Status := Ill_Started;
      Success    : Boolean := False;
      Swap_Count : Natural := 0;
   end record;

   --  RREF of a square matrix (leading N×N block meaningful).
   type RREF_Result is record
      R          : Matrix (1 .. Max_N, 1 .. Max_N) :=
                     [others => [others => 0.0]];
      N          : Dimension := 0;
      Rank_Value : Natural := 0;
      Stat       : Status := Ill_Started;
      Success    : Boolean := False;
      Swap_Count : Natural := 0;
   end record;

   type Example_Kind is
     (Identity, Diag_Dominant, Hilbert_Tiny, Poisson_1D, Example_2x2,
      Example_3x3, Needs_Pivot, Singular_2x2);

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

   function Mat_Near
     (A, B : Matrix; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => A'Length (1) = B'Length (1)
            and then A'Length (2) = B'Length (2)
            and then Tol >= 0.0,
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

   function Mat_Mul (A, B : Matrix) return Matrix
     with Pre => A'Length (1) = A'Length (2)
            and then B'Length (1) = B'Length (2)
            and then A'Length (2) = B'Length (1),
          Global => null;

   function Is_Square (A : Matrix) return Boolean
     with Global => null;

   function Is_Diagonally_Dominant (A : Matrix) return Boolean
     with Pre => A'Length (1) = A'Length (2), Global => null;

   function Is_Strictly_Diagonally_Dominant (A : Matrix) return Boolean
     with Pre => A'Length (1) = A'Length (2), Global => null;

   ---------------------------------------------------------------------------
   -- Residual: r = b − A x ; inverse residual Frobenius-ish max |A Inv − I|
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

   function Residual_Max_Abs (A : Matrix; X, B : Vector) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length = B'Length
            and then X'Length >= 1,
          Global => null;

   --  max_{i,j} |(A * Inv)_{ij} − δ_{ij}|  (uses leading N of Inv)
   function Inverse_Residual_Max_Abs
     (A, Inv : Matrix) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then Inv'Length (1) >= A'Length (1)
            and then Inv'Length (2) >= A'Length (1)
            and then A'Length (1) >= 1,
          Global => null;

   --  Copy leading N×N block (for Invert_Result.Inv / RREF_Result.R).
   function Leading_Square (A : Matrix; N : Dimension) return Matrix
     with Pre => N >= 1
            and then A'Length (1) >= N
            and then A'Length (2) >= N,
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

   function Make_Diagonally_Dominant
     (N : Dimension; Extra : Float := 1.0) return Matrix
     with Pre => N >= 1 and then Extra >= 0.0, Global => null;

   function Make_Hilbert (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   function Make_Poisson_1D (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   function Make_Example (Kind : Example_Kind; N : Dimension := 0)
     return Matrix
     with Global => null;
   --  Identity / Diag_Dominant / Hilbert_Tiny / Poisson_1D use N (≥1).
   --  Fixed-size kinds ignore N.

   function Make_RHS_Ones (N : Dimension; Value : Float := 1.0) return Vector
     with Pre => N >= 1, Global => null;

   function Make_RHS_From_Solution (A : Matrix; X : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- Core: Solve / Invert / RREF
   ---------------------------------------------------------------------------

   --  Gauss–Jordan with partial pivoting on [A|b] → [I|x].
   --  Does not modify inputs. Singular / tiny pivot → Singular / Zero_Pivot.
   function Solve (A : Matrix; B : Vector) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N;

   --  Gauss–Jordan on [A|I] → [I|A^{-1}].
   function Invert (A : Matrix) return Invert_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N;

   --  Reduce square A to RREF (partial pivoting; continues past zero cols).
   --  Success is True when reduction completes (even if rank-deficient);
   --  Stat = Ok if full rank, Singular if rank < N.
   function Reduce_To_RREF (A : Matrix) return RREF_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N;

   ---------------------------------------------------------------------------
   -- Determinant and rank
   ---------------------------------------------------------------------------

   --  det(A) = Det_Sign * Π pivots  (pivots recorded BEFORE row scaling).
   --  Returns 0 on singular / zero pivot.
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

   --  Rank from RREF (number of nonzero pivots above Tol).
   function Rank
     (A : Matrix; Tol : Float := Pivot_Tol) return Natural
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N
            and then Tol >= 0.0;

end Gauss_Jordan;
