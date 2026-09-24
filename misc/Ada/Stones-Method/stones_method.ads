--  Stones_Method — Ada 2023 educational package for Wikipedia
--  "Stone's method" / Strongly Implicit Procedure (SIP) (Harold S. Stone,
--  1968): iterative solver based on an incomplete LU factorization with
--  Stone fill-term compensation (parameter alpha). Designed for small
--  2D Poisson / five-point stencil systems (n = N_Grid² ≤ Max_N) and for
--  dense ILU(0)-style incomplete factors on general matrices.
--  Primary source:
--  https://en.wikipedia.org/wiki/Stone%27s_method
--  Siblings: Ada-Successive-Over-Relaxation / Ada-Conjugate-Gradient /
--  Ada-Thomas-Algorithm / Ada-Sparse-Matrix (README links).

pragma Ada_2022;

package Stones_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  Cap on unknowns: N_Grid × N_Grid ≤ Max_N for the structured builder.
   Max_N : constant := 64;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   type Vector is array (Positive range <>) of Float;
   type Matrix is array (Positive range <>, Positive range <>) of Float;

   --  Five-point stencil diagonals for an n-unknown structured system
   --  (row-major ordering of an N_Grid × N_Grid interior grid):
   --    A_W(i) x_{i-1} + A_S(i) x_{i-N} + A_P(i) x_i
   --      + A_E(i) x_{i+1} + A_N(i) x_{i+N} = b_i
   type Pentadiagonal is record
      N_Grid : Dimension := 0;
      N      : Dimension := 0;
      A_W    : Vector (1 .. Max_N) := [others => 0.0];
      A_E    : Vector (1 .. Max_N) := [others => 0.0];
      A_S    : Vector (1 .. Max_N) := [others => 0.0];
      A_N    : Vector (1 .. Max_N) := [others => 0.0];
      A_P    : Vector (1 .. Max_N) := [others => 0.0];
   end record;

   --  Incomplete L / U factors in Stone (SIP) pentadiagonal form:
   --    L: lower (LW, LS, LP);  U: unit diagonal + (UE, UN)
   type SIP_Factors is record
      N_Grid : Dimension := 0;
      N      : Dimension := 0;
      Alpha  : Float := 0.92;
      L_W    : Vector (1 .. Max_N) := [others => 0.0];
      L_S    : Vector (1 .. Max_N) := [others => 0.0];
      L_P    : Vector (1 .. Max_N) := [others => 0.0];
      U_E    : Vector (1 .. Max_N) := [others => 0.0];
      U_N    : Vector (1 .. Max_N) := [others => 0.0];
      Valid  : Boolean := False;
   end record;

   --  Dense incomplete LU (unit-diagonal U) for Option B / general A.
   type Dense_ILU is record
      N     : Dimension := 0;
      Alpha : Float := 0.0;
      L     : Matrix (1 .. Max_N, 1 .. Max_N) :=
        [others => [others => 0.0]];
      U     : Matrix (1 .. Max_N, 1 .. Max_N) :=
        [others => [others => 0.0]];
      Valid : Boolean := False;
   end record;

   --  Alpha    : Stone fill-compensation parameter in [0, 1]
   --             (classic CFD default ≈ 0.92; 0 ≈ plain ILU(0)-like)
   --  Tol      : stop when ‖r‖₂ ≤ Tol
   --  Max_Iter : hard iteration budget; 0 means use a generous default
   type Parameters is record
      Alpha    : Float   := 0.92;
      Tol      : Float   := 1.0E-8;
      Max_Iter : Natural := 0;
   end record;

   Default_Parameters : constant Parameters :=
     (Alpha => 0.92, Tol => 1.0E-8, Max_Iter => 0);

   Default_Max_Iter : constant Natural := 5_000;

   type Status is
     (Converged, Iteration_Limit, Factorization_Failed,
      Bad_Alpha, Zero_Diagonal, Ill_Started);

   type Result is record
      X          : Vector (1 .. Max_N) := [others => 0.0];
      N          : Dimension := 0;
      Iterations : Natural := 0;
      Residual   : Float := 0.0;
      Stat       : Status := Ill_Started;
      Success    : Boolean := False;
   end record;

   type Example_Kind is
     (Poisson_2D, Diagonally_Dominant, Poisson_1D);

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
   -- Example builders
   ---------------------------------------------------------------------------

   function Make_Poisson_2D (N_Grid : Dimension) return Pentadiagonal
     with Pre => N_Grid >= 1
            and then N_Grid * N_Grid <= Max_N,
          Global => null;
   --  Standard five-point discrete Laplacian on an N_Grid × N_Grid
   --  interior with Dirichlet-homogeneous boundary embedding:
   --    A_P = 4, A_W = A_E = A_S = A_N = −1 (missing neighbours = 0).

   function Pentadiagonal_To_Dense (P : Pentadiagonal) return Matrix
     with Pre => P.N >= 1 and then P.N <= Max_N, Global => null;

   function Make_Example
     (Kind : Example_Kind; N : Dimension) return Matrix
     with Pre => N >= 1
            and then (if Kind = Poisson_2D then
                        N * N <= Max_N
                      else
                        N <= Max_N),
          Global => null;
   --  Poisson_2D          : dense form of Make_Poisson_2D (N_Grid = N)
   --  Diagonally_Dominant : A_ii = N, A_ij = 1 (i≠j)
   --  Poisson_1D          : tridiagonal (−1, 2, −1)

   function Make_RHS_Ones (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Zero_Vector (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Make_RHS_From_Solution
     (A : Matrix; X_Star : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X_Star'Length,
          Global => null;
   --  b := A x*

   function Make_RHS_From_Solution
     (P : Pentadiagonal; X_Star : Vector) return Vector
     with Pre => P.N >= 1 and then X_Star'Length = P.N, Global => null;

   function Apply_Pentadiagonal
     (P : Pentadiagonal; X : Vector) return Vector
     with Pre => P.N >= 1 and then X'Length = P.N, Global => null;

   function Residual_Penta
     (P : Pentadiagonal; X, B : Vector) return Vector
     with Pre => P.N >= 1
            and then X'Length = P.N
            and then B'Length = P.N,
          Global => null;

   function Residual_Norm_Penta
     (P : Pentadiagonal; X, B : Vector) return Float
     with Pre => P.N >= 1
            and then X'Length = P.N
            and then B'Length = P.N,
          Global => null;

   ---------------------------------------------------------------------------
   -- Stone incomplete factorization + SIP iteration (Option A)
   ---------------------------------------------------------------------------

   function Factor_SIP
     (P : Pentadiagonal; Alpha : Float := 0.92) return SIP_Factors
     with Pre => P.N >= 1 and then Alpha >= 0.0 and then Alpha <= 1.0,
          Global => null;
   --  Build Stone-like incomplete L / U matching the five-point pattern.
   --  Neglected fill is approximately cancelled into the diagonal via Alpha.

   function Apply_SIP_Preconditioner
     (F : SIP_Factors; R : Vector) return Vector
     with Pre => F.Valid and then R'Length = F.N, Global => null;
   --  Solve M z = r via forward substitution on L then back on U.

   function Solve_SIP
     (P      : Pentadiagonal;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
     with Pre => P.N >= 1
            and then B'Length = P.N
            and then P.N <= Max_N
            and then (X0'Length = 0 or else X0'Length = B'Length);
   --  Residual form: r := b − A x;  z := M⁻¹ r;  x := x + z
   --  until ‖r‖₂ ≤ Tol (equivalent to Wikipedia Mx^{k+1} = Nx^k + b).

   ---------------------------------------------------------------------------
   -- Dense incomplete LU with optional Stone diagonal tweak (Option B)
   ---------------------------------------------------------------------------

   function Factor_ILU0
     (A : Matrix; Alpha : Float := 0.0) return Dense_ILU
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N
            and then Alpha >= 0.0
            and then Alpha <= 1.0,
          Global => null;
   --  ILU(0): factor only where A is nonzero. When Alpha > 0, a fraction
   --  of the neglected fill row-sum is added to the pivot (Stone-ish).

   function Apply_Dense_ILU
     (F : Dense_ILU; R : Vector) return Vector
     with Pre => F.Valid and then R'Length = F.N, Global => null;

   function Solve_SIP_Dense
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N
            and then (X0'Length = 0 or else X0'Length = B'Length);
   --  Same residual iteration using dense ILU(0)/Stone M = L U.

   ---------------------------------------------------------------------------
   -- Optional Jacobi / Gauss–Seidel comparison (dense)
   ---------------------------------------------------------------------------

   function Solve_Jacobi
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N
            and then (X0'Length = 0 or else X0'Length = B'Length);

   function Solve_Gauss_Seidel
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N
            and then (X0'Length = 0 or else X0'Length = B'Length);

end Stones_Method;
