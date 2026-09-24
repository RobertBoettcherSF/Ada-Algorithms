--  AC_3 — Ada 2023 educational package for Mackworth's AC-3 arc-consistency
--  algorithm on binary CSPs (finite domains). Demos: map colouring,
--  N-queens pairwise pruning, alldiff via != network.
--  Primary source: https://en.wikipedia.org/wiki/AC-3_algorithm
--  Also: Constraint satisfaction problem, Arc consistency.
--  Siblings (README links only — no package deps):
--  Ada-Min-Conflicts; Constraint satisfaction survey forthcoming.

pragma Ada_2022;

package AC_3
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational caps)
   ---------------------------------------------------------------------------

   Max_Vars        : constant := 16;
   Max_Domain      : constant := 16;
   Max_Constraints : constant := 64;

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

   ---------------------------------------------------------------------------
   -- Binary constraints
   ---------------------------------------------------------------------------

   --  Not_Equal     : Left /= Right (pairwise inequality)
   --  Less_Than     : Left < Right
   --  Allowed_Pairs : explicit Allowed (v_left, v_right) table
   type Constraint_Kind is (Not_Equal, Less_Than, Allowed_Pairs);

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
   -- AC-3 result / arc worklist
   ---------------------------------------------------------------------------

   type AC3_Status is (Success, Domain_Wipeout);

   type AC3_Result is record
      Status         : AC3_Status := Success;
      Revisions      : Natural    := 0;
      Arcs_Processed : Natural    := 0;
   end record;

   type Arc is record
      Xi, Xj : Variable_Id := 1;
   end record;
   --  Directed arc (Xi, Xj): revise Dom(Xi) w.r.t. Dom(Xj).

   Max_Arcs : constant := Max_Constraints * 2;
   subtype Arc_Count is Natural range 0 .. Max_Arcs;
   type Arc_Queue is array (1 .. Max_Arcs) of Arc;

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
   --  All values False.

   function Full_Domain (Dmax : Dom_Size) return Domain
     with Pre => Dmax > 0, Global => null;
   --  Values 1 .. Dmax present; rest absent.

   function Domain_Size (D : Domain) return Dom_Size
     with Global => null;

   function Is_Empty (D : Domain) return Boolean
     with Global => null;

   function Contains (D : Domain; V : Value) return Boolean
     with Global => null;

   procedure Remove_Value (D : in out Domain; V : Value)
     with Global => null;

   procedure Init
     (Problem  : out CSP;
      Num_Vars : Var_Count;
      Dmax     : Dom_Size)
     with Pre => Num_Vars > 0 and then Dmax > 0, Global => null;
   --  Create CSP with Num_Vars variables, each domain = {1 .. Dmax}.

   procedure Set_Domain
     (Problem : in out CSP;
      Var     : Variable_Id;
      D       : Domain)
     with Pre => Var <= Problem.Num_Vars, Global => null;

   ---------------------------------------------------------------------------
   -- Constraint builders
   ---------------------------------------------------------------------------

   procedure Add_Not_Equal
     (Problem : in out CSP;
      A, B    : Variable_Id)
     with Pre =>
       A <= Problem.Num_Vars
       and then B <= Problem.Num_Vars
       and then A /= B,
       Global => null;

   procedure Add_Less_Than
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

   procedure Add_All_Different
     (Problem : in out CSP)
     with Pre => Problem.Num_Vars >= 2, Global => null;
   --  Pairwise Not_Equal for every unordered pair (alldiff network).

   ---------------------------------------------------------------------------
   -- Arc / revise / AC-3
   ---------------------------------------------------------------------------

   function Satisfies
     (C      : Constraint;
      Vi, Vj : Value) return Boolean
     with Global => null;
   --  Whether (Vi, Vj) is allowed under C for (C.Left, C.Right).

   function Has_Support
     (Problem : CSP;
      Xi, Xj  : Variable_Id;
      Vi      : Value) return Boolean
     with Pre =>
       Xi <= Problem.Num_Vars
       and then Xj <= Problem.Num_Vars
       and then Xi /= Xj,
       Global => null;
   --  Exists Vj in Dom(Xj) such that all constraints linking Xi and Xj
   --  allow the oriented pair with Xi's value first.

   function Revise
     (Problem : in out CSP;
      Xi, Xj  : Variable_Id) return Boolean
     with Pre =>
       Xi <= Problem.Num_Vars
       and then Xj <= Problem.Num_Vars
       and then Xi /= Xj,
       Global => null;
   --  Delete values from Dom(Xi) with no support in Dom(Xj).
   --  Returns True iff the domain changed.

   procedure Fill_Initial_Queue
     (Problem : CSP;
      Queue   : out Arc_Queue;
      Count   : out Arc_Count)
     with Global => null;
   --  Both directions for every binary constraint.

   procedure Make_Arc_Consistent
     (Problem : in out CSP;
      Result  : out AC3_Result)
     with Pre => Problem.Num_Vars > 0, Global => null;
   --  Alias for AC3.

   procedure AC3
     (Problem : in out CSP;
      Result  : out AC3_Result)
     with Pre => Problem.Num_Vars > 0, Global => null;
   --  Mackworth AC-3. On Domain_Wipeout some Dom(Xi) is empty.

   ---------------------------------------------------------------------------
   -- Educational demos / builders
   ---------------------------------------------------------------------------

   procedure Build_Australia_Map (Problem : out CSP)
     with Global => null;
   --  Tiny Australia-style map: WA, NT, SA, Q, NSW, V, T; 3 colours.
   --  Variables 1..7; domain {1,2,3}. Adjacent regions Not_Equal.

   procedure Build_Unsat_Triangle (Problem : out CSP)
     with Global => null;
   --  3 regions, complete K3, 2 colours → wipeout under AC-3.

   procedure Build_N_Queens_Binary
     (Problem : out CSP;
      N       : Positive)
     with Pre => N in 1 .. Max_Vars and then N <= Max_Domain, Global => null;
   --  One variable per row; domain = columns 1 .. N.
   --  Pairwise Allowed_Pairs: different columns and not same diagonal.

   procedure Build_Alldiff_Demo
     (Problem : out CSP;
      N       : Positive;
      Dmax    : Dom_Size)
     with Pre =>
       N in 2 .. Max_Vars and then Dmax > 0 and then Dmax <= Max_Domain,
       Global => null;
   --  N variables, domains {1 .. Dmax}, pairwise Not_Equal (alldiff).

end AC_3;
