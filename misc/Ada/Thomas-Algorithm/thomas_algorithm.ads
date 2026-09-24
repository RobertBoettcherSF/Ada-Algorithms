--  Thomas_Algorithm — Ada 2023 educational package for Wikipedia
--  "Tridiagonal matrix algorithm" / TDMA (Thomas algorithm): O(n)
--  specialized Gaussian elimination for a_i x_{i-1} + b_i x_i +
--  c_i x_{i+1} = d_i with a_1 = c_n = 0. Forward sweep (c', d') then
--  back substitution. Stable when diagonally dominant or SPD.
--  Cap n ≤ 256; dense educational Float.
--  Primary source:
--  https://en.wikipedia.org/wiki/Tridiagonal_matrix_algorithm
--  Siblings: Ada-Gaussian-Elimination / Ada-Gauss-Seidel (forthcoming),
--  Ada-Conjugate-Gradient / Ada-Sparse-Matrix (README links).

pragma Ada_2022;

package Thomas_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   Max_N : constant := 256;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   --  Sub-/main-/super-diagonal and RHS / solution vectors (1-based).
   --  Convention: A(1) and C(N) are unused / should be 0.
   type Vector is array (Positive range <>) of Float;

   type Status is
     (Ok, Degenerate, Ill_Started, Size_Mismatch);

   type Result is record
      X       : Vector (1 .. Max_N) := [others => 0.0];
      N       : Dimension := 0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
      Pivot   : Dim_Index := 1;  --  index of zero/tiny pivot when Degenerate
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol  : constant Float := 1.0E-10;
   Pivot_Tol    : constant Float := 1.0E-12;

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

   ---------------------------------------------------------------------------
   -- Diagonal dominance (row) for tridiagonal A,B,C
   ---------------------------------------------------------------------------

   function Is_Diagonally_Dominant
     (A, B, C : Vector) return Boolean
     with Pre => A'Length = B'Length
            and then B'Length = C'Length
            and then B'Length >= 1,
          Global => null;
   --  |b_i| ≥ |a_i| + |c_i| for every row i (sufficient for Thomas
   --  stability when also a_1 = c_n = 0; not necessary).

   function Is_Strictly_Diagonally_Dominant
     (A, B, C : Vector) return Boolean
     with Pre => A'Length = B'Length
            and then B'Length = C'Length
            and then B'Length >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- Residual: r_i = d_i − (a_i x_{i−1} + b_i x_i + c_i x_{i+1})
   ---------------------------------------------------------------------------

   function Residual
     (A, B, C, D, X : Vector) return Vector
     with Pre => A'Length = B'Length
            and then B'Length = C'Length
            and then C'Length = D'Length
            and then D'Length = X'Length
            and then X'Length >= 1,
          Global => null;

   function Residual_Norm
     (A, B, C, D, X : Vector) return Float
     with Pre => A'Length = B'Length
            and then B'Length = C'Length
            and then C'Length = D'Length
            and then D'Length = X'Length
            and then X'Length >= 1,
          Global => null;
   --  ‖r‖₂

   function Residual_Max_Abs
     (A, B, C, D, X : Vector) return Float
     with Pre => A'Length = B'Length
            and then B'Length = C'Length
            and then C'Length = D'Length
            and then D'Length = X'Length
            and then X'Length >= 1,
          Global => null;
   --  max_i |r_i|

   ---------------------------------------------------------------------------
   -- Builders (Poisson 1D discrete Laplacian and friends)
   ---------------------------------------------------------------------------

   --  Classic (−1, 2, −1) tridiagonal with A(1)=C(N)=0.
   procedure Make_Poisson_1D
     (N : Dimension;
      A, B, C : out Vector)
     with Pre => N >= 1
            and then A'First = 1 and then A'Last = N
            and then B'First = 1 and then B'Last = N
            and then C'First = 1 and then C'Last = N;

   --  Same diagonals plus RHS D (default ones).
   procedure Make_Poisson_1D_System
     (N : Dimension;
      A, B, C, D : out Vector;
      RHS_Value  : Float := 1.0)
     with Pre => N >= 1
            and then A'First = 1 and then A'Last = N
            and then B'First = 1 and then B'Last = N
            and then C'First = 1 and then C'Last = N
            and then D'First = 1 and then D'Last = N;

   --  Constant-coefficient tridiagonal: a_i=Sub, b_i=Diag, c_i=Super
   --  with A(1)=C(N)=0.
   procedure Make_Constant_Tridiagonal
     (N              : Dimension;
      Sub, Diag, Super : Float;
      A, B, C        : out Vector)
     with Pre => N >= 1
            and then A'First = 1 and then A'Last = N
            and then B'First = 1 and then B'Last = N
            and then C'First = 1 and then C'Last = N;

   function Zero_Vector (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Ones_Vector (N : Dimension; Value : Float := 1.0) return Vector
     with Pre => N >= 1, Global => null;

   ---------------------------------------------------------------------------
   -- Thomas / TDMA solve
   ---------------------------------------------------------------------------

   --  Solve a_i x_{i-1} + b_i x_i + c_i x_{i+1} = d_i.
   --  Does not modify inputs; uses working copies of C and D for c', d'.
   --  Returns Degenerate when a pivot denominator is |denom| ≤ Pivot_Tol.
   function Thomas
     (A, B, C, D : Vector) return Result
     with Pre => A'Length = B'Length
            and then B'Length = C'Length
            and then C'Length = D'Length
            and then D'Length >= 1
            and then D'Length <= Max_N;

   --  Alias of Thomas (same algorithm).
   function Solve
     (A, B, C, D : Vector) return Result
     with Pre => A'Length = B'Length
            and then B'Length = C'Length
            and then C'Length = D'Length
            and then D'Length >= 1
            and then D'Length <= Max_N;

   --  In-place variant: overwrites C and D with c' and d', writes X.
   --  A and B are read-only. On Degenerate, X is unspecified.
   procedure Thomas_In_Place
     (A, B     : Vector;
      C, D     : in out Vector;
      X        : out Vector;
      Stat     : out Status;
      Pivot_At : out Dim_Index)
     with Pre => A'Length = B'Length
            and then B'Length = C'Length
            and then C'Length = D'Length
            and then D'Length = X'Length
            and then X'Length >= 1
            and then X'Length <= Max_N
            and then A'First = B'First
            and then B'First = C'First
            and then C'First = D'First
            and then D'First = X'First;

end Thomas_Algorithm;
