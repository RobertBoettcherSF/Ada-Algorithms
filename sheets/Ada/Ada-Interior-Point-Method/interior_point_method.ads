--  Interior_Point_Method — Ada 2023 educational package for Wikipedia
--  "Interior-point method": primal affine-scaling and logarithmic-barrier
--  path-following for small dense linear programs. Traverses the strict
--  interior of the feasible region (not vertices). Documents the IPM
--  taxonomy (barrier, primal-dual, affine-scaling); affine-scaling and
--  barrier drivers are fully implemented. Dense GE, n ≤ 12, m ≤ 8.
--  Primary source:
--  https://en.wikipedia.org/wiki/Interior-point_method
--  Siblings: Ada-Karmarkars-Algorithm, Ada-Simplex-Algorithm,
--  Ada-Linear-Programming (survey).

pragma Ada_2022;

package Interior_Point_Method
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

   --  Dense square systems for normal equations (m × m).
   type Square_Matrix is
     array (Constraint_Index range <>, Constraint_Index range <>) of Real;

   type Vector is array (Positive range <>) of Real;

   type Status is
     (Optimal, Iteration_Limit, Ill_Started, Unbounded);

   type Objective_Sense is (Minimize_Sense, Maximize_Sense);

   --  IPM taxonomy (Wikipedia / textbooks). Affine_Scaling and
   --  Logarithmic_Barrier are fully implemented; Primal_Dual is named for
   --  taxonomy / Classify_Method (Mehrotra-style PD is out of educational
   --  scope here — Solve maps it to Logarithmic_Barrier).
   type Method_Kind is
     (Affine_Scaling, Logarithmic_Barrier, Primal_Dual);

   --  Max_Iterations : hard iteration budget (affine) or outer×inner (barrier)
   --  Tol            : stationarity / residual / feasibility tolerance
   --  Step_Fraction  : γ ∈ (0,1) fraction of distance to the boundary
   --  Min_Step       : treat smaller steps as numerical stall → Optimal
   --  Method         : which IPM family to run
   --  Mu_Init        : initial barrier parameter μ > 0
   --  Mu_Min         : stop when μ ≤ Mu_Min (and stationarity ok)
   --  Mu_Factor      : μ ← Mu_Factor · μ after centering (∈ (0,1))
   --  Centering_Iters: Newton / affine steps per μ level
   type Config is record
      Max_Iterations  : Positive      := 200;
      Tol             : Positive_Real := 1.0E-8;
      Step_Fraction   : Positive_Real := 0.9;
      Min_Step        : Positive_Real := 1.0E-14;
      Method          : Method_Kind   := Affine_Scaling;
      Mu_Init         : Positive_Real := 1.0;
      Mu_Min          : Positive_Real := 1.0E-10;
      Mu_Factor       : Positive_Real := 0.1;
      Centering_Iters : Positive      := 8;
   end record;

   type Result is record
      Stat       : Status := Ill_Started;
      Objective  : Real := 0.0;
      X          : Vector (1 .. Max_Vars) := [others => 0.0];
      N_Vars     : Var_Count := 0;
      Iterations : Natural := 0;
      Mu_Final   : Real := 0.0;
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
   -- Taxonomy helpers
   ---------------------------------------------------------------------------

   function Method_Name (M : Method_Kind) return String
     with Global => null;

   function Classify_Method (Name : String) return Method_Kind
     with Global => null;
   --  Case-insensitive match on "affine", "barrier"/"log", "primal-dual"/"pd".
   --  Raises Invalid_Argument if unrecognized.

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

   function Solve_GE
     (A : Square_Matrix; B : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) = B'Length,
          Global => null;
   --  Dense Gaussian elimination with partial pivoting.
   --  Raises Singular_System if numerically singular.

   function Solve_SPD
     (A : Square_Matrix; B : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) = B'Length,
          Global => null;
   --  Alias of Solve_GE for the SPD normal matrix A D² Aᵀ.

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
     (A            : Matrix;
      C            : Vector;
      X            : Vector;
      Sense        : Objective_Sense;
      DX           : out Vector;
      R_Scaled_Inf : out Non_Negative)
     with Pre => A'Length (1) >= 1
            and then A'Length (2) = C'Length
            and then C'Length = X'Length
            and then DX'Length = X'Length;
   --  D = diag(X). Solve (A D² Aᵀ) y = A D² ĉ, r = ĉ − Aᵀ y,
   --  DX = ± D² r. R_Scaled_Inf = ‖D r‖_∞.

   ---------------------------------------------------------------------------
   -- Logarithmic barrier primitives
   ---------------------------------------------------------------------------

   function Barrier_Value
     (C : Vector; X : Vector; Mu : Positive_Real) return Real
     with Pre => C'Length = X'Length and then All_Positive (X, 0.0),
          Global => null;
   --  φ_μ(x) = cᵀx − μ Σ log x_i  (minimize sense).

   procedure Barrier_Direction
     (A            : Matrix;
      C            : Vector;
      X            : Vector;
      Mu           : Positive_Real;
      Sense        : Objective_Sense;
      DX           : out Vector;
      Grad_Scaled  : out Non_Negative)
     with Pre => A'Length (1) >= 1
            and then A'Length (2) = C'Length
            and then C'Length = X'Length
            and then DX'Length = X'Length
            and then All_Positive (X, 0.0);
   --  Newton step for min/max ±(cᵀx − μ Σ log x_i) s.t. Ax=b.
   --  H = diag(μ / x_i²); solve (A H⁻¹ Aᵀ) λ = A H⁻¹ g with
   --  g = ±c − μ X⁻¹ e; DX = −H⁻¹ (g − Aᵀ λ). Grad_Scaled = ‖X ⊙ (g−Aᵀλ)‖_∞.

   function Interior_Step
     (X             : Vector;
      DX            : Vector;
      Step_Fraction : Positive_Real;
      Min_Step      : Positive_Real := 1.0E-14)
     return Vector
     with Pre => X'Length = DX'Length
            and then All_Positive (X, 0.0);
   --  α = Step_Fraction · min_i{−X_i/DX_i : DX_i < 0}; X_new = X + α DX.

   function Max_Feasible_Step (X, DX : Vector) return Real
     with Pre => X'Length = DX'Length, Global => null;

   ---------------------------------------------------------------------------
   -- Inequality → equality helpers (slack conversion)
   ---------------------------------------------------------------------------

   procedure Expand_Inequalities
     (A_In   : Matrix;
      B      : Vector;
      C_In   : Vector;
      X0_In  : Vector;
      A_Out  : out Matrix;
      C_Out  : out Vector;
      X0_Out : out Vector;
      N_Out  : out Var_Count)
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
   --  Ax ≤ b, x > 0 → [A I][x;s]=b with s = b−Ax > 0.

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
   --  Dispatch on Cfg.Method: Affine_Scaling or Logarithmic_Barrier
   --  (Primal_Dual → Logarithmic_Barrier). Strictly feasible X0 required.

   function Solve_Affine
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

   function Solve_Barrier
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
   --  Path-following: reduce μ, take Centering_Iters Newton steps per level.

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

end Interior_Point_Method;
