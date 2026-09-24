--  Delayed_Column_Generation — Ada 2023 educational package for Wikipedia
--  "Delayed column generation" / "Column generation": restricted master
--  problem (RMP) + pricing subproblem, demonstrated on cutting-stock.
--  Embedded dense Bland two-phase tableau simplex (sibling ideas only —
--  no with-clause dependency on Ada-Simplex-Algorithm).
--  Caps: items ≤ 8, rod width W ≤ 50, columns ≤ 64.
--  Primary sources:
--  https://en.wikipedia.org/wiki/Delayed_column_generation
--  https://en.wikipedia.org/wiki/Column_generation
--  Sibling forthcoming: Ada-Dantzig-Wolfe (decomposition).

pragma Ada_2022;

package Delayed_Column_Generation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Items     : constant := 8;
   Max_Width     : constant := 50;
   Max_Columns   : constant := 64;
   --  Tableau room: decision columns + surplus + artificials + Phase-I row.
   Max_Constraints : constant := 16;
   Max_Vars        : constant := 80;

   subtype Item_Count     is Natural range 0 .. Max_Items;
   subtype Item_Index     is Positive range 1 .. Max_Items;
   subtype Width_Value    is Natural range 0 .. Max_Width;
   subtype Column_Count   is Natural range 0 .. Max_Columns;
   subtype Column_Index   is Positive range 1 .. Max_Columns;
   subtype Constraint_Count is Natural range 0 .. Max_Constraints;
   subtype Var_Count        is Natural range 0 .. Max_Vars;
   subtype Constraint_Index is Positive range 1 .. Max_Constraints;
   subtype Var_Index        is Positive range 1 .. Max_Vars;

   type Matrix is
     array (Constraint_Index range <>, Var_Index range <>) of Real;
   type Vector is array (Positive range <>) of Real;

   --  Pattern: how many pieces of each item width in one rod.
   type Pattern_Counts is array (Item_Index) of Natural;

   type Column is record
      Counts : Pattern_Counts := [others => 0];
      Cost   : Real := 1.0;
      Valid  : Boolean := False;
   end record;

   type Column_Pool is array (Column_Index) of Column;

   type Status is
     (Optimal, Infeasible, Unbounded, Iteration_Limit, Column_Limit);

   --  Max_Iters    : outer column-generation rounds
   --  Max_Columns  : hard column-pool cap (≤ package Max_Columns)
   --  Max_Pivots   : simplex pivot budget per RMP solve
   --  Tol          : numerical zero for reduced costs / ratios / duals
   type Config is record
      Max_Iters   : Positive      := 64;
      Max_Columns : Positive      := Delayed_Column_Generation.Max_Columns;
      Max_Pivots  : Positive      := 800;
      Tol         : Positive_Real := 1.0E-9;
   end record;

   type Tableau_Data is
     array (0 .. Max_Constraints, 0 .. Max_Vars) of Real;
   type Basic_Map is array (1 .. Max_Constraints) of Natural;

   --  Dense maximisation tableau (same layout spirit as Ada-Simplex):
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

   --  Pricing result for 0-1 / unbounded-integer knapsack over item widths.
   type Pricing_Result is record
      Counts       : Pattern_Counts := [others => 0];
      Value        : Real := 0.0;       -- π · a
      Reduced_Cost : Real := 0.0;      -- cost − π · a  (improving if < 0)
      Improving    : Boolean := False;
      Feasible     : Boolean := False;
   end record;

   type Result is record
      Stat         : Status := Infeasible;
      Objective    : Real := 0.0;
      Lambda       : Vector (1 .. Max_Columns) := [others => 0.0];
      Duals        : Vector (1 .. Max_Items) := [others => 0.0];
      Pool         : Column_Pool := [others => <>];
      N_Items      : Item_Count := 0;
      N_Columns    : Column_Count := 0;
      N_Iters      : Natural := 0;
      N_Pivots     : Natural := 0;
      Success      : Boolean := False;
   end record;

   type RMP_Result is record
      Stat       : Status := Infeasible;
      Objective  : Real := 0.0;
      Lambda     : Vector (1 .. Max_Columns) := [others => 0.0];
      Duals      : Vector (1 .. Max_Items) := [others => 0.0];
      N_Columns  : Column_Count := 0;
      N_Items    : Item_Count := 0;
      N_Pivots   : Natural := 0;
      Success    : Boolean := False;
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-9;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vec_Near
     (A, B : Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   ---------------------------------------------------------------------------
   -- Column-pool helpers
   ---------------------------------------------------------------------------

   function Pattern_Width
     (Counts : Pattern_Counts;
      Widths : Vector;
      N      : Item_Count) return Natural
     with Pre => N <= Max_Items
            and then Widths'Length >= Natural (N),
          Global => null;

   function Patterns_Equal
     (A, B : Pattern_Counts; N : Item_Count) return Boolean
     with Pre => N <= Max_Items, Global => null;

   function Pattern_Exists
     (Pool   : Column_Pool;
      N_Cols : Column_Count;
      Counts : Pattern_Counts;
      N      : Item_Count) return Boolean
     with Pre => N_Cols <= Max_Columns and then N <= Max_Items,
          Global => null;

   procedure Clear_Pool (Pool : in out Column_Pool; N_Cols : out Column_Count);

   procedure Add_Column
     (Pool   : in out Column_Pool;
      N_Cols : in out Column_Count;
      Counts : Pattern_Counts;
      Cost   : Real := 1.0)
     with Pre => N_Cols < Max_Columns;

   procedure Init_Trivial_Patterns
     (Pool   : in out Column_Pool;
      N_Cols : out Column_Count;
      Widths : Vector;
      W      : Width_Value;
      N      : Item_Count)
     with Pre => N >= 1
            and then N <= Max_Items
            and then Widths'Length >= Natural (N)
            and then W >= 1;

   function Reduced_Cost
     (Counts : Pattern_Counts;
      Duals  : Vector;
      N      : Item_Count;
      Cost   : Real := 1.0) return Real
     with Pre => N <= Max_Items
            and then Duals'Length >= Natural (N),
          Global => null;
   --  For minimization: Cost − π · a. Improving column when < 0.

   ---------------------------------------------------------------------------
   -- Embedded dense LP (Bland tableau) — helpers exposed for tests
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

   function Extract_Primal
     (Tab : Tableau; N_Decision : Var_Count) return Vector
     with Pre => N_Decision <= Max_Vars, Global => null;

   function Solve_Tableau
     (Tab : in out Tableau;
      Cfg : Config := (others => <>)) return RMP_Result;

   ---------------------------------------------------------------------------
   -- Pricing (knapsack subproblem)
   ---------------------------------------------------------------------------

   function Price_Knapsack
     (Duals  : Vector;
      Widths : Vector;
      W      : Width_Value;
      N      : Item_Count;
      Cost   : Real := 1.0;
      Tol    : Real := Epsilon_Tol) return Pricing_Result
     with Pre => N >= 1
            and then N <= Max_Items
            and then Duals'Length >= Natural (N)
            and then Widths'Length >= Natural (N)
            and then W <= Max_Width
            and then Tol >= 0.0;
   --  Maximize π · a s.t. w · a ≤ W, a_i ≥ 0 integer (unbounded knapsack).
   --  Improving when Value > Cost (+ Tol).

   ---------------------------------------------------------------------------
   -- Restricted master problem
   ---------------------------------------------------------------------------

   function Solve_RMP
     (Pool   : Column_Pool;
      N_Cols : Column_Count;
      Demand : Vector;
      N      : Item_Count;
      Cfg    : Config := (others => <>)) return RMP_Result
     with Pre => N_Cols >= 1
            and then N >= 1
            and then N <= Max_Items
            and then N_Cols <= Max_Columns
            and then Demand'Length >= Natural (N);
   --  min Σ_j cost_j λ_j  s.t. Σ_j a_{ij} λ_j ≥ demand_i, λ ≥ 0.
   --  Implemented as max −cost via embedded Bland two-phase simplex.
   --  Duals π ≥ 0 of the cover rows are returned for pricing.

   ---------------------------------------------------------------------------
   -- Full delayed column generation (cutting stock)
   ---------------------------------------------------------------------------

   function Solve_Cutting_Stock
     (Widths : Vector;
      Demand : Vector;
      W      : Width_Value;
      Cfg    : Config := (others => <>)) return Result
     with Pre => Widths'Length = Demand'Length
            and then Widths'Length >= 1
            and then Widths'Length <= Max_Items
            and then W >= 1
            and then W <= Max_Width;
   --  Gilmore–Gomory style: trivial single-item patterns → iterate
   --  Solve_RMP + Price_Knapsack until no improving column (or caps).

end Delayed_Column_Generation;
