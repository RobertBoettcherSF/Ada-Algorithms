--  A_Star — Ada 2023 educational package for A* (Hart–Nilsson–Raphael)
--  point-to-point shortest paths on directed graphs with non-negative edge
--  weights and a caller-supplied heuristic. Evaluation function
--  f(n) = g(n) + h(n): g is path cost from Source, h estimates remaining
--  cost to Goal. Open-set selection is a dense O(V) scan (like the Dijkstra
--  sibling sheet) — no priority-queue / heap machinery. An admissible
--  heuristic yields an optimal path cost; a consistent heuristic additionally
--  ensures each vertex is settled at most once. Heuristic all zeros reduces
--  A* to dense Dijkstra on the same digraph.
--  Vertices indexed from 1. Fixed educational arrays sized to Max_Vertices /
--  Max_Edges (no dynamic heap).
--  Reference: https://en.wikipedia.org/wiki/A*_search_algorithm
--  Sibling sheets (README only — do not `with`): Dijkstra, Best-First,
--  UCS / IDDFS — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package A_Star
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 1_000;

   --  Maximum number of directed weighted edges (parallel edges allowed;
   --  each Add_Edge consumes one slot until Clear).
   Max_Edges : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, weights, distances, heuristics, paths
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Non-negative edge weight stored after Add_Edge validation.
   --  Add_Edge accepts Integer and raises Invalid_Argument when Weight < 0.
   type Weight_Type is range 0 .. 2**31 - 1;

   --  Path / cumulative distances (g-scores). Infinity marks unreachable.
   type Distance_Value is range 0 .. 2**63 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   type Distance_Array is array (Vertex_Id range <>) of Distance_Value;

   --  Caller-supplied heuristic estimates H(V) ≈ remaining cost from V to
   --  Goal. Must be non-negative for every V in 1 .. N (negatives raise
   --  Invalid_Argument). Admissible ⇒ H(V) ≤ true remaining cost; consistent
   --  (monotone) ⇒ H(U) ≤ c(U,W) + H(W) for every edge U→W. H(Goal) = 0 is
   --  typical for admissibility but is not enforced here.
   type Heuristic_Array is array (Vertex_Id range <>) of Integer;

   --  Prev(V) = predecessor of V on a Source→V path found by Search, or 0
   --  if none (Source itself, or unreachable).
   type Prev_Array is array (Vertex_Id range <>) of Natural;

   --  Vertex sequence for a Source→Goal walk: Path(1) = Source,
   --  Path(Length) = Goal when Length > 0. Length is the number of
   --  vertices (arc count = Length − 1 when Length ≥ 1).
   type Path_Array is array (Positive range <>) of Vertex_Id;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, negative edge weights, negative heuristic
   --  values, Heuristic range that does not cover 1 .. N, or Dist / Prev /
   --  Path bounds that cannot hold the result
   --  (First /= 1 or Last < Vertex_Count when N > 0).

   ---------------------------------------------------------------------------
   -- Directed weighted graph (adjacency lists, non-negative weights)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty digraph on vertices 1 .. Vertex_Count (no edges).
   --  Vertex_Count = 0 yields an empty graph. Raises Invalid_Argument when
   --  Vertex_Count > Max_Vertices.

   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Weight : Integer)
     with Global => null;
   --  Append a directed edge From → To with non-negative Weight.
   --  Parallel edges are permitted (A* uses the minimum implicitly via
   --  relaxation). Self-loops are permitted. Raises Invalid_Argument when
   --  Weight < 0, when From or To is outside 1 .. Vertex_Count(G), or when
   --  Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of directed edges currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (dense A*, open set = array scan)
   ---------------------------------------------------------------------------
   --  Initialise Dist(v) ← ∞, Prev(v) ← 0; Dist(Source) ← 0.
   --  Open = {v | Dist(v) < ∞ and not closed}; closed starts empty.
   --  While open nonempty:
   --    u ← argmin_{v in open} Dist(v) + H(v)   -- dense O(V) scan
   --    mark u closed; count an expansion
   --    if u = Goal then stop (admissible H ⇒ Dist(Goal) optimal)
   --    for each edge u → w with weight c:
   --      alt ← Dist(u) + c
   --      if alt < Dist(w) then Dist(w) ← alt; Prev(w) ← u;
   --        reopen w if it was closed (needed for admissible-only H)
   --  When H ≡ 0 everywhere, selection is by Dist alone ⇒ dense Dijkstra.
   --  Time Θ(V^2 + E) with array scan (classic educational formulation).

   procedure Search
     (G         : Graph;
      Source    : Vertex_Id;
      Goal      : Vertex_Id;
      Heuristic : Heuristic_Array;
      Dist      : out Distance_Array;
      Prev      : out Prev_Array;
      Path      : out Path_Array;
      Length    : out Natural;
      Found     : out Boolean)
     with Global => null;
   --  A* from Source to Goal guided by Heuristic. On success Found is True,
   --  Dist(V) is the g-score (Source→V cost) for visited vertices (Infinity
   --  if never reached), Prev encodes a path tree, and Path(1 .. Length) is
   --  the Source→Goal vertex sequence. On failure Found is False and
   --  Length = 0 (Goal unreachable). Source = Goal yields Length = 1 and
   --  Dist(Source) = 0. Requires Dist/Prev First = 1 and Last >= N,
   --  Path'First = 1 and Path'Last >= N, Heuristic covering 1 .. N with
   --  non-negative entries; raises Invalid_Argument otherwise, when Source
   --  or Goal is outside 1 .. N, or when N = 0.

   procedure Search
     (G              : Graph;
      Source         : Vertex_Id;
      Goal           : Vertex_Id;
      Heuristic      : Heuristic_Array;
      Dist           : out Distance_Array;
      Prev           : out Prev_Array;
      Path           : out Path_Array;
      Length         : out Natural;
      Found          : out Boolean;
      Nodes_Expanded : out Natural)
     with Global => null;
   --  Same as Search, also reporting Nodes_Expanded = number of times a
   --  vertex was selected from the open set (educational: a guiding
   --  admissible heuristic often expands fewer nodes than H ≡ 0).

   function Find_Path
     (G         : Graph;
      Source    : Vertex_Id;
      Goal      : Vertex_Id;
      Heuristic : Heuristic_Array;
      Path      : out Path_Array;
      Length    : out Natural) return Distance_Value
     with Global => null;
   --  Convenience: run A* and return the Source→Goal cost (or Infinity if
   --  unreachable). On success Path(1 .. Length) holds the vertex walk;
   --  on failure Length = 0. Same validation as Search.

   function Distance
     (G         : Graph;
      Source    : Vertex_Id;
      Goal      : Vertex_Id;
      Heuristic : Heuristic_Array) return Distance_Value
     with Global => null;
   --  Source→Goal shortest-path cost under A* with Heuristic, or Infinity
   --  if unreachable. Raises Invalid_Argument on the same guards as Search
   --  (except Path bounds — an internal path buffer is used).

   function Reconstruct_Path
     (Prev   : Prev_Array;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Walk Prev from Target back to Source and reverse into Path.
   --  Returns True with Path(1) = Source … Path(Length) = Target when a
   --  path exists in the tree (including Source = Target with Length = 1
   --  when Prev(Source) = 0). Returns False and Length = 0 when Target is
   --  unreachable. Requires Path'First = 1 and Path'Last >= Prev'Last;
   --  raises Invalid_Argument when Source/Target are outside Prev'Range or
   --  Path bounds are wrong.

private

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Edge_Index is Positive range 1 .. Max_Edges;

   --  Adjacency via intrusive singly-linked edge nodes in a dense pool:
   --  Head(V) is the first edge index for V (0 = none); To(E) / Weight(E)
   --  / Next(E) store the head, weight, and remainder of the list.
   type Head_Array is array (Vertex_Id) of Natural;
   type To_Array is array (Edge_Index) of Vertex_Id;
   type Weight_Array is array (Edge_Index) of Weight_Type;
   type Next_Array is array (Edge_Index) of Natural;

   type Graph is limited record
      N      : Natural := 0;
      E      : Edge_Count_T := 0;
      Head   : Head_Array := [others => 0];
      To     : To_Array := [others => Vertex_Id'First];
      Weight : Weight_Array := [others => 0];
      Next   : Next_Array := [others => 0];
   end record;

end A_Star;
