--  Gauss_Seidel — Ada 2023 educational package for Wikipedia
--  "Gauss–Seidel method" (Liebmann / successive displacement):
--  iterative solver for Ax = b that uses newly computed components
--  immediately within each sweep. Equivalent to SOR with ω = 1.
--  Cap n ≤ 32; dense Float.
--  Primary source:
--  https://en.wikipedia.org/wiki/Gauss%E2%80%93Seidel_method
--  Siblings: Ada-Successive-Over-Relaxation / Ada-Gaussian-Elimination /
--  Ada-Conjugate-Gradient / Ada-Stones-Method / Ada-Jacobi (README links).

pragma Ada_2022;

package Gauss_Seidel
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

   --  Tol      : stop when ‖r‖₂ ≤ Tol
   --  Max_Iter : hard iteration budget; 0 means use a generous default
   --  (Gauss–Seidel ≡ SOR with ω = 1; no Omega field here.)
   type Parameters is record
      Tol      : Float   := 1.0E-6;
      Max_Iter : Natural := 0;
   end record;

   Default_Parameters : constant Parameters :=
     (Tol => 1.0E-6, Max_Iter => 0);

   Default_Max_Iter : constant Natural := 10_000;

   type Status is
     (Converged, Iteration_Limit, Zero_Diagonal, Ill_Started,
      Dimension_Error);

   type Result is record
      X          : Vector (1 .. Max_N) := [others => 0.0];
      N          : Dimension := 0;
      Iterations : Natural := 0;
      Residual   : Float := 0.0;
      Stat       : Status := Ill_Started;
      Success    : Boolean := False;
   end record;

   type Example_Kind is
     (Diagonally_Dominant, Poisson_1D, Diagonal_Plus_Ones,
      Non_Convergent);

   Invalid_Argument : exception;

   Epsilon_Tol  : constant Float := 1.0E-10;
   Diagonal_Tol : constant Float := 1.0E-12;

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

   function Mat_Vec (A : Matrix; X : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length,
          Global => null;

   function Is_Symmetric
     (A : Matrix; Tol : Float := 1.0E-6) return Boolean
     with Pre => A'Length (1) = A'Length (2) and then Tol >= 0.0,
          Global => null;

   function Is_Diagonally_Dominant (A : Matrix) return Boolean
     with Pre => A'Length (1) = A'Length (2), Global => null;
   --  |A_ii| ≥ Σ_{j≠i} |A_ij| for every row (sufficient for Gauss–Seidel
   --  convergence on many systems; not necessary).

   function Is_Strictly_Diagonally_Dominant (A : Matrix) return Boolean
     with Pre => A'Length (1) = A'Length (2), Global => null;

   function Residual (A : Matrix; X, B : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length = B'Length,
          Global => null;
   --  r = b − A x

   function Residual_Norm (A : Matrix; X, B : Vector) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length = B'Length,
          Global => null;
   --  ‖b − A x‖₂

   ---------------------------------------------------------------------------
   -- Example builders (dense diagonally dominant / SPD Poisson-ish)
   ---------------------------------------------------------------------------

   function Make_Example
     (Kind : Example_Kind; N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  Diagonally_Dominant : A_ii = N, A_ij = 1 (i≠j) — strictly DD / SPD
   --  Poisson_1D          : tridiagonal (−1, 2, −1) discrete Laplacian
   --  Diagonal_Plus_Ones  : A = diag(N+1) + ones (SPD, DD)
   --  Non_Convergent      : educational counterexample (may fail to converge)

   function Make_RHS_Ones (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Zero_Vector (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Make_RHS_From_Solution
     (A : Matrix; X_Star : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X_Star'Length,
          Global => null;
   --  b := A x*  (known-solution test helper)

   ---------------------------------------------------------------------------
   -- Gauss–Seidel iteration
   ---------------------------------------------------------------------------

   function Solve
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N
            and then (X0'Length = 0 or else X0'Length = B'Length);
   --  Component update (Wikipedia / successive displacement):
   --    x_i := (1 / a_ii) (b_i − Σ_{j<i} a_ij x_j^{new}
   --                           − Σ_{j>i} a_ij x_j^{old})
   --  In-place overwrite of x. Requires nonzero diagonals.
   --  Empty X0 ⇒ zero start. Equivalent to SOR with ω = 1.

end Gauss_Seidel;
