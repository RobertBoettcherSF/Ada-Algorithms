--  Brents_Algorithm — Ada 2023 educational package for Brent's
--  cycle-finding algorithm (Richard P. Brent, 1980). Detects a cycle
--  in the orbit
--
--      x_{0},  x_{i+1} = f(x_i)
--
--  of an endofunction on a finite set by exponential search over
--  powers of two, recovering the cycle length λ first, then the
--  tail length μ. The reachable subgraph is ρ-shaped.
--
--  Classroom model: a successor array Next (1 .. N) with values in
--  0 .. N.  0 is Null_Index — no successor (linked-list sentinel).
--  A total functional graph (every Next(I) in 1 .. N) always cycles.
--  A path that reaches 0 has no cycle.
--
--  Detect  = powers-of-two / teleport phase (finds λ).
--  Find_Cycle = Detect + μ recovery (full Brent).
--  Find_Cycle_Naive is an O(μ+λ)-space reference for tests.
--
--  Reference:
--    https://en.wikipedia.org/wiki/Cycle_detection#Brent's_algorithm
--    https://en.wikipedia.org/wiki/Cycle_detection
--  Sibling sheet (README only — do not `with`): Floyd's algorithm —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Brents_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Index model
   ---------------------------------------------------------------------------

   --  Soft classroom bound on |S|. Larger maps raise Invalid_Argument.
   Max_Nodes : constant Positive := 4096;

   --  0 is Null_Index (no successor / end of list). Live nodes are 1 .. N.
   subtype Node_Index is Natural range 0 .. Max_Nodes;
   Null_Index : constant Node_Index := 0;

   --  Next (I) is the image f(I). Component type is Natural so an
   --  out-of-range successor can be rejected as Invalid_Argument
   --  rather than Constraint_Error at aggregate construction.
   type Successor_Map is array (Positive range <>) of Natural;

   ---------------------------------------------------------------------------
   -- Result
   ---------------------------------------------------------------------------

   --  Has_Cycle      : tortoise and hare matched at a live node
   --  Meeting_Point  : that live node (hare when it matched the
   --                   teleported tortoise — some vertex of the cycle)
   --  Start_Node     : x_μ, first node of the cycle (Find_Cycle only)
   --  Mu             : tail length (index of x_μ along the path)
   --  Lambda         : cycle length λ (Detect already fills this —
   --                   Brent finds λ in the main loop)
   --  Detect fills Has_Cycle, Meeting_Point, and Lambda; Mu /
   --  Start_Node stay 0.  Find_Cycle fills every field.
   type Cycle_Result is record
      Has_Cycle     : Boolean    := False;
      Meeting_Point : Node_Index := Null_Index;
      Start_Node    : Node_Index := Null_Index;
      Mu            : Natural    := 0;
      Lambda        : Natural    := 0;
   end record;

   No_Cycle : constant Cycle_Result :=
     (Has_Cycle     => False,
      Meeting_Point => Null_Index,
      Start_Node    => Null_Index,
      Mu            => 0,
      Lambda        => 0);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when the map is empty, not 1-based, longer than Max_Nodes,
   --  a successor is > N, Start is outside 1 .. N, a builder is given a
   --  bad size / zero cycle, or a generic walk exceeds Max_Steps.

   ---------------------------------------------------------------------------
   -- Validation / stepping
   ---------------------------------------------------------------------------

   function Is_Valid_Map (Next : Successor_Map) return Boolean
     with Global => null;
   --  True iff Next'First = 1, 1 ≤ N ≤ Max_Nodes, and every Next(I)
   --  lies in 0 .. N.

   function Step
     (Next : Successor_Map;
      X    : Node_Index) return Node_Index
     with Global => null;
   --  f(X). Step (Next, 0) = 0. Raises Invalid_Argument on a bad map
   --  or when X is a live index outside 1 .. N.

   function Iterate
     (Next  : Successor_Map;
      Start : Positive;
      Steps : Natural) return Node_Index
     with Global => null;
   --  f^Steps (Start). Raises Invalid_Argument on a bad map / Start.

   ---------------------------------------------------------------------------
   -- Brent: detect (λ) and find (μ, λ)
   ---------------------------------------------------------------------------

   --  Algorithm sketch (Wikipedia / Brent 1980):
   --    power ← 1;  λ ← 1;  tortoise ← x0;  hare ← f(x0).
   --    While tortoise ≠ hare (and both live):
   --      if power = λ then teleport tortoise ← hare; power ← 2·power; λ ← 0
   --      hare ← f(hare);  λ ← λ + 1
   --    Meeting ⇒ λ is the exact cycle length.
   --    Advance hare λ steps from x0; then walk both → x_μ.
   --    Reaching Null_Index ⇒ the trajectory is a finite list (no cycle).

   function Detect
     (Next  : Successor_Map;
      Start : Positive) return Cycle_Result
     with Global => null;
   --  Phase 1 only. Has_Cycle, Meeting_Point, and Lambda; Mu / Start 0.

   function Find_Cycle
     (Next  : Successor_Map;
      Start : Positive) return Cycle_Result
     with Global => null;
   --  Full Brent: Has_Cycle, Meeting_Point, Start_Node, Mu, Lambda.

   function Has_Cycle
     (Next  : Successor_Map;
      Start : Positive) return Boolean
     with Global => null;
   --  Detect (Next, Start).Has_Cycle.

   function Cycle_Length
     (Next  : Successor_Map;
      Start : Positive) return Natural
     with Global => null;
   --  λ, or 0 when there is no cycle.

   function Cycle_Start
     (Next  : Successor_Map;
      Start : Positive) return Node_Index
     with Global => null;
   --  x_μ, or Null_Index when there is no cycle.

   function Tail_Length
     (Next  : Successor_Map;
      Start : Positive) return Natural
     with Global => null;
   --  μ, or 0 when there is no cycle (including a cycle at Start).

   function Is_On_Cycle
     (Next       : Successor_Map;
      Node       : Node_Index;
      Start_Node : Node_Index;
      Lambda     : Natural) return Boolean
     with Global => null;
   --  True iff Node is among the λ vertices of the cycle at Start_Node.

   ---------------------------------------------------------------------------
   -- Naive O(μ+λ)-space reference (tests / teaching contrast)
   ---------------------------------------------------------------------------

   function Find_Cycle_Naive
     (Next  : Successor_Map;
      Start : Positive) return Cycle_Result
     with Global => null;
   --  Record first-visit indices. First repeat is x_μ; gap is λ.
   --  Meeting_Point is set to Start_Node (the first repeat). Same
   --  μ / λ / Start_Node as Find_Cycle on a valid map.

   ---------------------------------------------------------------------------
   -- Black-box f (generic; cleaner in Ada than an access-to-function)
   ---------------------------------------------------------------------------

   generic
      with function F (X : Node_Index) return Node_Index;
   function Find_Cycle_On_Function
     (Start     : Node_Index;
      Max_Steps : Positive := Max_Nodes) return Cycle_Result;
   --  Same two phases on a callback f. Start = 0 → No_Cycle.
   --  F(X) = 0 ends the walk (no cycle). Exceeding Max_Steps without
   --  a meeting or a null raises Invalid_Argument.

   generic
      with function F (X : Node_Index) return Node_Index;
   function Detect_On_Function
     (Start     : Node_Index;
      Max_Steps : Positive := Max_Nodes) return Cycle_Result;
   --  Phase 1 only, same callback conventions as Find_Cycle_On_Function.

   ---------------------------------------------------------------------------
   -- Example-graph builders
   ---------------------------------------------------------------------------

   function Pure_Cycle (N : Positive) return Successor_Map
     with Global => null;
   --  1 → 2 → … → N → 1.  From 1: μ = 0, λ = N.

   function Rho_Graph
     (Tail  : Natural;
      Cycle : Positive) return Successor_Map
     with Global => null;
   --  Stem 1 → … → Tail → (Tail+1) and cycle
   --  (Tail+1) → … → (Tail+Cycle) → (Tail+1).
   --  Tail = 0 is a pure cycle of length Cycle.
   --  From 1: μ = Tail, λ = Cycle.  N = Tail + Cycle.

   function Path_To_Sink (N : Positive) return Successor_Map
     with Global => null;
   --  1 → 2 → … → N → 0.  Finite list; no cycle from any node.

   function Self_Loop_Chain (N : Positive) return Successor_Map
     with Global => null;
   --  1 → 2 → … → N → N.  From 1: μ = N − 1, λ = 1.

   function Two_Cycles return Successor_Map
     with Global => null;
   --  1 → 2 → 3 → 1  and  4 → 5 → 4;  node 6 → 0.
   --  Starts 1..3 see λ = 3; 4..5 see λ = 2; 6 sees no cycle.

   function Wikipedia_Example return Successor_Map
     with Global => null;
   --  1-based remapping of the Wikipedia S = {0..8} figure.
   --  Ada index I stores wiki node I − 1. Known edges from the
   --  article (start wiki 2 → 0 → 6 → 3 → 1 → 6, cycles {1,6,3}
   --  and {4}); remaining images filled so those two cycles remain.
   --  From Ada 3 (wiki 2): μ = 2, λ = 3, Start_Node = 7 (wiki 6).

end Brents_Algorithm;
