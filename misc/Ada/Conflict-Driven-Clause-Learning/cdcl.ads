with Ada.Containers.Vectors;

package CDCL is
   pragma Preelaborate;

   type Variable_Id is new Positive;
   type Literal is new Integer;
   subtype Clause_Index is Positive;

   type Truth_Value is (False, True, Unassigned);

   package Literal_Vectors is new Ada.Containers.Vectors (Positive, Literal);
   subtype Clause is Literal_Vectors.Vector;

   package Clause_Vectors is new Ada.Containers.Vectors (
      Index_Type   => Positive,
      Element_Type => Clause,
      "="          => Literal_Vectors."="
   );

   type Formula is record
      Variables_Count : Natural := 0;
      Clauses         : Clause_Vectors.Vector;
   end record;

   -- Exceptions
   Invalid_Formula : exception;
   Bad_Literal     : exception;

   -- API
   procedure Init_Formula (F : out Formula; Vars : Natural);
   procedure Add_Clause (F : in out Formula; C : Clause);

   type Solve_Status is (Satisfiable, Unsatisfiable, Unknown);
   type Assignment_Array is array (Variable_Id range <>) of Truth_Value;

   -- Variant 1: Basic CDCL
   function Solve_Basic (F : Formula; Assignments : out Assignment_Array) return Solve_Status
     with Pre => F.Variables_Count > 0 and then Assignments'Length = F.Variables_Count;

   -- Variant 2: CDCL with Restarts
   function Solve_With_Restarts (F : Formula; Assignments : out Assignment_Array; Restart_Interval : Positive) return Solve_Status
     with Pre => F.Variables_Count > 0 and then Assignments'Length = F.Variables_Count;

   -- Variant 3: CDCL with Clause Deletion
   function Solve_With_Clause_Deletion (F : Formula; Assignments : out Assignment_Array; Max_Learned : Positive) return Solve_Status
     with Pre => F.Variables_Count > 0 and then Assignments'Length = F.Variables_Count;

   -- Instrumented run (any variant) with per-run counters, so tests can
   -- show that restarts and clause deletion actually happen.
   type Solve_Statistics is record
      Conflicts    : Natural := 0;  -- conflicts met (the last one, at level 0, ends an UNSAT run)
      Learned      : Natural := 0;  -- learned clauses added
      Deleted      : Natural := 0;  -- learned clauses deleted
      Restarts     : Natural := 0;
      Peak_Learned : Natural := 0;  -- most learned clauses held at once (after deletion)
      Decisions     : Natural := 0;
      Conflict_Bound : Long_Long_Integer := 0;  -- T4 / T5 / T6 bound used (0 if none)
      Bound_Checked : Boolean := False;  -- a conflict bound applied to this run
   end record;

   procedure Solve_Instrumented
     (F                : Formula;
      Assignments      : out Assignment_Array;
      Use_Restarts     : Boolean;
      Restart_Interval : Positive;
      Use_Deletion     : Boolean;
      Max_Learned      : Positive;
      Status           : out Solve_Status;
      Stats            : out Solve_Statistics)
     with Pre => F.Variables_Count > 0 and then Assignments'Length = F.Variables_Count;

   --  Documented search policies. Solve_Traced reports them so that tests
   --  can check them; the trace is write-only for the solver and never
   --  changes a decision, so every variant above returns exactly the result
   --  of Solve_Traced with the matching options (Solve_Basic: no restarts,
   --  no deletion; Solve_With_Restarts: no deletion; Solve_With_Clause_
   --  Deletion: no restarts).
   --
   --  Decisions: the lowest-numbered unassigned variable is set to False.
   --  This is a property of THIS package's fixed decision rule, not of CDCL
   --  in general: standard CDCL solvers with VSIDS-style activity ordering
   --  or phase saving do not guarantee it and usually return some other
   --  model. With this rule, learned clauses implied by the formula and
   --  sound propagation, every SAT answer is the lexicographically least
   --  model (variable 1 most significant, False before True), whatever the
   --  restart and deletion options: if the answer M first differed from the least
   --  model M* at V, then M (V) = True was propagated at some level L; all
   --  decisions at levels <= L precede V's entry on the trail, so they are
   --  on variables below V (each decision takes the lowest unassigned
   --  variable) and agree with M*; they imply V, hence M* (V) = True.
   --
   --  Restarts (geometric schedule): with interval I, restart k (k = 1, 2,
   --  ...) happens at the conflict that brings the conflicts since the
   --  previous restart (or since the start) to t_k, where t_1 = I and
   --  t_(k+1) = t_k + (t_k + 1) / 2 (integer division, so the gap grows by
   --  at least 1 and by a factor >= 3/2 also from t = 1; until 2026-10-08
   --  it was t_k + t_k / 2, which stays 1 forever for interval 1 and gave
   --  no termination bound together with deletion). The conflict at
   --  decision level 0 that ends an UNSAT run is not counted. By the
   --  lexicographically-least-model result above, the schedule never
   --  changes an answer.
   --
   --  Clause deletion: every conflict except a final level-0 one learns one
   --  clause, whose learn ID is the conflict index. After learning, if more
   --  than Max_Learned learned clauses are held, the solver deletes the
   --  oldest held learned clause that is not the reason of a current
   --  assignment (at most one per conflict). The clause just learned is
   --  never deleted; if every older held clause is a reason, none is.
   --  Termination (checked at run time by every variant; a violation
   --  raises Termination_Bound_Exceeded, which a correct solver never does).
   --  N = number of variables. The bounds use only N and the options:
   --  (T1) Propagate: every pass that changes something assigns at least
   --       one variable, so a call makes at most N + 1 passes.
   --  (T2) Conflict analysis: every resolution step resolves on a distinct
   --       trail position (scanned downwards; the pivot leaves the clause
   --       and the reason's other literals lie earlier on the trail), so
   --       it takes at most Trail'Length steps.
   --  (T3) Between two conflicts (and before the first) there are at most
   --       N decisions: each assigns a fresh variable and nothing is
   --       unassigned without a conflict. So Decisions <= (Conflicts + 1) * N.
   --  (T4) Trail profile: (l_0, .., l_N), l_i = assignments at level i, sum
   --       <= N; there are V (N) = C (2N + 1, N) such tuples. A decision
   --       opens a level (new nonzero entry), a conflict backjumps to b and
   --       asserts the learned literal at b (entry b grows, later ones
   --       clear): both strictly increase the profile lexicographically.
   --       Without restarts: Conflicts <= V (N).
   --  (T5) Restarts (any interval): a period that ends in a restart
   --       has t_k conflicts, all strict profile increases, so t_k < V (N);
   --       hence Restarts <= R = #{k : t_k < V (N)} and Conflicts <=
   --       t_1 + .. + t_R + V (N) < 4 * V (N), as t_(k+1) >= 3/2 t_k gives
   --       t_1 + .. + t_R < 3 * V (N) and R <= 1 + log_1.5 V (N) < 128.
   --       (Deletion does not affect T4 / T5.)
   --  (T6) No deletion: a learned clause is never already held (it would
   --       have been unit before the decision of the conflict level, and
   --       Propagate runs to a fixpoint before each decision), and held
   --       clauses are distinct non-tautological clauses: Conflicts <= 3**N.
   --  T4 .. T6 are checked for N <= Max_Bounded_Vars, where
   --  every bound fits Long_Long_Integer (V (30) < 2.4E17, the T5 bound
   --  < 4 * V (30), 3**30 < 2.1E14); computing the T5 bound takes < 128
   --  steps (more raises Termination_Bound_Exceeded); above that they are not checked
   --  (Stats.Bound_Checked = False), never capped.
   Termination_Bound_Exceeded : exception;
   Max_Bounded_Vars : constant := 30;

   Max_Trace_Events : constant := 4_096;
   type Event_Count is range 0 .. Max_Trace_Events;
   subtype Event_Index is Event_Count range 1 .. Event_Count'Last;
   type Conflict_List is array (Event_Index) of Natural;

   type Deletion_Event is record
      At_Conflict : Natural := 0;  -- conflict index (= learn ID of the newest clause)
      Learn_ID    : Natural := 0;  -- learn ID of the deleted clause, 0 = every older one is a reason
      Skipped     : Natural := 0;  -- older held learned clauses kept because they are reasons
   end record;
   type Deletion_List is array (Event_Index) of Deletion_Event;

   --  One deletion event per conflict at which the learned limit was
   --  exceeded; events after the first Max_Trace_Events of a kind are not
   --  recorded and set Truncated.
   type Solve_Trace is record
      Restarts       : Event_Count := 0;
      Restart_At     : Conflict_List;  -- conflict index of each restart (1 .. Restarts set)
      Deletions      : Event_Count := 0;
      Deletion_Log   : Deletion_List;  -- 1 .. Deletions set
      Truncated      : Boolean := False;
   end record;

   procedure Solve_Traced
     (F                : Formula;
      Assignments      : out Assignment_Array;
      Use_Restarts     : Boolean;
      Restart_Interval : Positive;
      Use_Deletion     : Boolean;
      Max_Learned      : Positive;
      Status           : out Solve_Status;
      Stats            : out Solve_Statistics;
      Trace            : out Solve_Trace)
     with Pre => F.Variables_Count > 0 and then Assignments'Length = F.Variables_Count;

   -- Helper: to validate an assignment against a formula
   function Is_Satisfied (F : Formula; Assignments : Assignment_Array) return Boolean;

end CDCL;
