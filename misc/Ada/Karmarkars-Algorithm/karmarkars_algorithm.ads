--  Karmarkars_Algorithm — Ada 2023 educational package for Wikipedia
--  "Karmarkar's algorithm": an affine-scaling / simplified Karmarkar-style
--  interior-point method for small dense linear programs. This is NOT a
--  bit-exact reproduction of Karmarkar's 1984 projective potential-reduction
--  algorithm; it walks through the strict interior toward improving
--  directions after diagonal scaling, in the spirit of that breakthrough.
--  Primary source:
--  https://en.wikipedia.org/wiki/Karmarkar%27s_algorithm
--  Sibling (vertex method): Ada-Simplex-Algorithm.

pragma Ada_2022;

package Karmarkars_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Dense interior-point limits (educational size).
   Max_Constraints : constant := 8;
   Max_Vars        : constant := 12;

   subtype Constraint_Count is Natural range 0 .. Max_Constraints;
   subtype Var_Count        is Natural range 0 .. Max_Vars;
   subtype Constraint_Index is Positive range 1 .. Max_Constraints;
   subtype Var_Index        is Positive range 1 .. Max_Vars;

   --  Dense A (rows = equality constraints, cols = variables).
   type Matrix is
     array (Constraint_Index range <>, Var_Index range <>) of Real;

   --  Dense square systems for normal equations (m × m, m ≤ Max_Constraints).
   type Square_Matrix is
     array (Constraint_Index range <>, Constraint_Index range <>) of Real;

   type Vector is array (Positive range <>) of Real;

   type Status is
     (Optimal, Iteration_Limit, Ill_Started, Unbounded);

   type Objective_Sense is (Minimize_Sense, Maximize_Sense);

   --  Max_Iterations : hard iteration budget
   --  Tol            : stationarity / residual / feasibility tolerance
   --  Step_Fraction  : γ ∈ (0,1) fraction of distance to the boundary
   --  Min_Step       : treat smaller steps as numerical stall → Optimal
   type Config is record
      Max_Iterations : Positive      := 200;
      Tol            : Positive_Real := 1.0E-8;
      Step_Fraction  : Positive_Real := 0.9;
      Min_Step       : Positive_Real := 1.0E-14;
   end record;

   type Result is record
      Stat       : Status := Ill_Started;
      Objective  : Real := 0.0;
      X          : Vector (1 .. Max_Vars) := [others => 0.0];
      N_Vars     : Var_Count := 0;
      Iterations : Natural := 0;
      Success    : Boolean := False;  -- True iff Stat = Optimal
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   Singular_System  : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vec_Near
     (A, B : Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   function Dot (A, B : Vector) return Real
     with Pre => A'Length = B'Length, Global => null;

   function Norm_Inf (X : Vector) return Non_Negative
     with Global => null;

   function Norm2 (X : Vector) return Non_Negative
     with Global => null;

   function Scale (C : Real; X : Vector) return Vector
     with Global => null;

   function Add (A, B : Vector) return Vector
     with Pre => A'Length = B'Length, Global => null;

   function Sub (A, B : Vector) return Vector
     with Pre => A'Length = B'Length, Global => null;

   ---------------------------------------------------------------------------
   -- Linear algebra (exposed for unit tests)
   ---------------------------------------------------------------------------

   function Mat_Vec (A : Matrix; X : Vector) return Vector
     with Pre => A'Length (2) = X'Length, Global => null;
   --  y = A x  (m-vector).

   function Mat_Vec_T (A : Matrix; Y : Vector) return Vector
     with Pre => A'Length (1) = Y'Length, Global => null;
   --  x = Aᵀ y  (n-vector).

   function Mat_Vec (A : Square_Matrix; X : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) = X'Length,
          Global => null;
   --  Square mat-vec for normal-equation systems.

   function Solve_GE
     (A : Square_Matrix; B : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) = B'Length,
          Global => null;
   --  Dense Gaussian elimination with partial pivoting (m ≤ Max_Constraints).
   --  Raises Singular_System if numerically singular.

   function Solve_SPD
     (A : Square_Matrix; B : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) = B'Length,
          Global => null;
   --  Alias of Solve_GE for the SPD normal matrix A D² Aᵀ (same GE path).

   function Project_Nullspace
     (A : Matrix; V : Vector) return Vector
     with Pre => A'Length (2) = V'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1,
          Global => null;
   --  (I − Aᵀ (A Aᵀ)⁻¹ A) V : Euclidean projection onto nullspace of A.

   function Feasible_Residual
     (A : Matrix; B, X : Vector) return Non_Negative
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = X'Length,
          Global => null;
   --  ‖A x − b‖_∞

   function All_Positive
     (X : Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Affine-scaling primitives
   ---------------------------------------------------------------------------

   procedure Affine_Direction
     (A      : Matrix;
      C      : Vector;
      X      : Vector;
      Sense  : Objective_Sense;
      DX     : out Vector;
      R_Scaled_Inf : out Non_Negative)
     with Pre => A'Length (1) >= 1
            and then A'Length (2) = C'Length
            and then C'Length = X'Length
            and then DX'Length = X'Length;
   --  Diagonal scale D = diag(X). Solve (A D² Aᵀ) y = A D² ĉ, then
   --  r = ĉ − Aᵀ y and DX = ± D² r (sign by Sense). R_Scaled_Inf = ‖D r‖_∞
   --  is the stationarity measure. Raises Singular_System if A D² Aᵀ is
   --  singular (rank-deficient scaled constraints).

   function Interior_Step
     (X             : Vector;
      DX            : Vector;
      Step_Fraction : Positive_Real;
      Min_Step      : Positive_Real := 1.0E-14)
     return Vector
     with Pre => X'Length = DX'Length
            and then All_Positive (X, 0.0);
   --  α = Step_Fraction · min_i{−X_i/DX_i : DX_i < 0}; X_new = X + α DX.
   --  If no blocking component and ‖DX‖ is tiny, returns X unchanged.
   --  Raises Invalid_Argument when the ray is unbounded (no DX_i < 0 and
   --  ‖DX‖_∞ > Min_Step).

   function Max_Feasible_Step (X, DX : Vector) return Real
     with Pre => X'Length = DX'Length, Global => null;
   --  min{−X_i/DX_i : DX_i < 0}, or Real'Last if none (unbounded ray).

   ---------------------------------------------------------------------------
   -- Inequality → equality helpers (slack conversion)
   ---------------------------------------------------------------------------

   procedure Expand_Inequalities
     (A_In  : Matrix;
      B     : Vector;
      C_In  : Vector;
      X0_In : Vector;
      A_Out : out Matrix;
      C_Out : out Vector;
      X0_Out : out Vector;
      N_Out : out Var_Count)
     with Pre => A_In'Length (1) = B'Length
            and then A_In'Length (2) = C_In'Length
            and then C_In'Length = X0_In'Length
            and then A_In'Length (1) >= 1
            and then A_In'Length (2) >= 1
            and then A_In'Length (2) + A_In'Length (1) <= Max_Vars
            and then A_Out'Length (1) = A_In'Length (1)
            and then A_Out'Length (2) >= A_In'Length (2) + A_In'Length (1)
            and then C_Out'Length >= A_In'Length (2) + A_In'Length (1)
            and then X0_Out'Length >= A_In'Length (2) + A_In'Length (1);
   --  Convert Ax ≤ b, x > 0 into [A I][x;s]=b with s = b−Ax > 0 required.
   --  C_Out = [C_In; 0], X0_Out = [X0_In; s0]. Raises Ill path via
   --  Invalid_Argument if any slack would be non-positive.

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   function Solve
     (A     : Matrix;
      B     : Vector;
      C     : Vector;
      X0    : Vector;
      Sense : Objective_Sense := Minimize_Sense;
      Cfg   : Config := (others => <>)) return Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then C'Length = X0'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_Constraints
            and then A'Length (2) <= Max_Vars;
   --  Affine-scaling interior-point on Ax=b, x>0 from strictly feasible X0.

   function Minimize
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      X0  : Vector;
      Cfg : Config := (others => <>)) return Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then C'Length = X0'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_Constraints
            and then A'Length (2) <= Max_Vars;

   function Maximize
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      X0  : Vector;
      Cfg : Config := (others => <>)) return Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then C'Length = X0'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_Constraints
            and then A'Length (2) <= Max_Vars;

   function Maximize_Inequalities
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      X0  : Vector;
      Cfg : Config := (others => <>)) return Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then C'Length = X0'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_Constraints
            and then A'Length (2) + A'Length (1) <= Max_Vars;
   --  max cᵀx s.t. Ax ≤ b, x > 0 from interior X0 (slacks appended).

   function Minimize_Inequalities
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      X0  : Vector;
      Cfg : Config := (others => <>)) return Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then C'Length = X0'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_Constraints
            and then A'Length (2) + A'Length (1) <= Max_Vars;

end Karmarkars_Algorithm;
