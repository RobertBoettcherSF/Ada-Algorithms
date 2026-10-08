--  Floyds_Cycle_Finding_Algorithm — Ada/SPARK Level 4 educational package
--  for Floyd's tortoise-and-hare cycle-finding algorithm (Robert W. Floyd,
--  popularised by Knuth). Detects a cycle in the orbit
--
--      x_0,  x_{i+1} = f(x_i)
--
--  of an endofunction on a finite set, then recovers the tail length μ
--  and the cycle length λ. The reachable subgraph is ρ-shaped.
--
--  Classroom model: a successor array Next (1 .. N) with values in
--  0 .. N.  0 is Null_Index — no successor (linked-list sentinel).
--  A total functional graph (every Next(I) in 1 .. N) always cycles.
--  A path that reaches 0 has no cycle.
--
--  Detect     = tortoise / hare meeting (phase 1).
--  Find_Cycle = meeting + μ + λ (full Floyd).
--
--  SPARK port of Ada-Floyds-Cycle-Finding-Algorithm: hard bounds, no heap,
--  no exceptions, no generics — contracts replace Invalid_Argument.
--
--  Reference:
--    https://en.wikipedia.org/wiki/Floyd%27s_cycle-finding_algorithm
--    https://en.wikipedia.org/wiki/Cycle_detection

package Floyds_Cycle_Finding_Algorithm
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Index model (bounded for static allocation / Level 4 proof)
   ---------------------------------------------------------------------------

   --  Hard classroom bound on |S|. Smaller than the non-SPARK sibling so
   --  loop variants and array indexes stay within automated SMT reach.
   Max_N : constant Positive := 64;

   --  0 is Null_Index (no successor / end of list). Live nodes are 1 .. N.
   subtype Node_Index is Natural range 0 .. Max_N;
   Null_Index : constant Node_Index := 0;

   subtype Node_Id is Positive range 1 .. Max_N;
   subtype Node_Count is Positive range 1 .. Max_N;

   --  Next (I) is the image f(I). Values in 0 .. N (N = Next'Last).
   type Successor_Map is array (Node_Id range <>) of Node_Index;

   ---------------------------------------------------------------------------
   -- Result
   ---------------------------------------------------------------------------

   --  Has_Cycle      : tortoise and hare met at a live node
   --  Meeting_Point  : that live node (some vertex of the cycle)
   --  Start_Node     : x_μ, first node of the cycle (Find_Cycle only)
   --  Mu             : tail length (index of x_μ along the path)
   --  Lambda         : cycle length λ
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
   -- Validation / stepping
   ---------------------------------------------------------------------------

   function Is_Valid_Map (Next : Successor_Map) return Boolean
     with
       Global => null,
       Post   => Is_Valid_Map'Result =
         (Next'First = 1
          and then Next'Last in Node_Count
          and then (for all I in Next'Range => Next (I) <= Next'Last));
   --  True iff Next'First = 1, 1 ≤ N ≤ Max_N, and every Next(I) ∈ 0 .. N.

   function Step
     (Next : Successor_Map;
      X    : Node_Index) return Node_Index
     with
       Global => null,
       Pre    => Is_Valid_Map (Next)
                 and then (X = Null_Index or else X <= Next'Last),
       Post   => Step'Result <= Next'Last
                 and then (if X = Null_Index then Step'Result = Null_Index);
   --  f(X). Step (Next, 0) = 0.

   function Iterate
     (Next  : Successor_Map;
      Start : Node_Id;
      Steps : Natural) return Node_Index
     with
       Global => null,
       Pre    => Is_Valid_Map (Next)
                 and then Start <= Next'Last
                 and then Steps <= Max_N,
       Post   => Iterate'Result <= Next'Last;
   --  f^Steps (Start).

   ---------------------------------------------------------------------------
   -- Floyd: detect (phase 1) and find (μ, λ)
   ---------------------------------------------------------------------------

   --  Algorithm sketch (Wikipedia / Knuth):
   --    Tortoise ← f(x0),  Hare ← f(f(x0)).
   --    While both live and unequal: tortoise one step, hare two.
   --    Meeting ⇒ a cycle (x_ν = x_{2ν} for ν = kλ ≥ μ).
   --    Reset tortoise to x0; walk both one step at a time → x_μ.
   --    Freeze tortoise at x_μ; walk hare → λ.
   --    Reaching Null_Index ⇒ the trajectory is a finite list (no cycle).

   function Detect
     (Next  : Successor_Map;
      Start : Node_Id) return Cycle_Result
     with
       Global => null,
       Pre    => Is_Valid_Map (Next) and then Start <= Next'Last,
       Post   =>
         (if Detect'Result.Has_Cycle then
            Detect'Result.Meeting_Point in 1 .. Next'Last
            and then Detect'Result.Start_Node = Null_Index
            and then Detect'Result.Mu = 0
            and then Detect'Result.Lambda = 0
          else
            Detect'Result = No_Cycle);
   --  Phase 1 only. Has_Cycle and Meeting_Point; other fields 0.

   function Find_Cycle
     (Next  : Successor_Map;
      Start : Node_Id) return Cycle_Result
     with
       Global => null,
       Pre    => Is_Valid_Map (Next) and then Start <= Next'Last,
       Post   =>
         (if Find_Cycle'Result.Has_Cycle then
            Find_Cycle'Result.Meeting_Point in 1 .. Next'Last
            and then Find_Cycle'Result.Start_Node in 1 .. Next'Last
            and then Find_Cycle'Result.Lambda in 1 .. Next'Last
            and then Find_Cycle'Result.Mu <= Next'Last
          else
            Find_Cycle'Result = No_Cycle);
   --  Full Floyd: Has_Cycle, Meeting_Point, Start_Node, Mu, Lambda.

   function Has_Cycle
     (Next  : Successor_Map;
      Start : Node_Id) return Boolean
     with
       Global => null,
       Pre    => Is_Valid_Map (Next) and then Start <= Next'Last,
       Post   => Has_Cycle'Result = Detect (Next, Start).Has_Cycle;

   function Cycle_Length
     (Next  : Successor_Map;
      Start : Node_Id) return Natural
     with
       Global => null,
       Pre    => Is_Valid_Map (Next) and then Start <= Next'Last,
       Post   => Cycle_Length'Result = Find_Cycle (Next, Start).Lambda
                 and then Cycle_Length'Result <= Next'Last;

   function Cycle_Start
     (Next  : Successor_Map;
      Start : Node_Id) return Node_Index
     with
       Global => null,
       Pre    => Is_Valid_Map (Next) and then Start <= Next'Last,
       Post   => Cycle_Start'Result = Find_Cycle (Next, Start).Start_Node
                 and then Cycle_Start'Result <= Next'Last;

   function Tail_Length
     (Next  : Successor_Map;
      Start : Node_Id) return Natural
     with
       Global => null,
       Pre    => Is_Valid_Map (Next) and then Start <= Next'Last,
       Post   => Tail_Length'Result = Find_Cycle (Next, Start).Mu
                 and then Tail_Length'Result <= Next'Last;

   function Is_On_Cycle
     (Next       : Successor_Map;
      Node       : Node_Index;
      Start_Node : Node_Index;
      Lambda     : Natural) return Boolean
     with
       Global => null,
       Pre    => Is_Valid_Map (Next)
                 and then Lambda <= Next'Last
                 and then (Start_Node = Null_Index
                           or else Start_Node <= Next'Last)
                 and then (Node = Null_Index or else Node <= Next'Last);

   ---------------------------------------------------------------------------
   -- Naive O(μ+λ)-space reference (tests / teaching contrast)
   ---------------------------------------------------------------------------

   function Find_Cycle_Naive
     (Next  : Successor_Map;
      Start : Node_Id) return Cycle_Result
     with
       Global => null,
       Pre    => Is_Valid_Map (Next) and then Start <= Next'Last,
       Post   =>
         (if Find_Cycle_Naive'Result.Has_Cycle then
            Find_Cycle_Naive'Result.Meeting_Point in 1 .. Next'Last
            and then Find_Cycle_Naive'Result.Start_Node in 1 .. Next'Last
            and then Find_Cycle_Naive'Result.Lambda in 1 .. Next'Last
            and then Find_Cycle_Naive'Result.Mu <= Next'Last
          else
            Find_Cycle_Naive'Result = No_Cycle);

   ---------------------------------------------------------------------------
   -- Example-graph builders (bounded; no dynamic allocation)
   ---------------------------------------------------------------------------

   function Pure_Cycle (N : Node_Count) return Successor_Map
     with
       Global => null,
       Post   => Pure_Cycle'Result'First = 1
                 and then Pure_Cycle'Result'Last = N
                 and then Is_Valid_Map (Pure_Cycle'Result);
   --  1 → 2 → … → N → 1.  From 1: μ = 0, λ = N.

   function Rho_Graph
     (Tail  : Natural;
      Cycle : Node_Count) return Successor_Map
     with
       Global => null,
       Pre    => Tail <= Max_N - Cycle,
       Post   => Rho_Graph'Result'First = 1
                 and then Rho_Graph'Result'Last = Tail + Cycle
                 and then Is_Valid_Map (Rho_Graph'Result);
   --  Stem 1 → … → Tail → (Tail+1) and cycle of length Cycle.
   --  From 1: μ = Tail, λ = Cycle.  N = Tail + Cycle.

   function Path_To_Sink (N : Node_Count) return Successor_Map
     with
       Global => null,
       Post   => Path_To_Sink'Result'First = 1
                 and then Path_To_Sink'Result'Last = N
                 and then Is_Valid_Map (Path_To_Sink'Result);
   --  1 → 2 → … → N → 0.  Finite list; no cycle.

   function Self_Loop_Chain (N : Node_Count) return Successor_Map
     with
       Global => null,
       Post   => Self_Loop_Chain'Result'First = 1
                 and then Self_Loop_Chain'Result'Last = N
                 and then Is_Valid_Map (Self_Loop_Chain'Result);
   --  1 → 2 → … → N → N.  From 1: μ = N − 1, λ = 1.

   function Two_Cycles return Successor_Map
     with
       Global => null,
       Post   => Two_Cycles'Result'First = 1
                 and then Two_Cycles'Result'Last = 6
                 and then Is_Valid_Map (Two_Cycles'Result);
   --  1 → 2 → 3 → 1  and  4 → 5 → 4;  node 6 → 0.

   function Wikipedia_Example return Successor_Map
     with
       Global => null,
       Post   => Wikipedia_Example'Result'First = 1
                 and then Wikipedia_Example'Result'Last = 9
                 and then Is_Valid_Map (Wikipedia_Example'Result);
   --  1-based remapping of the Wikipedia S = {0..8} figure.
   --  From Ada 3 (wiki 2): μ = 2, λ = 3, Start_Node = 7 (wiki 6).

end Floyds_Cycle_Finding_Algorithm;
