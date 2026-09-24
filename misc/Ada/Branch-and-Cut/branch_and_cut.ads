--  Branch_And_Cut — Ada 2023 educational package for Wikipedia
--  "Branch and cut": branch-and-bound over MILP with optional Gomory
--  fractional cuts at nodes, embedded dense Bland two-phase simplex
--  for LP relaxations. Caps n,m ≤ 10 (decision / original rows).
--  No with-clause dependency on sibling Ada-Simplex-Algorithm or
--  Ada-Cutting-Plane-Method (tableau / cut ideas only).
--  Primary source:
--  https://en.wikipedia.org/wiki/Branch_and_cut
--  Siblings: Ada-Cutting-Plane-Method; Ada-Simplex-Algorithm.

pragma Ada_2022;

package Branch_And_Cut
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Problem size caps (decision vars / original inequalities).
   Max_Problem_Vars : constant := 10;
   Max_Problem_Rows : constant := 10;

   --  Tableau room: original rows + bound rows + a few cut rows / slacks.
   Max_Constraints : constant := 40;
   Max_Vars        : constant := 48;

   subtype Constraint_Count is Natural range 0 .. Max_Constraints;
   subtype Var_Count        is Natural range 0 .. Max_Vars;
   subtype Constraint_Index is Positive range 1 .. Max_Constraints;
   subtype Var_Index        is Positive range 1 .. Max_Vars;
   subtype Problem_Var_Count is Natural range 0 .. Max_Problem_Vars;
   subtype Problem_Row_Count is Natural range 0 .. Max_Problem_Rows;

   type Matrix is
     array (Constraint_Index range <>, Var_Index range <>) of Real;
   type Vector is array (Positive range <>) of Real;

   --  Which decision variables must be integer (MILP / pure IP).
   type Integer_Flags is array (Positive range <>) of Boolean;

   type Status is (Optimal, Infeasible, Node_Limit);

   --  Max_Nodes         : branch-and-bound node budget
   --  Max_Pivots        : simplex pivots per node LP
   --  Max_Cuts_Per_Node : Gomory cuts attempted per node (0 = off)
   --  Tol / Integer_Tol : numeric / integrality tolerances
   --  Use_Best_Bound     : True = best-bound queue; False = FIFO
   type Config is record
      Max_Nodes         : Positive      := 200;
      Max_Pivots        : Positive      := 400;
      Max_Cuts_Per_Node : Natural       := 3;
      Tol               : Positive_Real := 1.0E-9;
      Integer_Tol       : Positive_Real := 1.0E-6;
      Use_Best_Bound     : Boolean       := False;
   end record;

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

   --  Cut in ≥ form: sum_j Coeff(j) * x_j ≥ RHS
   type Cut is record
      N_Cols : Var_Count := 0;
      Coeff  : Vector (1 .. Max_Vars) := [others => 0.0];
      RHS    : Real := 0.0;
      Valid  : Boolean := False;
   end record;

   --  Variable bounds for a B&B node (Lo default 0, Hi = No_Upper → open).
   No_Upper : constant Real := 1.0E6;

   type Result is record
      Stat      : Status := Infeasible;
      Objective : Real := 0.0;
      X         : Vector (1 .. Max_Vars) := [others => 0.0];
      N_Vars    : Var_Count := 0;
      Nodes     : Natural := 0;
      Cuts      : Natural := 0;
      Success   : Boolean := False;
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

   function Frac (X : Real) return Real
     with Global => null;

   function Is_Integer
     (X : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Is_Integer_Vector
     (X : Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Required_Are_Integer
     (X        : Vector;
      Required : Integer_Flags;
      Tol      : Real := Epsilon_Tol) return Boolean
     with Pre => X'Length = Required'Length and then Tol >= 0.0,
          Global => null;

   ---------------------------------------------------------------------------
   -- Embedded dense LP (Bland tableau) — helpers for tests
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
      Cfg : Config := (others => <>)) return Result;

   function Maximize_LP
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      Cfg : Config := (others => <>)) return Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_Constraints
            and then A'Length (2) + A'Length (1) <= Max_Vars;
   --  Solve max cᵀx s.t. Ax ≤ b, x ≥ 0 (embedded Bland two-phase).

   ---------------------------------------------------------------------------
   -- Gomory fractional cut (optional local cuts at B&B nodes)
   ---------------------------------------------------------------------------

   function First_Fractional_Row
     (Tab : Tableau; Tol : Real := Epsilon_Tol) return Natural
     with Global => null;

   function Gomory_Cut_From_Row
     (Tab : Tableau;
      Row : Positive;
      Tol : Real := Epsilon_Tol) return Cut
     with Pre => Row <= Max_Constraints, Global => null;

   procedure Add_Gomory_Cut
     (Tab : in out Tableau;
      C   : Cut)
     with Pre => C.Valid;

   ---------------------------------------------------------------------------
   -- Branching / bounds
   ---------------------------------------------------------------------------

   function Branch_Variable
     (X        : Vector;
      Required : Integer_Flags;
      Tol      : Real := Epsilon_Tol) return Natural
     with Pre => X'Length = Required'Length and then Tol >= 0.0,
          Global => null;
   --  Most-fractional integer-required index (frac closest to 0.5).
   --  Returns 0 if all required components are integer within Tol.

   procedure Apply_Bound
     (A_In        : Matrix;
      A_Out       : in out Matrix;
      B_In        : Vector;
      B_Out       : in out Vector;
      Lo, Hi      : Vector;
      M_In        : Constraint_Count;
      N_Dec       : Var_Count;
      M_Out       : out Constraint_Count)
     with Pre => N_Dec >= 1
            and then Lo'Length >= N_Dec
            and then Hi'Length >= N_Dec;
   --  Append x_j ≤ Hi_j and −x_j ≤ −Lo_j (when nontrivial) to (A_In,B_In)
   --  producing (A_Out,B_Out) with M_Out rows. A_Out/B_Out must be large
   --  enough (Max_Constraints × N_Dec). Does not copy objective.

   ---------------------------------------------------------------------------
   -- Branch-and-cut driver
   ---------------------------------------------------------------------------

   function Solve
     (A        : Matrix;
      B        : Vector;
      C        : Vector;
      Required : Integer_Flags;
      Cfg      : Config := (others => <>)) return Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then A'Length (2) = Required'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_Problem_Rows
            and then A'Length (2) <= Max_Problem_Vars;
   --  Maximize cᵀx s.t. Ax ≤ b, x ≥ 0, Required(j) ⇒ x_j ∈ ℤ.
   --  Branch-and-bound with optional Gomory cuts (Max_Cuts_Per_Node).

end Branch_And_Cut;
