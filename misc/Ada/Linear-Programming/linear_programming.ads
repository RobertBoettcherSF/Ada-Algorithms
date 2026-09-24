--  Linear_Programming — Ada 2023 educational survey package for
--  Wikipedia "Linear programming": standard / canonical form helpers
--  (≤ constraints → equality via slacks), embedded Bland two-phase
--  simplex Maximize / Minimize, weak duality and complementary-slackness
--  smoke checks, method taxonomy (Simplex / Interior_Point / Ellipsoid /
--  Dual_Simplex — only simplex fully implemented), feasibility /
--  unbounded demos, and an optional 2-variable graphical vertex helper.
--  Sibling solvers (full Simplex, Karmarkar, ILP, Dantzig–Wolfe, delayed
--  column generation) are README links only — no package deps.
--  Primary source: https://en.wikipedia.org/wiki/Linear_programming

pragma Ada_2022;

package Linear_Programming
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Decision / constraint caps for survey demos (incl. slack / art cols).
   Max_Constraints : constant := 16;
   Max_Vars        : constant := 32;
   Max_Vertices    : constant := 24;

   subtype Constraint_Count is Natural range 0 .. Max_Constraints;
   subtype Var_Count        is Natural range 0 .. Max_Vars;
   subtype Constraint_Index is Positive range 1 .. Max_Constraints;
   subtype Var_Index        is Positive range 1 .. Max_Vars;
   subtype Vertex_Count     is Natural range 0 .. Max_Vertices;

   type Matrix is
     array (Constraint_Index range <>, Var_Index range <>) of Real;
   type Vector is array (Positive range <>) of Real;

   type Status is (Optimal, Unbounded, Infeasible, Iteration_Limit);

   type Config is record
      Max_Pivots : Positive      := 500;
      Tol        : Positive_Real := 1.0E-10;
   end record;

   Default_Config : constant Config := (others => <>);

   type Tableau_Data is
     array (0 .. Max_Constraints, 0 .. Max_Vars) of Real;
   type Basic_Map is array (1 .. Max_Constraints) of Natural;

   --  Dense maximisation tableau (same spirit as Ada-Simplex-Algorithm):
   --    T(0, 0)      = objective value z
   --    T(0, 1 .. N) = reduced costs (enter when < −Tol)
   --    T(1 .. M, 0) = RHS
   --    Basic(i)     = variable index basic in row i
   type Tableau is record
      M            : Constraint_Count := 0;
      N            : Var_Count        := 0;
      N_Decision   : Var_Count        := 0;
      N_Slack      : Var_Count        := 0;
      N_Artificial : Var_Count        := 0;
      Obj_Phase1   : Natural          := 0;
      T            : Tableau_Data     := [others => [others => 0.0]];
      Basic        : Basic_Map        := [others => 0];
   end record;

   type Result is record
      Stat      : Status := Infeasible;
      Objective : Real := 0.0;
      X         : Vector (1 .. Max_Vars) := [others => 0.0];
      N_Vars    : Var_Count := 0;
      N_Pivots  : Natural := 0;
      Success   : Boolean := False;
   end record;

   --  2-D point for the graphical-method helper.
   type Point2 is record
      X, Y : Real := 0.0;
   end record;

   type Vertex_Array is array (1 .. Max_Vertices) of Point2;

   type Vertex_List is record
      Points : Vertex_Array := [others => <>];
      Count  : Vertex_Count := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Form / method taxonomy (metadata)
   ---------------------------------------------------------------------------

   --  Wikipedia: canonical ≈ Ax ≤ b, x ≥ 0; standard ≈ Ax = b, x ≥ 0;
   --  slack / augmented form introduces non-negative slack vars.
   type Form_Kind is (Canonical, Standard_Equality, Slack);

   type Method_Kind is
     (Simplex, Interior_Point, Ellipsoid, Dual_Simplex);

   type Method_Info is record
      Kind                    : Method_Kind;
      Polynomial_Worst_Case   : Boolean;
      Uses_Basis_Exchange     : Boolean;
      Fully_Implemented       : Boolean;  -- only Simplex = True here
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions / numeric helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vec_Near
     (A, B : Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   function Dot (A, B : Vector) return Real
     with Pre => A'Length = B'Length, Global => null;

   function Objective_Value (C, X : Vector) return Real
     with Pre => C'Length = X'Length, Global => null;
   --  cᵀx.

   ---------------------------------------------------------------------------
   -- Classification / naming
   ---------------------------------------------------------------------------

   function Classify_Method (Kind : Method_Kind) return Method_Info
     with Global => null;

   function Method_Name (Kind : Method_Kind) return String
     with Global => null;

   function Form_Name (Kind : Form_Kind) return String
     with Global => null;

   function Method_Count return Natural
     with Global => null;
   --  Number of Method_Kind values (4).

   function Form_Count return Natural
     with Global => null;
   --  Number of Form_Kind values (3).

   ---------------------------------------------------------------------------
   -- Standard / canonical / slack form helpers
   ---------------------------------------------------------------------------

   function Primal_Slack
     (A : Matrix; B, X : Vector) return Vector
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = X'Length,
          Global => null;
   --  w = b − Ax (componentwise). Feasible for Ax ≤ b when w ≥ 0 and X ≥ 0.

   function Dual_Slack
     (A : Matrix; C, Y : Vector) return Vector
     with Pre => A'Length (1) = Y'Length
            and then A'Length (2) = C'Length,
          Global => null;
   --  z = Aᵀy − c. Dual feasible (symmetric max-form) when z ≥ 0, Y ≥ 0.

   function Mat_Vec (A : Matrix; X : Vector) return Vector
     with Pre => A'Length (2) = X'Length, Global => null;

   function Mat_T_Vec (A : Matrix; Y : Vector) return Vector
     with Pre => A'Length (1) = Y'Length, Global => null;
   --  Aᵀy.

   function Is_Nonnegative
     (V : Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Feasible_Inequality
     (A   : Matrix;
      B   : Vector;
      X   : Vector;
      Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = X'Length
            and then Tol >= 0.0,
          Global => null;
   --  True iff Ax ≤ b + Tol and X ≥ −Tol.

   function Dual_Feasible
     (A   : Matrix;
      C   : Vector;
      Y   : Vector;
      Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length (1) = Y'Length
            and then A'Length (2) = C'Length
            and then Tol >= 0.0,
          Global => null;
   --  True iff Aᵀy ≥ c − Tol and Y ≥ −Tol (symmetric dual of max form).

   --  Convert Ax ≤ b into equality by appending an identity of slack
   --  columns: [A I] [x; s] = b. Returns the augmented coefficient matrix
   --  with Width = N_Decision + M rows×cols layout encoded as Matrix
   --  (1 .. M, 1 .. N+M). Caller supplies Out_A sized accordingly.
   procedure Append_Slacks
     (A     : Matrix;
      Out_A : out Matrix)
     with Pre => A'Length (1) = Out_A'Length (1)
            and then Out_A'Length (2) = A'Length (2) + A'Length (1)
            and then Out_A'Length (2) <= Max_Vars;

   function Slack_Column_Count (M_Rows : Constraint_Count) return Var_Count
     with Global => null;
   --  One slack per ≤ row.

   ---------------------------------------------------------------------------
   -- Embedded dense LP (Bland tableau) — Maximize / Minimize
   ---------------------------------------------------------------------------

   function Active_Obj_Row (Tab : Tableau) return Natural
     with Global => null;

   function Is_Optimal_LP
     (Tab : Tableau; Tol : Real := Epsilon_Tol) return Boolean
     with Global => null;

   function Select_Entering
     (Tab : Tableau; Tol : Real := Epsilon_Tol) return Natural
     with Global => null;

   function Select_Leaving
     (Tab       : Tableau;
      Enter_Col : Positive;
      Tol       : Real := Epsilon_Tol) return Natural
     with Pre => Enter_Col <= Max_Vars, Global => null;

   procedure Pivot
     (Tab                  : in out Tableau;
      Leave_Row, Enter_Col : Positive)
     with Pre => Leave_Row <= Max_Constraints
            and then Enter_Col <= Max_Vars;

   function Build_Tableau
     (A : Matrix; B, C : Vector) return Tableau
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then A'Length (1) <= Max_Constraints
            and then A'Length (2) + A'Length (1) <= Max_Vars,
          Global => null;
   --  max cᵀx s.t. Ax ≤ b, x ≥ 0 (slack / artificial two-phase).

   function Extract_Primal
     (Tab : Tableau; N_Decision : Var_Count) return Vector
     with Pre => N_Decision <= Max_Vars, Global => null;

   function Solve_Tableau
     (Tab : in out Tableau;
      Cfg : Config := Default_Config) return Result;

   function Maximize
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      Cfg : Config := Default_Config) return Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_Constraints
            and then A'Length (2) + A'Length (1) <= Max_Vars;
   --  max cᵀx s.t. Ax ≤ b, x ≥ 0.

   function Minimize
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      Cfg : Config := Default_Config) return Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_Constraints
            and then A'Length (2) + A'Length (1) <= Max_Vars;
   --  min cᵀx s.t. Ax ≤ b, x ≥ 0  (implemented as Maximize (−c)).

   ---------------------------------------------------------------------------
   -- Weak duality / complementary slackness (symmetric max-form)
   ---------------------------------------------------------------------------
   --  Primal: max cᵀx  s.t. Ax ≤ b, x ≥ 0
   --  Dual:   min bᵀy  s.t. Aᵀy ≥ c, y ≥ 0
   --  Weak duality: feasible pair ⇒ cᵀx ≤ bᵀy.
   --  Complementary slackness: xⱼ zⱼ = 0 and wᵢ yᵢ = 0.

   function Weak_Duality_Holds
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      X   : Vector;
      Y   : Vector;
      Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length (1) = B'Length
            and then A'Length (1) = Y'Length
            and then A'Length (2) = C'Length
            and then A'Length (2) = X'Length
            and then Tol >= 0.0,
          Global => null;
   --  True when (X,Y) are primal/dual feasible and cᵀx ≤ bᵀy + Tol.
   --  Returns False if either side is infeasible (smoke helper).

   function Complementary_Slackness_Holds
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      X   : Vector;
      Y   : Vector;
      Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length (1) = B'Length
            and then A'Length (1) = Y'Length
            and then A'Length (2) = C'Length
            and then A'Length (2) = X'Length
            and then Tol >= 0.0,
          Global => null;
   --  Smoke check: |xⱼ zⱼ| ≤ Tol and |wᵢ yᵢ| ≤ Tol for all i,j
   --  (does not by itself prove optimality without feasibility).

   function Duality_Gap
     (C, X, B, Y : Vector) return Real
     with Pre => C'Length = X'Length and then B'Length = Y'Length,
          Global => null;
   --  bᵀy − cᵀx (nonnegative under weak duality for max form).

   ---------------------------------------------------------------------------
   -- Geometric 2-variable graphical method (optional helper)
   ---------------------------------------------------------------------------

   function Feasible_Vertices_2D
     (A   : Matrix;
      B   : Vector;
      Tol : Real := Epsilon_Tol) return Vertex_List
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = 2
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_Constraints
            and then Tol >= 0.0,
          Global => null;
   --  Enumerate vertices of {x ∈ R² : Ax ≤ b, x ≥ 0} by intersecting
   --  pairs of binding lines (incl. x=0, y=0) and keeping feasible points.
   --  Caps at Max_Vertices; educational only.

   function Best_Vertex
     (Verts : Vertex_List;
      C     : Vector;
      Sense : Character := 'M') return Point2
     with Pre => C'Length = 2
            and then (Sense = 'M' or else Sense = 'm'),
          Global => null;
   --  Among Verts, pick argmax ('M') or argmin ('m') of cᵀ[x;y].
   --  Raises Invalid_Argument if Count = 0.

   function Evaluate_At (P : Point2; C : Vector) return Real
     with Pre => C'Length = 2, Global => null;

end Linear_Programming;
