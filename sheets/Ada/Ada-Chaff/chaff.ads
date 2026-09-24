--  Chaff — Ada 2023 educational package for Chaff-style SAT engineering:
--  two-watched-literals BCP and a VSIDS activity sketch on a small
--  DPLL-family search (chronological backtrack; full CDCL learning
--  documented as forthcoming).
--  Primary sources:
--  Moskewicz et al., Chaff: Engineering an Efficient SAT Solver (DAC 2001);
--  https://en.wikipedia.org/wiki/Chaff_algorithm
--  Siblings (README links only — no package deps):
--  Ada-DPLL, Ada-Davis-Putnam.

pragma Ada_2022;

package Chaff
  with SPARK_Mode => Off
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
      Status       : Sat_Status := Unsatisfiable;
      Result_Model : Model;
   end record;

   --  Activity scores for VSIDS (educational Float sketch).
   type Activity_Array is array (Variable_Id) of Float;

   --  Two watch indices into a clause's Lits (1 .. Length). Zero = unused.
   type Watch_Pair is record
      W1 : Clause_Length := 0;
      W2 : Clause_Length := 0;
   end record;

   type Watch_Pair_Array is array (1 .. Max_Clauses) of Watch_Pair;

   --  Literal slot index in [1 .. 2*Max_Vars]: +v → 2v−1, −v → 2v.
   subtype Lit_Slot is Positive range 1 .. 2 * Max_Vars;

   type Clause_Ref_List is array (1 .. Max_Clauses) of Clause_Id;

   type Watch_Bucket is record
      Length : Clause_Count   := 0;
      Refs   : Clause_Ref_List := [others => 1];
   end record;

   type Watch_Bucket_Array is array (Lit_Slot) of Watch_Bucket;

   subtype Trail_Index is Natural range 0 .. Max_Vars;

   type Trail_Array is array (1 .. Max_Vars) of Literal;

   --  Solver scratch: watches, VSIDS activities, BCP trail / queue.
   type Solver_State is record
      Watches       : Watch_Pair_Array   := [others => <>];
      Buckets       : Watch_Bucket_Array := [others => <>];
      Activities    : Activity_Array     := [others => 0.0];
      Trail         : Trail_Array        := [others => 0];
      Trail_Len     : Trail_Index        := 0;
      Queue_Head    : Trail_Index        := 1;
      Initialized   : Boolean            := False;
      Decay_Countdown : Natural          := 0;
   end record;

   Bump_Amount     : constant Float   := 1.0;
   Decay_Factor    : constant Float   := 0.95;
   Decay_Interval  : constant Natural := 32;
   --  After this many bumps, Decay_Activities is applied inside Bump when
   --  using the auto-decay path; tests may call Decay_Activities directly.

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;
   Parse_Error       : exception;
   Not_Initialized   : exception;

   ---------------------------------------------------------------------------
   -- Literal helpers
   ---------------------------------------------------------------------------

   function Var_Of (L : Literal) return Variable_Id
     with Global => null,
          Pre    => L /= 0;

   function Is_Positive (L : Literal) return Boolean
     with Global => null,
          Pre    => L /= 0;

   function Negate (L : Literal) return Literal
     with Global => null,
          Pre    => L /= 0;

   function Make_Literal (V : Variable_Id; Positive_Pol : Boolean) return Literal
     with Global => null;

   function Lit_Is_True (L : Literal; A : Assignment) return Boolean
     with Global => null,
          Pre    => L /= 0;

   function Lit_Is_False (L : Literal; A : Assignment) return Boolean
     with Global => null,
          Pre    => L /= 0;

   function Lit_Is_Unassigned (L : Literal; A : Assignment) return Boolean
     with Global => null,
          Pre    => L /= 0;

   function Slot_Of (L : Literal) return Lit_Slot
     with Global => null,
          Pre    => L /= 0;
   --  Watch-bucket index for literal L.

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   procedure Clear (F : out Formula)
     with Global => null;

   procedure Set_Num_Vars (F : in out Formula; N : Variable_Count)
     with Global => null;

   procedure Add_Clause (F : in out Formula; C : Clause)
     with Global => null;

   procedure Add_Clause_From_Literals
     (F    : in out Formula;
      Lits : Literal_List;
      Len  : Clause_Length)
     with Global => null;

   procedure From_DIMACS_Lite (F : out Formula; Text : String)
     with Global => null;

   ---------------------------------------------------------------------------
   -- Clause / formula queries
   ---------------------------------------------------------------------------

   function Clause_Is_Empty (C : Clause) return Boolean
     with Global => null;

   function Clause_Is_Satisfied (C : Clause; A : Assignment) return Boolean
     with Global => null;

   function Clause_Is_Conflict (C : Clause; A : Assignment) return Boolean
     with Global => null;

   function Unit_Literal (C : Clause; A : Assignment) return Literal
     with Global => null;

   function Has_Empty_Clause (F : Formula) return Boolean
     with Global => null;

   function All_Clauses_Satisfied (F : Formula; A : Assignment) return Boolean
     with Global => null;

   function Formula_Has_Conflict (F : Formula; A : Assignment) return Boolean
     with Global => null;

   function Model_Satisfies (F : Formula; M : Model) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Watched literals + VSIDS primitives (educational; exposed for tests)
   ---------------------------------------------------------------------------

   procedure Init_Watches (F : Formula; S : out Solver_State)
     with Global => null;
   --  Build two watches per clause (len≥2), unary watch, empty→conflict
   --  flag via Has_Empty_Clause; clear activities and trail. Raises
   --  Invalid_Argument if F has no Num_Vars and clauses refer past Max.

   function Get_Watch_Pair
     (S : Solver_State; C : Clause_Id) return Watch_Pair
     with Global => null;

   function Watches_Invariant
     (F : Formula; S : Solver_State) return Boolean
     with Global => null;
   --  Educational check: each non-empty clause has valid distinct watches
   --  (or a single watch for unit clauses), and each watched literal's
   --  bucket contains the clause.

   procedure Enqueue
     (A        : in out Assignment;
      S        : in out Solver_State;
      L        : Literal;
      Conflict : in out Boolean)
     with Global => null;
   --  Force L true on the trail. Sets Conflict on opposing assignment.
   --  Raises Not_Initialized if watches were never built.

   procedure Propagate
     (F        : Formula;
      A        : in out Assignment;
      S        : in out Solver_State;
      Conflict : out Boolean)
     with Global => null;
   --  Two-watched-literal BCP: drain S.Trail from Queue_Head. On falsified
   --  watched literal, re-watch or detect unit/conflict.

   procedure Bump_Activity
     (S : in out Solver_State;
      V : Variable_Id)
     with Global => null;
   --  Activities(V) := Activities(V) + Bump_Amount; may auto-decay.

   procedure Bump_Clause_Activities
     (F : Formula;
      S : in out Solver_State;
      C : Clause_Id)
     with Global => null;
   --  Bump every variable appearing in clause C (conflict / learned stub).

   procedure Decay_Activities (S : in out Solver_State)
     with Global => null;
   --  Multiply all Activities by Decay_Factor.

   function Get_Activity
     (S : Solver_State; V : Variable_Id) return Float
     with Global => null;

   function Choose_VSIDS
     (F : Formula;
      A : Assignment;
      S : Solver_State) return Variable_Count
     with Global => null;
   --  Unassigned variable of maximum activity; tie-break lowest index.
   --  0 if none remain.

   function Choose_Variable
     (F : Formula;
      A : Assignment;
      S : Solver_State) return Variable_Count
     with Global => null;
   --  Alias of Choose_VSIDS for DPLL-style naming in Solve.

   procedure Assign_Literal
     (A  : in out Assignment;
      L  : Literal;
      Ok : out Boolean)
     with Global => null;
   --  Force L true without trail (simple helper). Ok=False on conflict.

   function Solve (F : Formula) return Solve_Result
     with Global => null;
   --  Watched BCP + VSIDS branching + chronological backtrack.
   --  Full CDCL clause learning / non-chronological backjump is forthcoming.

   function Is_Satisfiable (F : Formula) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Classic tiny examples
   ---------------------------------------------------------------------------

   procedure Build_Two_Clause_Sat (F : out Formula)
     with Global => null;
   --  (a ∨ b) ∧ (¬a ∨ b) — satisfiable; forces b.

   procedure Build_Contradictory_Units (F : out Formula)
     with Global => null;
   --  (a) ∧ (¬a) — unsatisfiable.

   procedure Build_Empty_Clause (F : out Formula)
     with Global => null;

   procedure Build_Empty_Formula (F : out Formula)
     with Global => null;

   procedure Build_Small_3SAT_Sat (F : out Formula)
     with Global => null;

   procedure Build_Small_3SAT_Unsat (F : out Formula)
     with Global => null;

   procedure Build_Chain_Units (F : out Formula)
     with Global => null;
   --  (a) ∧ (¬a ∨ b) ∧ (¬b ∨ c) — forces a,b,c via watched BCP.

end Chaff;
