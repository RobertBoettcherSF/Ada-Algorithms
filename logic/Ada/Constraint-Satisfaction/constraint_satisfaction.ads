--  Constraint_Satisfaction — Ada 2023 educational SURVEY package for
--  constraint satisfaction problems (CSPs): finite domains, binary
--  constraints, backtracking search, forward checking, a tiny embedded
--  arc-consistency (Revise) filter, and taxonomy flags for min-conflicts
--  / SAT encoding (sibling packages; not build deps).
--  Primary source: https://en.wikipedia.org/wiki/Constraint_satisfaction_problem
--  Also: AC-3 algorithm, Min-conflicts algorithm, DPLL algorithm.
--  Siblings (README links only — no package deps):
--  Ada-AC-3, Ada-Min-Conflicts, Ada-DPLL, Ada-Difference-Map.

pragma Ada_2022;

package Constraint_Satisfaction
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational caps)
   ---------------------------------------------------------------------------

   Max_Vars        : constant := 12;
   Max_Domain      : constant := 8;
   Max_Constraints : constant := 32;

   subtype Variable_Id is Positive range 1 .. Max_Vars;
   subtype Value       is Positive range 1 .. Max_Domain;
   subtype Var_Count   is Natural range 0 .. Max_Vars;
   subtype Dom_Size    is Natural range 0 .. Max_Domain;
   subtype Cons_Count  is Natural range 0 .. Max_Constraints;
   subtype Cons_Index  is Positive range 1 .. Max_Constraints;

   ---------------------------------------------------------------------------
   -- Domains: membership bit-vector over 1 .. Max_Domain
   ---------------------------------------------------------------------------

   type Domain is array (Value) of Boolean
     with Default_Component_Value => False;

   type Domain_Array is array (Variable_Id) of Domain;

   --  Partial / complete assignment: 0 = unassigned; else value in 1 .. Dmax.
   type Assignment is array (Variable_Id) of Natural
     with Default_Component_Value => 0;

   ---------------------------------------------------------------------------
   -- Binary constraints
   ---------------------------------------------------------------------------

   --  Not_Equal     : Left /= Right
   --  Allowed_Pairs : explicit Allowed (v_left, v_right) table
   type Constraint_Kind is (Not_Equal, Allowed_Pairs);

   type Allowed_Matrix is array (Value, Value) of Boolean
     with Default_Component_Value => False;

   type Constraint is record
      Left, Right : Variable_Id     := 1;
      Kind        : Constraint_Kind := Not_Equal;
      Allowed     : Allowed_Matrix  := [others => [others => False]];
   end record;

   type Constraint_List is array (Cons_Index) of Constraint;

   ---------------------------------------------------------------------------
   -- CSP instance
   ---------------------------------------------------------------------------

   type CSP is record
      Num_Vars        : Var_Count  := 0;
      Num_Constraints : Cons_Count := 0;
      Domains         : Domain_Array := [others => [others => False]];
      Constraints     : Constraint_List :=
        [others => (1, 1, Not_Equal, [others => [others => False]])];
   end record;

   ---------------------------------------------------------------------------
   -- Search / filter results
   ---------------------------------------------------------------------------

   type Solve_Status is (Solved, Unsatisfiable, Incomplete);

   type Solve_Result is record
      Status     : Solve_Status := Incomplete;
      Solution   : Assignment   := [others => 0];
      Nodes      : Natural      := 0;
      Backtracks : Natural      := 0;
   end record;

   type Count_Result is record
      Count      : Natural := 0;
      Nodes      : Natural := 0;
      Backtracks : Natural := 0;
   end record;

   type AC_Status is (Success, Domain_Wipeout);

   type AC_Result is record
      Status    : AC_Status := Success;
      Revisions : Natural   := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Method taxonomy (Implemented vs Forthcoming)
   ---------------------------------------------------------------------------

   type Method_Kind is
     (Backtracking,
      Forward_Checking,
      Arc_Consistency,
      Min_Conflicts_Local,
      SAT_Encoding);

   type Method_Info is record
      Kind        : Method_Kind;
      Implemented : Boolean;
      Forthcoming : Boolean;
      --  Family: Search / Inference / Local_Search / Encoding
      Family      : String (1 .. 16) := "                ";
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Domain helpers
   ---------------------------------------------------------------------------

   function Empty_Domain return Domain
     with Global => null;

   function Full_Domain (Dmax : Dom_Size) return Domain
     with Pre => Dmax > 0, Global => null;

   function Domain_Size (D : Domain) return Dom_Size
     with Global => null;

   function Is_Empty (D : Domain) return Boolean
     with Global => null;

   function Contains (D : Domain; V : Value) return Boolean
     with Global => null;

   procedure Remove_Value (D : in out Domain; V : Value)
     with Global => null;

   function First_Value (D : Domain) return Natural
     with Global => null;
   --  Smallest value in D, or 0 if empty.

   ---------------------------------------------------------------------------
   -- CSP builders
   ---------------------------------------------------------------------------

   procedure Init
     (Problem  : out CSP;
      Num_Vars : Var_Count;
      Dmax     : Dom_Size)
     with Pre => Num_Vars > 0 and then Dmax > 0, Global => null;

   procedure Set_Domain
     (Problem : in out CSP;
      Var     : Variable_Id;
      D       : Domain)
     with Pre => Var <= Problem.Num_Vars, Global => null;

   procedure Add_Not_Equal
     (Problem : in out CSP;
      A, B    : Variable_Id)
     with Pre =>
       A <= Problem.Num_Vars
       and then B <= Problem.Num_Vars
       and then A /= B,
       Global => null;

   procedure Add_Allowed_Pairs
     (Problem : in out CSP;
      A, B    : Variable_Id;
      Allowed : Allowed_Matrix)
     with Pre =>
       A <= Problem.Num_Vars
       and then B <= Problem.Num_Vars
       and then A /= B,
       Global => null;

   procedure Add_All_Different (Problem : in out CSP)
     with Pre => Problem.Num_Vars >= 2, Global => null;

   function Satisfies
     (C      : Constraint;
      Vi, Vj : Value) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Consistency of a partial assignment
   ---------------------------------------------------------------------------

   function Is_Assigned (A : Assignment; Var : Variable_Id) return Boolean
     with Global => null;

   function Is_Consistent
     (Problem : CSP;
      A       : Assignment) return Boolean
     with Pre => Problem.Num_Vars > 0, Global => null;
   --  True iff every constraint whose both ends are assigned is satisfied.
   --  Unassigned variables are ignored (partial-assignment check).

   function Is_Complete
     (Problem : CSP;
      A       : Assignment) return Boolean
     with Pre => Problem.Num_Vars > 0, Global => null;

   function Is_Solution
     (Problem : CSP;
      A       : Assignment) return Boolean
     with Pre => Problem.Num_Vars > 0, Global => null;

   ---------------------------------------------------------------------------
   -- Variable ordering (MRV optional)
   ---------------------------------------------------------------------------

   function Select_Unassigned
     (Problem : CSP;
      A       : Assignment;
      Use_MRV : Boolean) return Natural
     with Pre => Problem.Num_Vars > 0, Global => null;
   --  Next unassigned variable id, or 0 if none.
   --  If Use_MRV: choose variable with fewest remaining domain values
   --  consistent with the current assignment (minimum remaining values).

   ---------------------------------------------------------------------------
   -- Backtracking search
   ---------------------------------------------------------------------------

   procedure Backtrack_Solve
     (Problem : CSP;
      Result  : out Solve_Result;
      Use_MRV : Boolean := False)
     with Pre => Problem.Num_Vars > 0, Global => null;
   --  Depth-first backtracking; optional MRV variable ordering.

   procedure Count_Solutions
     (Problem : CSP;
      Result  : out Count_Result;
      Use_MRV : Boolean := False)
     with Pre => Problem.Num_Vars > 0, Global => null;
   --  Enumerate all solutions (same search skeleton).

   ---------------------------------------------------------------------------
   -- Forward checking (sketch)
   ---------------------------------------------------------------------------

   procedure Forward_Check_Solve
     (Problem : CSP;
      Result  : out Solve_Result;
      Use_MRV : Boolean := False)
     with Pre => Problem.Num_Vars > 0, Global => null;
   --  Backtracking + forward checking: after assigning X=v, remove
   --  unsupported values from future (unassigned) neighbours; restore
   --  on backtrack. Educational sketch (binary constraints only).

   ---------------------------------------------------------------------------
   -- Tiny embedded arc consistency (Revise filter; no ac_3 package dep)
   ---------------------------------------------------------------------------

   function Has_Support
     (Problem : CSP;
      Xi, Xj  : Variable_Id;
      Vi      : Value) return Boolean
     with Pre =>
       Xi <= Problem.Num_Vars
       and then Xj <= Problem.Num_Vars
       and then Xi /= Xj,
       Global => null;

   function Revise
     (Problem : in out CSP;
      Xi, Xj  : Variable_Id) return Boolean
     with Pre =>
       Xi <= Problem.Num_Vars
       and then Xj <= Problem.Num_Vars
       and then Xi /= Xj,
       Global => null;
   --  Drop unsupported values from Dom(Xi) w.r.t. Dom(Xj).
   --  Returns True iff the domain changed.

   procedure AC_Filter
     (Problem : in out CSP;
      Result  : out AC_Result)
     with Pre => Problem.Num_Vars > 0, Global => null;
   --  Minimal arc filter: revise both directions of every constraint
   --  once (not a full AC-3 worklist). Sibling Ada-AC-3 has Mackworth AC-3.

   ---------------------------------------------------------------------------
   -- Tiny min-conflicts step (embedded sketch; full solver in sibling)
   ---------------------------------------------------------------------------

   function Conflict_Count
     (Problem : CSP;
      A       : Assignment) return Natural
     with Pre =>
       Problem.Num_Vars > 0
       and then Is_Complete (Problem, A),
       Global => null;

   procedure Min_Conflicts_Step
     (Problem : CSP;
      A       : in out Assignment;
      Var     : Variable_Id;
      Changed : out Boolean)
     with Pre =>
       Problem.Num_Vars > 0
       and then Var <= Problem.Num_Vars
       and then Is_Complete (Problem, A),
       Global => null;
   --  Reassign Var to a value that minimises the number of conflicts
   --  (ties: smallest value). Educational one-variable repair step.

   ---------------------------------------------------------------------------
   -- Educational demos
   ---------------------------------------------------------------------------

   procedure Build_Map_Coloring
     (Problem : out CSP;
      Regions : Positive;
      Colors  : Dom_Size)
     with Pre =>
       Regions in 2 .. Max_Vars
       and then Colors > 0
       and then Colors <= Max_Domain,
       Global => null;
   --  Path graph R1—R2—…—R_Regions with Not_Equal on edges; domain 1..Colors.

   procedure Build_Australia_Map (Problem : out CSP)
     with Global => null;
   --  7 regions / 3 colours (WA,NT,SA,Q,NSW,V,T) Australia-style sketch.

   procedure Build_N_Queens
     (Problem : out CSP;
      N       : Positive)
     with Pre => N in 1 .. 5, Global => null;
   --  N-queens as binary CSP (N <= 5 educational). Row vars, col domains;
   --  Allowed_Pairs: different columns and not same diagonal.

   ---------------------------------------------------------------------------
   -- Taxonomy helpers
   ---------------------------------------------------------------------------

   function Classify (Kind : Method_Kind) return Method_Info
     with Global => null;

   function Method_Name (Kind : Method_Kind) return String
     with Global => null;

   function Implemented (Kind : Method_Kind) return Boolean
     with Global => null;

   function Forthcoming (Kind : Method_Kind) return Boolean
     with Global => null;

end Constraint_Satisfaction;
