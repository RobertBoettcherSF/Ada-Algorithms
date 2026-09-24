--  Davis_Putnam — Ada 2023 educational package for the classical
--  Davis–Putnam (DP, 1960) resolution-based propositional CNF-SAT
--  procedure: unit / one-literal rule, pure-literal rule, and
--  variable elimination by resolution (with educational blow-up caps).
--  Primary source:
--  https://en.wikipedia.org/wiki/Davis%E2%80%93Putnam_algorithm
--  Contrast: DPLL (1961) replaces resolution with splitting/backtracking.
--  Siblings (README links only — no package deps):
--  Ada-DPLL, Ada-Chaff (forthcoming).

pragma Ada_2022;

package Davis_Putnam
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / domain  (|Vars| ≤ 16, #clauses ≤ 64, clause len ≤ 8)
   -- Max_Resolvents bounds one elimination step's resolution blow-up.
   ---------------------------------------------------------------------------

   Max_Vars       : constant := 16;
   Max_Clauses    : constant := 64;
   Max_Clause_Len : constant := 8;
   Max_Resolvents : constant := 96;

   subtype Variable_Id    is Positive range 1 .. Max_Vars;
   subtype Variable_Count is Natural  range 0 .. Max_Vars;
   subtype Clause_Id      is Positive range 1 .. Max_Clauses;
   subtype Clause_Count   is Natural  range 0 .. Max_Clauses;
   subtype Clause_Length  is Natural  range 0 .. Max_Clause_Len;
   subtype Resolvent_Count is Natural range 0 .. Max_Resolvents;

   --  Signed literal: +v means variable v, −v means ¬v. Zero is unused.
   subtype Literal is Integer range -Max_Vars .. Max_Vars;

   type Literal_List is array (1 .. Max_Clause_Len) of Literal;

   type Clause is record
      Length : Clause_Length := 0;
      Lits   : Literal_List  := [others => 0];
   end record;

   type Clause_Array is array (1 .. Max_Clauses) of Clause;

   --  CNF formula over variables 1 .. Num_Vars (rewritten in place by DP).
   type Formula is record
      Num_Vars    : Variable_Count := 0;
      Num_Clauses : Clause_Count   := 0;
      Clauses     : Clause_Array   := [others => <>];
   end record;

   --  Classical DP decides sat/unsat; Failed = educational capacity abort
   --  (resolution blow-up or clause-length overflow). No model is returned —
   --  contrast Ada-DPLL, which returns a total assignment on success.
   type Status is (Satisfiable, Unsatisfiable, Failed);

   type Literal_Bag is array (1 .. Max_Vars) of Literal;
   type Pure_List is record
      Length : Variable_Count := 0;
      Lits   : Literal_Bag  := [others => 0];
   end record;

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

   function Clause_Contains (C : Clause; L : Literal) return Boolean
     with Global => null,
          Pre    => L /= 0;
   --  True iff C mentions literal L exactly.

   function Clause_Mentions_Var (C : Clause; V : Variable_Id) return Boolean
     with Global => null;
   --  True iff C mentions +V or −V.

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   procedure Clear (F : out Formula)
     with Global => null;
   --  Empty formula (0 vars, 0 clauses) — vacuously satisfiable.

   procedure Set_Num_Vars (F : in out Formula; N : Variable_Count)
     with Global => null;
   --  Set variable universe size; does not clear clauses.
   --  Raises Invalid_Argument if an existing literal refers past N.

   procedure Add_Clause (F : in out Formula; C : Clause)
     with Global => null;
   --  Append clause C (empty clause allowed → immediate unsat later).
   --  Raises Capacity_Exceeded at Max_Clauses.
   --  Raises Invalid_Argument on zero literal, duplicate |lit| in C,
   --  or literal whose |v| exceeds Num_Vars (auto-grows Num_Vars if
   --  literals fit Max_Vars).

   procedure Add_Clause_From_Literals
     (F    : in out Formula;
      Lits : Literal_List;
      Len  : Clause_Length)
     with Global => null;
   --  Convenience wrapper around Add_Clause.

   procedure From_DIMACS_Lite (F : out Formula; Text : String)
     with Global => null;
   --  Tiny DIMACS CNF subset: optional "p cnf <vars> <clauses>", then
   --  lines of integers ending in 0; "c" comments and blank lines ok.
   --  Raises Parse_Error / Capacity_Exceeded / Invalid_Argument.

   ---------------------------------------------------------------------------
   -- Clause / formula queries
   ---------------------------------------------------------------------------

   function Clause_Is_Empty (C : Clause) return Boolean
     with Global => null;

   function Has_Empty_Clause (F : Formula) return Boolean
     with Global => null;
   --  True iff some clause has length 0 (□) — unsatisfiable.

   function Is_Unit_Clause (C : Clause) return Boolean
     with Global => null;
   --  True iff C has exactly one literal.

   function Find_Unit_Literal (F : Formula) return Literal
     with Global => null;
   --  First unit-clause literal if any; else 0.

   function Find_Pure_Literal (F : Formula) return Literal
     with Global => null;
   --  First pure literal (occurs with only one polarity); else 0.

   procedure Collect_Pures (F : Formula; Pures : out Pure_List)
     with Global => null;
   --  All pure literals currently present in F.

   function Choose_Variable (F : Formula) return Variable_Count
     with Global => null;
   --  Smallest variable that still occurs in some clause; 0 if none.

   function Count_Pos_Occurrences (F : Formula; V : Variable_Id) return Natural
     with Global => null;

   function Count_Neg_Occurrences (F : Formula; V : Variable_Id) return Natural
     with Global => null;

   ---------------------------------------------------------------------------
   -- Classical Davis–Putnam steps (formula rewriting; educational)
   ---------------------------------------------------------------------------

   procedure Apply_Unit_Literal
     (F  : in out Formula;
      L  : Literal;
      Ok : out Boolean)
     with Global => null,
          Pre    => L /= 0;
   --  One-literal / unit rule for L: delete every clause containing L;
   --  delete ¬L from the remaining clauses. Ok=False if a resulting
   --  clause would somehow violate caps (should not happen educationally).

   procedure Unit_Propagate_Rule
     (F         : in out Formula;
      Got_Empty : out Boolean)
     with Global => null;
   --  Eager unit rule to fixpoint. Got_Empty if □ appears (UNSAT).

   procedure Apply_Pure_Literal (F : in out Formula; L : Literal)
     with Global => null,
          Pre    => L /= 0;
   --  Pure-literal rule: delete every clause containing L.

   procedure Pure_Literal_Rule
     (F       : in out Formula;
      Changed : out Boolean)
     with Global => null;
   --  Apply all current pure literals once (scan → apply). Changed if any.

   procedure Resolve_Clauses
     (C_Pos, C_Neg : Clause;
      V            : Variable_Id;
      Resolvent    : out Clause;
      Is_Tautology : out Boolean;
      Ok           : out Boolean)
     with Global => null;
   --  Classical resolvent of a clause containing +V with one containing −V:
   --  (C_Pos \ {+V}) ∪ (C_Neg \ {−V}). Tautology if both q and ¬q appear.
   --  Ok=False if length would exceed Max_Clause_Len.

   procedure Eliminate_Variable
     (F  : in out Formula;
      V  : Variable_Id;
      Ok : out Boolean)
     with Global => null;
   --  Resolve every clause with +V against every clause with −V; drop
   --  tautologies; remove all clauses mentioning V; append resolvents.
   --  Ok=False if resolvent count > Max_Resolvents, total clauses would
   --  exceed Max_Clauses, or a resolvent exceeds Max_Clause_Len
   --  (educational blow-up guard — Status Failed from Solve).

   function Solve (F : Formula) return Status
     with Global => null;
   --  Classical DP on a working copy: unit → pure → eliminate chosen var
   --  until no clauses (SAT), □ (UNSAT), or capacity abort (Failed).
   --  Does not mutate the caller's formula. No backtracking — contrast DPLL.

   function Is_Satisfiable (F : Formula) return Boolean
     with Global => null;
   --  True iff Solve (F) = Satisfiable. False on Unsatisfiable or Failed.

   ---------------------------------------------------------------------------
   -- Classic tiny examples (overlap DPLL toys where useful)
   ---------------------------------------------------------------------------

   procedure Build_Two_Clause_Sat (F : out Formula)
     with Global => null;
   --  (a ∨ b) ∧ (¬a ∨ b) — satisfiable.

   procedure Build_Contradictory_Units (F : out Formula)
     with Global => null;
   --  (a) ∧ (¬a) — unsatisfiable.

   procedure Build_Empty_Clause (F : out Formula)
     with Global => null;
   --  One empty clause — unsatisfiable.

   procedure Build_Empty_Formula (F : out Formula)
     with Global => null;
   --  No clauses — vacuously satisfiable.

   procedure Build_Small_3SAT_Sat (F : out Formula)
     with Global => null;
   --  Tiny satisfiable 3-SAT toy (3 vars, 4 clauses).

   procedure Build_Small_3SAT_Unsat (F : out Formula)
     with Global => null;
   --  Tiny unsatisfiable 3-SAT / pigeon toy.

   procedure Build_Pure_Only_Sat (F : out Formula)
     with Global => null;
   --  (a ∨ b) ∧ (a ∨ ¬b) — a is pure; satisfiable by pure rule alone.

   procedure Build_Blowup_Risk (F : out Formula)
     with Global => null;
   --  Dense occurrence pattern on a few vars to exercise blow-up guard
   --  (may Fail or still decide within caps — used by tests either way).

end Davis_Putnam;
