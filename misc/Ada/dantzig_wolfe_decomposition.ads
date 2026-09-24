--  Dantzig_Wolfe_Decomposition — Ada 2023 educational package for Wikipedia
--  "Dantzig–Wolfe decomposition": block-angular LP reformulated as a master
--  over convex combinations of block extreme points, solved by column
--  generation (restricted master + per-block pricing). Embedded dense Bland
--  two-phase tableau simplex (sibling ideas only — no with-clause dependency
--  on Ada-Delayed-Column-Generation / Ada-Simplex-Algorithm).
--  Caps: blocks ≤ 3, block vars ≤ 2, coupling rows ≤ 4, columns ≤ 48.
--  Primary source:
--  https://en.wikipedia.org/wiki/Dantzig%E2%80%93Wolfe_decomposition
--  Sibling (README link only): Ada-Delayed-Column-Generation.

pragma Ada_2022;

package Dantzig_Wolfe_Decomposition
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Blocks            : constant := 3;
   Max_Block_Vars        : constant := 2;
   Max_Block_Constraints : constant := 4;
   Max_Coupling_Rows     : constant := 4;
   Max_Columns           : constant := 48;
   Max_Total_Vars        : constant := Max_Blocks * Max_Block_Vars;
   --  Tableau room: decision columns + slacks + artificials + Phase-I row.
   Max_Constraints : constant := 16;
   Max_Vars        : constant := 80;

   subtype Block_Count      is Natural range 0 .. Max_Blocks;
   subtype Block_Index      is Positive range 1 .. Max_Blocks;
   subtype Block_Var_Count  is Natural range 0 .. Max_Block_Vars;
   subtype Block_Var_Index  is Positive range 1 .. Max_Block_Vars;
   subtype Block_Cons_Count is Natural range 0 .. Max_Block_Constraints;
   subtype Coupling_Count   is Natural range 0 .. Max_Coupling_Rows;
   subtype Coupling_Index   is Positive range 1 .. Max_Coupling_Rows;
   subtype Column_Count     is Natural range 0 .. Max_Columns;
   subtype Column_Index     is Positive range 1 .. Max_Columns;
   subtype Constraint_Count is Natural range 0 .. Max_Constraints;
   subtype Var_Count        is Natural range 0 .. Max_Vars;
   subtype Constraint_Index is Positive range 1 .. Max_Constraints;
   subtype Var_Index        is Positive range 1 .. Max_Vars;
   subtype Total_Var_Count  is Natural range 0 .. Max_Total_Vars;

   type Matrix is
     array (Constraint_Index range <>, Var_Index range <>) of Real;
   type Vector is array (Positive range <>) of Real;

   --  Dense fixed-size storage for one block's local LP data.
   type Block_Cost_Array is array (Block_Var_Index) of Real;
   type Block_RHS_Array  is array (1 .. Max_Block_Constraints) of Real;
   type Block_B_Matrix is
     array (1 .. Max_Block_Constraints, Block_Var_Index) of Real;
   type Coupling_A_Matrix is
     array (Coupling_Index, Block_Var_Index) of Real;
   type Coupling_RHS_Array is array (Coupling_Index) of Real;

   type Block_Data is record
      N_Vars : Block_Var_Count := 0;
      N_Cons : Block_Cons_Count := 0;
      Cost   : Block_Cost_Array := [others => 0.0];
      B_Mat  : Block_B_Matrix := [others => [others => 0.0]];
      B_RHS  : Block_RHS_Array := [others => 0.0];
      --  Coupling columns for this block: (A_k)_{r,j}
      A_Coup : Coupling_A_Matrix := [others => [others => 0.0]];
   end record;

   type Block_Array is array (Block_Index) of Block_Data;

   --  Full block-angular LP: min Σ c_kᵀ x_k
   --    s.t. Σ_k A_k x_k ≤ a,  B_k x_k ≤ b_k,  x ≥ 0.
   type Problem is record
      N_Blocks    : Block_Count := 0;
      N_Coupling  : Coupling_Count := 0;
      Blocks      : Block_Array := [others => <>];
      Coupling_RHS : Coupling_RHS_Array := [others => 0.0];
   end record;

   --  One master column = proposal (extreme point / feasible point) of a block.
   type Proposal_X is array (Block_Var_Index) of Real;

   type Column is record
      Block_Id : Block_Index := 1;
      X        : Proposal_X := [others => 0.0];
      Cost     : Real := 0.0;           -- c_kᵀ x
      Coup     : Coupling_RHS_Array := [others => 0.0];  -- A_k x
      Valid    : Boolean := False;
   end record;

   type Column_Pool is array (Column_Index) of Column;

   type Status is
     (Optimal, Infeasible, Unbounded, Iteration_Limit, Column_Limit);

   type Config is record
      Max_Iters   : Positive      := 64;
      Max_Columns : Positive      := Dantzig_Wolfe_Decomposition.Max_Columns;
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

   type Pricing_Result is record
      X            : Proposal_X := [others => 0.0];
      Value        : Real := 0.0;       -- min (c − Aᵀπ)ᵀ x over block
      Reduced_Cost : Real := 0.0;      -- Value − σ  (improving if < 0)
      Improving    : Boolean := False;
      Feasible     : Boolean := False;
      Block_Id     : Block_Index := 1;
   end record;

   type Master_Result is record
      Stat          : Status := Infeasible;
      Objective     : Real := 0.0;
      Lambda        : Vector (1 .. Max_Columns) := [others => 0.0];
      Coupling_Dual : Vector (1 .. Max_Coupling_Rows) := [others => 0.0];
      Convexity_Dual : Vector (1 .. Max_Blocks) := [others => 0.0];
      N_Columns     : Column_Count := 0;
      N_Blocks      : Block_Count := 0;
      N_Coupling    : Coupling_Count := 0;
      N_Pivots      : Natural := 0;
      Success       : Boolean := False;
   end record;

   type Result is record
      Stat          : Status := Infeasible;
      Objective     : Real := 0.0;
      X             : Vector (1 .. Max_Total_Vars) := [others => 0.0];
      Lambda        : Vector (1 .. Max_Columns) := [others => 0.0];
      Coupling_Dual : Vector (1 .. Max_Coupling_Rows) := [others => 0.0];
      Convexity_Dual : Vector (1 .. Max_Blocks) := [others => 0.0];
      Pool          : Column_Pool := [others => <>];
      N_Columns     : Column_Count := 0;
      N_Blocks      : Block_Count := 0;
      N_Coupling    : Coupling_Count := 0;
      N_Total_Vars  : Total_Var_Count := 0;
      N_Iters       : Natural := 0;
      N_Pivots      : Natural := 0;
      Success       : Boolean := False;
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
   -- Column-pool / proposal helpers
   ---------------------------------------------------------------------------

   function Proposals_Equal
     (A, B : Proposal_X; N : Block_Var_Count; Tol : Real := Epsilon_Tol)
      return Boolean
     with Pre => N <= Max_Block_Vars and then Tol >= 0.0, Global => null;

   function Column_Exists
     (Pool     : Column_Pool;
      N_Cols   : Column_Count;
      Block_Id : Block_Index;
      X        : Proposal_X;
      N_Vars   : Block_Var_Count;
      Tol      : Real := Epsilon_Tol) return Boolean
     with Pre => N_Cols <= Max_Columns
            and then N_Vars <= Max_Block_Vars
            and then Tol >= 0.0,
          Global => null;

   procedure Clear_Pool (Pool : in out Column_Pool; N_Cols : out Column_Count);

   procedure Add_Column
     (Pool : in out Column_Pool;
      N_Cols : in out Column_Count;
      Col  : Column)
     with Pre => N_Cols < Max_Columns;

   function Make_Column
     (Prob     : Problem;
      Block_Id : Block_Index;
      X        : Proposal_X) return Column
     with Pre => Block_Id <= Prob.N_Blocks
            and then Prob.N_Blocks >= 1
            and then Prob.Blocks (Block_Id).N_Vars >= 1;

   function Proposal_Cost
     (Blk : Block_Data; X : Proposal_X) return Real
     with Global => null;

   function Proposal_Coupling
     (Blk : Block_Data; X : Proposal_X; N_Coup : Coupling_Count)
      return Coupling_RHS_Array
     with Pre => N_Coup <= Max_Coupling_Rows, Global => null;

   function Reduced_Cost
     (Col      : Column;
      Pi       : Vector;
      Sigma    : Real;
      N_Coup   : Coupling_Count) return Real
     with Pre => N_Coup <= Max_Coupling_Rows
            and then Pi'Length >= Natural (N_Coup),
          Global => null;
   --  For minimization (≤ coupling Lagrangian): cost + πᵀ (A x) − σ. Improving when < 0.

   procedure Init_Zero_Columns
     (Prob   : Problem;
      Pool   : in out Column_Pool;
      N_Cols : out Column_Count)
     with Pre => Prob.N_Blocks >= 1;

   function Total_Vars (Prob : Problem) return Total_Var_Count
     with Global => null;

   function Reconstruct_X
     (Prob   : Problem;
      Pool   : Column_Pool;
      N_Cols : Column_Count;
      Lambda : Vector) return Vector
     with Pre => N_Cols <= Max_Columns
            and then Lambda'Length >= Natural (N_Cols);

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
      Cfg : Config := (others => <>)) return Master_Result;

   ---------------------------------------------------------------------------
   -- Toy problem (known optimum −26)
   ---------------------------------------------------------------------------

   --  min −3 x1 − 4 x2 − 2 y1 − 5 y2
   --  s.t.  x1 + y1 ≤ 4,  x2 + y2 ≤ 3
   --        0 ≤ x1 ≤ 3, 0 ≤ x2 ≤ 2
   --        0 ≤ y1 ≤ 2, 0 ≤ y2 ≤ 3
   --  Optimum: (x1,x2,y1,y2) = (3,0,1,3), objective −26.
   function Make_Toy_Problem return Problem;

   function Toy_Optimum return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- Pricing / master / full DW
   ---------------------------------------------------------------------------

   function Price_Block
     (Prob     : Problem;
      Block_Id : Block_Index;
      Pi       : Vector;
      Sigma    : Real;
      Cfg      : Config := (others => <>)) return Pricing_Result
     with Pre => Block_Id <= Prob.N_Blocks
            and then Prob.N_Blocks >= 1
            and then Prob.Blocks (Block_Id).N_Vars >= 1
            and then Pi'Length >= Natural (Prob.N_Coupling);
   --  min (c_k + A_kᵀ π)ᵀ x over B_k x ≤ b_k, x ≥ 0.
   --  Reduced_Cost = Value − σ; improving when < −Tol.

   function Solve_Master
     (Prob   : Problem;
      Pool   : Column_Pool;
      N_Cols : Column_Count;
      Cfg    : Config := (others => <>)) return Master_Result
     with Pre => N_Cols >= 1
            and then N_Cols <= Max_Columns
            and then Prob.N_Blocks >= 1;
   --  Restricted master: convex combination of current proposals;
   --  coupling rows + per-block convexity equalities; Bland simplex.

   function Solve
     (Prob : Problem;
      Cfg  : Config := (others => <>)) return Result
     with Pre => Prob.N_Blocks >= 1
            and then Prob.N_Blocks <= Max_Blocks
            and then Prob.N_Coupling <= Max_Coupling_Rows;
   --  Full Dantzig–Wolfe: seed zero proposals → iterate master + pricing.

end Dantzig_Wolfe_Decomposition;
