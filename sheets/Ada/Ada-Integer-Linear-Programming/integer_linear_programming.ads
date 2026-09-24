--  Integer_Linear_Programming — Ada 2023 educational survey package for
--  Wikipedia "Integer linear programming": problem taxonomy (Pure_IP /
--  Binary_IP / MILP), LP relaxation via an embedded tiny Bland two-phase
--  simplex (inequality form), integrality-gap helpers, exact 0–1 knapsack
--  DP, and a tiny pure branch-and-bound (no cuts) for small binary IPs
--  (n ≤ 12). Full Branch-and-Cut / Cutting-Plane / Simplex / Karmarkar
--  live in sibling repos (README links only — no package deps).
--  Primary source:
--  https://en.wikipedia.org/wiki/Integer_linear_programming

pragma Ada_2022;

package Integer_Linear_Programming
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Decision-var / constraint caps for survey demos.
   Max_Problem_Vars : constant := 12;
   Max_Problem_Rows : constant := 16;

   --  Tableau room: original rows + bound rows + slacks / artificials.
   Max_Constraints : constant := 48;
   Max_Vars        : constant := 64;

   --  0–1 knapsack DP capacity (weight sum).
   Max_Knapsack_Capacity : constant := 200;
   Max_Knapsack_Items    : constant := 32;

   subtype Constraint_Count is Natural range 0 .. Max_Constraints;
   subtype Var_Count        is Natural range 0 .. Max_Vars;
   subtype Constraint_Index is Positive range 1 .. Max_Constraints;
   subtype Var_Index        is Positive range 1 .. Max_Vars;
   subtype Problem_Var_Count is Natural range 0 .. Max_Problem_Vars;
   subtype Problem_Row_Count is Natural range 0 .. Max_Problem_Rows;
   subtype Binary_Var_Count  is Natural range 0 .. Max_Problem_Vars;

   type Matrix is
     array (Constraint_Index range <>, Var_Index range <>) of Real;
   type Vector is array (Positive range <>) of Real;

   --  Which decision variables must be integer (MILP / pure IP).
   type Integer_Flags is array (Positive range <>) of Boolean;

   --  Binary assignment x_j ∈ {0,1}.
   type Binary_Vector is array (Positive range <>) of Boolean;

   type Status is
     (Optimal, Infeasible, Unbounded, Node_Limit, Iteration_Limit);

   --  Max_Pivots : simplex pivot budget per LP
   --  Max_Nodes  : B&B node budget (binary branch-and-bound)
   --  Tol / Integer_Tol : numeric / integrality tolerances
   type Config is record
      Max_Pivots  : Positive      := 500;
      Max_Nodes   : Positive      := 500;
      Tol         : Positive_Real := 1.0E-9;
      Integer_Tol : Positive_Real := 1.0E-6;
   end record;

   Default_Config : constant Config := (others => <>);

   type Tableau_Data is
     array (0 .. Max_Constraints, 0 .. Max_Vars) of Real;
   type Basic_Map is array (1 .. Max_Constraints) of Natural;

   --  Dense maximisation tableau (same spirit as Ada-Simplex):
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
      Nodes     : Natural := 0;
      N_Pivots  : Natural := 0;
      Success   : Boolean := False;
   end record;

   ---------------------------------------------------------------------------
   -- Problem / method taxonomy (metadata)
   ---------------------------------------------------------------------------

   type Problem_Kind is (Pure_IP, Binary_IP, MILP);

   type Method_Kind is
     (Branch_And_Bound,
      Cutting_Planes,
      Branch_And_Cut,
      Dynamic_Programming);

   type Method_Info is record
      Kind          : Method_Kind;
      Uses_LP       : Boolean;
      Uses_Cuts     : Boolean;
      Exact         : Boolean;
      Special_Case  : Boolean;  -- e.g. knapsack DP
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions / numeric helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vec_Near
     (A, B : Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   function Frac (X : Real) return Real
     with Global => null;
   --  Fractional part in [0, 1): X − ⌊X⌋ (for negative X uses floor).

   function Is_Integer
     (X : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Is_Integer_Vector
     (X : Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Is_Binary
     (X : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True iff X ≈ 0 or X ≈ 1 within Tol.

   function Is_Binary_Vector
     (X : Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Required_Are_Integer
     (X        : Vector;
      Required : Integer_Flags;
      Tol      : Real := Epsilon_Tol) return Boolean
     with Pre => X'Length = Required'Length and then Tol >= 0.0,
          Global => null;

   ---------------------------------------------------------------------------
   -- Classification
   ---------------------------------------------------------------------------

   function Classify
     (Required : Integer_Flags;
      Binary   : Boolean := False) return Problem_Kind
     with Pre => Required'Length >= 1, Global => null;
   --  Binary=True forces Binary_IP when all Required are True.
   --  Else: all Required True → Pure_IP; some False → MILP;
   --  none Required → Pure_IP treated as continuous (still Pure_IP tag
   --  is avoided: if no integer vars, returns MILP with zero integers
   --  — callers usually pass at least one Required).

   function Classify_Method (Kind : Method_Kind) return Method_Info
     with Global => null;

   function Method_Name (Kind : Method_Kind) return String
     with Global => null;

   function Problem_Name (Kind : Problem_Kind) return String
     with Global => null;

   function Method_Count return Natural
     with Global => null;
   --  Number of Method_Kind values (4).

   ---------------------------------------------------------------------------
   -- Embedded dense LP (Bland tableau) — LP relaxation helpers
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

   function Maximize_LP
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
   --  Solve the continuous LP relaxation max cᵀx s.t. Ax ≤ b, x ≥ 0.

   ---------------------------------------------------------------------------
   -- Integrality gap
   ---------------------------------------------------------------------------

   function Integrality_Gap
     (LP_Opt : Real;
      IP_Opt : Real) return Real
     with Global => null;
   --  Absolute gap LP_Opt − IP_Opt (maximization: LP ≥ IP when both exact).

   function Relative_Integrality_Gap
     (LP_Opt : Real;
      IP_Opt : Real) return Real
     with Global => null;
   --  (LP_Opt − IP_Opt) / max(1, |IP_Opt|). Non-negative when LP ≥ IP.

   function Gap_From_Relaxation
     (A        : Matrix;
      B        : Vector;
      C        : Vector;
      IP_Opt   : Real;
      Cfg      : Config := Default_Config) return Real
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1;
   --  Solve LP relaxation and return Integrality_Gap (LP, IP_Opt).
   --  Raises Invalid_Argument if the LP is not Optimal.

   ---------------------------------------------------------------------------
   -- Feasibility / rounding heuristics
   ---------------------------------------------------------------------------

   function Feasible_Inequality
     (A   : Matrix;
      B   : Vector;
      X   : Vector;
      Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = X'Length
            and then Tol >= 0.0,
          Global => null;
   --  True iff Ax ≤ b + Tol (componentwise) and X ≥ −Tol.

   function Round_Binary
     (X : Vector; Tol : Real := Epsilon_Tol) return Binary_Vector
     with Pre => X'Length >= 1 and then Tol >= 0.0, Global => null;
   --  Componentwise: ≥ 0.5 → True (1), else False (0).

   function Binary_To_Real (Bits : Binary_Vector) return Vector
     with Pre => Bits'Length >= 1, Global => null;

   function Objective_Value (C : Vector; X : Vector) return Real
     with Pre => C'Length = X'Length, Global => null;

   function Round_And_Check
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      X   : Vector;
      Tol : Real := Epsilon_Tol) return Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then A'Length (2) = X'Length
            and then Tol >= 0.0;
   --  Round X to binary, check Ax ≤ b; on success return Optimal with
   --  that objective; else Infeasible (Success=False).

   ---------------------------------------------------------------------------
   -- 0–1 knapsack DP (classic special case)
   ---------------------------------------------------------------------------

   type Knapsack_Item is record
      Weight : Natural := 0;
      Value  : Real    := 0.0;
   end record;

   type Knapsack_Items is
     array (Positive range <>) of Knapsack_Item;

   type Knapsack_Result is record
      Objective : Real := 0.0;
      Selected  : Binary_Vector (1 .. Max_Knapsack_Items) :=
                    [others => False];
      N_Items   : Natural := 0;
      Capacity  : Natural := 0;
      Success   : Boolean := False;
   end record;

   function Solve_Knapsack_01
     (Items    : Knapsack_Items;
      Capacity : Natural) return Knapsack_Result
     with Pre => Items'Length >= 1
            and then Items'Length <= Max_Knapsack_Items
            and then Capacity <= Max_Knapsack_Capacity;
   --  Exact max Σ v_i x_i s.t. Σ w_i x_i ≤ Capacity, x_i ∈ {0,1}.
   --  Classic O(n·W) DP. Zero-weight items with positive value are taken.

   ---------------------------------------------------------------------------
   -- Tiny pure branch-and-bound (no cuts) for small binary IPs
   ---------------------------------------------------------------------------

   function Branch_Variable_Binary
     (X   : Vector;
      Tol : Real := Epsilon_Tol) return Natural
     with Pre => Tol >= 0.0, Global => null;
   --  Most-fractional index among components not near {0,1}.
   --  Returns 0 if all are binary within Tol.

   function Solve_Binary_BB
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      Cfg : Config := Default_Config) return Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_Problem_Rows
            and then A'Length (2) <= Max_Problem_Vars;
   --  Maximize cᵀx s.t. Ax ≤ b, x ∈ {0,1}^n (n ≤ 12).
   --  Pure branch-and-bound: LP relaxation at each node, branch by
   --  fixing a fractional binary variable to 0 or 1. No cutting planes
   --  (see Ada-Branch-and-Cut / Ada-Cutting-Plane-Method).

end Integer_Linear_Programming;
