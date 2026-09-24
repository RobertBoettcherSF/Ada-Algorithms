--  DPLL — Ada 2023 educational package for the classical
--  Davis–Putnam–Logemann–Loveland CNF-SAT algorithm:
--  unit propagation, pure-literal elimination, and branching
--  backtracking on tiny propositional formulae.
--  Primary source:
--  https://en.wikipedia.org/wiki/DPLL_algorithm
--  Also: Davis–Putnam algorithm (1960), CNF-SAT.
--  Siblings (README links only — no package deps):
--  Ada-Davis-Putnam (forthcoming), Ada-Chaff (forthcoming).

pragma Ada_2022;

package DPLL
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity / domain  (|Vars| ≤ 32, #clauses ≤ 128, clause len ≤ 8)
   ---------------------------------------------------------------------------

   Max_Vars       : constant := 32;
   Max_Clauses    : constant := 128;
   Max_Clause_Len : constant := 8;

   subtype Variable_Id    is Positive range 1 .. Max_Vars;
   subtype Variable_Count is Natural  range 0 .. Max_Vars;
   subtype Clause_Id      is Positive range 1 .. Max_Clauses;
   subtype Clause_Count   is Natural  range 0 .. Max_Clauses;
   subtype Clause_Length  is Natural  range 0 .. Max_Clause_Len;

   --  Signed literal: +v means variable v, −v means ¬v. Zero is unused.
   subtype Literal is Integer range -Max_Vars .. Max_Vars;

   type Literal_List is array (1 .. Max_Clause_Len) of Literal;

   type Clause is record
      Length : Clause_Length := 0;
      Lits   : Literal_List  := [others => 0];
   end record;

   type Clause_Array is array (1 .. Max_Clauses) of Clause;

   --  CNF formula over variables 1 .. Num_Vars.
   type Formula is record
      Num_Vars    : Variable_Count := 0;
      Num_Clauses : Clause_Count   := 0;
      Clauses     : Clause_Array   := [others => <>];
   end record;

   type Truth_Value is (Unassigned, Is_False, Is_True);

   type Assignment is array (Variable_Id) of Truth_Value;

   --  Partial or total model: Values (1 .. Num_Vars).
   type Model is record
      Num_Vars : Variable_Count := 0;
      Values   : Assignment     := [others => Unassigned];
   end record;

   type Sat_Status is (Satisfiable, Unsatisfiable);

   type Solve_Result is record
      Status : Sat_Status := Unsatisfiable;
      Result_Model : Model;
   end record;

   type Literal_Bag is array (1 .. Max_Vars) of Literal;
   type Pure_List is record
      Length : Variable_Count := 0;
      Lits   : Literal_Bag  := [others => 0];
   end record;

   --  Well-formed clause: no zero literals in 1 .. Length (SPARK L2 bar).
   function Valid_Clause (C : Clause) return Boolean
     with Global => null,
          Ghost  => True;


   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;
   Parse_Error       : exception;

   ---------------------------------------------------------------------------
   -- Literal helpers
   ---------------------------------------------------------------------------

   function Var_Of (L : Literal) return Variable_Id
     with Global => null,
          Pre    => L /= 0;
   --  |L|.

   function Is_Positive (L : Literal) return Boolean
     with Global => null,
          Pre    => L /= 0;
   --  True iff L > 0.

   function Negate (L : Literal) return Literal
     with Global => null,
          Pre    => L /= 0;
   --  −L.

   function Make_Literal (V : Variable_Id; Positive_Pol : Boolean) return Literal
     with Global => null;
   --  +V if Positive_Pol, else −V.

   function Lit_Is_True (L : Literal; A : Assignment) return Boolean
     with Global => null,
          Pre    => L /= 0;
   --  True iff L is satisfied under A (assigned accordingly).

   function Lit_Is_False (L : Literal; A : Assignment) return Boolean
     with Global => null,
          Pre    => L /= 0;
   --  True iff L is falsified under A.

   function Lit_Is_Unassigned (L : Literal; A : Assignment) return Boolean
     with Global => null,
          Pre    => L /= 0;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   procedure Clear (F : out Formula)
     with Global => null;
   --  Empty formula (0 vars, 0 clauses) — vacuously satisfiable.

   procedure Set_Num_Vars (F : in out Formula; N : Variable_Count)
     with Global => null,
          SPARK_Mode => Off;
   --  Set variable universe size; does not clear clauses.
   --  Raises Invalid_Argument if an existing literal refers past N.

   procedure Add_Clause (F : in out Formula; C : Clause)
     with Global => null,
          SPARK_Mode => Off;
   --  Append clause C (empty clause allowed → immediate unsat later).
   --  Raises Capacity_Exceeded at Max_Clauses.
   --  Raises Invalid_Argument on zero literal, duplicate |lit| in C,
   --  or literal whose |v| exceeds Num_Vars (auto-grows Num_Vars if 0
   --  vars were set and literals fit Max_Vars).

   procedure Add_Clause_From_Literals
     (F    : in out Formula;
      Lits : Literal_List;
      Len  : Clause_Length)
     with Global => null,
          SPARK_Mode => Off;
   --  Convenience wrapper around Add_Clause.

   procedure From_DIMACS_Lite (F : out Formula; Text : String)
     with Global => null,
          SPARK_Mode => Off;
   --  Tiny DIMACS CNF subset: optional "p cnf <vars> <clauses>", then
   --  lines of integers ending in 0; "c" comments and blank lines ok.
   --  Raises Parse_Error / Capacity_Exceeded / Invalid_Argument.

   ---------------------------------------------------------------------------
   -- Clause / formula queries
   ---------------------------------------------------------------------------

   function Clause_Is_Empty (C : Clause) return Boolean
     with Global => null;

   function Clause_Is_Satisfied (C : Clause; A : Assignment) return Boolean
     with Global => null;
   --  True iff some literal of C is true under A.

   function Clause_Is_Conflict (C : Clause; A : Assignment) return Boolean
     with Global => null;
   --  True iff every literal is false (includes empty clause).

   function Unit_Literal (C : Clause; A : Assignment) return Literal
     with Global => null;
   --  The unique unassigned literal if C is a unit under A; else 0.

   function Has_Empty_Clause (F : Formula) return Boolean
     with Global => null;

   function All_Clauses_Satisfied (F : Formula; A : Assignment) return Boolean
     with Global => null;

   function Formula_Has_Conflict (F : Formula; A : Assignment) return Boolean
     with Global => null;

   function Model_Satisfies (F : Formula; M : Model) return Boolean
     with Global => null;
   --  True iff every clause is satisfied and all used vars are assigned.

   ---------------------------------------------------------------------------
   -- Classical DPLL steps (educational; exposed for tests)
   ---------------------------------------------------------------------------

   procedure Assign_Literal
     (A   : in out Assignment;
      L   : Literal;
      Ok  : out Boolean)
     with Global => null,
          Pre    => L /= 0;
   --  Force L true. Ok=False on conflicting re-assignment.

   procedure Unit_Propagate
     (F        : Formula;
      A        : in out Assignment;
      Conflict : out Boolean)
     with Global => null;
   --  Eager unit propagation to fixpoint. Conflict if empty/conflict clause.

   procedure Pure_Literals
     (F     : Formula;
      A     : Assignment;
      Pures : out Pure_List)
     with Global => null,
          SPARK_Mode => Off;
   --  Literals that appear with only one polarity among still-active
   --  (unsatisfied) clauses; only for currently unassigned variables.

   procedure Eliminate_Pures
     (F        : Formula;
      A        : in out Assignment;
      Conflict : out Boolean)
     with Global => null,
          SPARK_Mode => Off;
   --  Assign all current pure literals (then optional unit cascade).

   function Choose_Variable (F : Formula; A : Assignment) return Variable_Count
     with Global => null,
          SPARK_Mode => Off;
   --  Smallest unassigned variable that still occurs in an unsatisfied
   --  clause; 0 if none (formula satisfied or no open vars).

   function Solve (F : Formula) return Solve_Result
     with Global => null,
          SPARK_Mode => Off;
   --  Classical DPLL: unit → pure → branch true/false with backtrack.
   --  Returns Satisfiable with a total model on used vars, or Unsatisfiable.

   function Is_Satisfiable (F : Formula) return Boolean
     with Global => null,
          SPARK_Mode => Off;

   ---------------------------------------------------------------------------
   -- Classic tiny examples
   ---------------------------------------------------------------------------

   procedure Build_Two_Clause_Sat (F : out Formula)
     with Global => null,
          SPARK_Mode => Off;
   --  (a ∨ b) ∧ (¬a ∨ b) — satisfiable; forces b.

   procedure Build_Contradictory_Units (F : out Formula)
     with Global => null,
          SPARK_Mode => Off;
   --  (a) ∧ (¬a) — unsatisfiable.

   procedure Build_Empty_Clause (F : out Formula)
     with Global => null,
          SPARK_Mode => Off;
   --  One empty clause — unsatisfiable.

   procedure Build_Empty_Formula (F : out Formula)
     with Global => null,
          SPARK_Mode => Off;
   --  No clauses — vacuously satisfiable.

   procedure Build_Small_3SAT_Sat (F : out Formula)
     with Global => null,
          SPARK_Mode => Off;
   --  Tiny satisfiable 3-SAT toy (3 vars, 4 clauses).

   procedure Build_Small_3SAT_Unsat (F : out Formula)
     with Global => null,
          SPARK_Mode => Off;
   --  Tiny unsatisfiable 3-SAT / pigeon toy.

end DPLL;
