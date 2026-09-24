--  Bidirectional_Search — Ada 2023 educational package for bidirectional
--  breadth-first search on directed unweighted graphs. Runs two simultaneous
--  BFS frontiers — forward from Start on out-edges and backward from Goal
--  on automatically recorded reverse edges — meeting in the middle to recover
--  a unit-cost shortest path. Yields Shortest_Path, Distance / Reachable
--  queries, and a unidirectional BFS_Distance oracle for tests. Undirected
--  graphs are modelled by inserting both directed edges. Vertices indexed
--  from 1. Fixed educational arrays sized to Max_Vertices / Max_Edges (no
--  dynamic heap). Intuition: O(b^{d/2}) expansions vs O(b^d) one-sided BFS.
--  Reference: https://en.wikipedia.org/wiki/Bidirectional_search
--  Sibling sheets (README only — do not `with`): BFS, DFS, IDDFS, Dijkstra —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Bidirectional_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 1_000;

   --  Maximum number of directed edges (parallel edges allowed; each
   --  Add_Edge consumes one forward slot and one reverse slot until Clear).
   Max_Edges : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, paths, sentinel
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Path sequence: Path (1) is Start; Path (Length) is Goal when found.
   type Order_Array is array (Positive range <>) of Vertex_Id;

   --  Sentinel for unreachable distances (larger than any simple-path
   --  length on graphs with at most Max_Vertices vertices).
   Infinity : constant Natural := Natural'Last;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, N = 0 on Distance / Reachable / Shortest_Path
   --  / BFS_Distance, or Path array bounds that cannot hold the result
   --  (First /= 1 or Last < Vertex_Count when N > 0).

   ---------------------------------------------------------------------------
   -- Directed unweighted graph (forward + reverse adjacency)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty digraph on vertices 1 .. Vertex_Count (no edges).
   --  Vertex_Count = 0 yields an empty graph. Raises Invalid_Argument when
   --  Vertex_Count > Max_Vertices.

   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id)
     with Global => null;
   --  Append a directed edge From → To and automatically record the reverse
   --  adjacency entry To ← From used by the backward search frontier.
   --  Parallel edges and self-loops are permitted. For an undirected edge
   --  {u,v}, call Add_Edge twice (u→v and v→u). Raises Invalid_Argument when
   --  From or To is outside 1 .. Vertex_Count(G), or when Edge_Count would
   --  exceed Max_Edges. Edges are prepended, so the most recently added
   --  out-edge is expanded first among same-level neighbours.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of directed edges currently stored in G (reverse slots are
   --  bookkeeping for the same Edge_Count, not counted twice).

   ---------------------------------------------------------------------------
   -- Algorithm sketch
   ---------------------------------------------------------------------------
   --  Bidirectional BFS (Wikipedia): maintain two FIFO queues — forward
   --  from Start on out-edges, backward from Goal on reverse edges. Mark
   --  vertices explored per side before enqueue. Whenever a vertex is known
   --  to both sides, candidate length = Dist_F + Dist_B; keep the minimum
   --  meeting vertex. Alternating expansion of the smaller frontier finds a
   --  unit-cost shortest Start→Goal path. Reconstruct by walking Prev_F
   --  Start←…←Meet and Prev_B Meet→…→Goal. Time O(V+E) worst case; typical
   --  expansions ~ O(b^{d/2}) vs O(b^d) for one-sided BFS of depth d and
   --  branching factor b. Auxiliary space O(V) for both frontiers.

   function Shortest_Path
     (G      : Graph;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      Path   : out Order_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Bidirectional BFS unit-cost shortest path from Start to Goal.
   --  On success returns True and writes Path (1 .. Length) with
   --  Path (1) = Start, Path (Length) = Goal, Length = Dist + 1.
   --  On failure (unreachable) returns False and Length = 0.
   --  Start = Goal yields Length = 1. Requires Path'First = 1 and
   --  Path'Last >= N when N > 0; raises Invalid_Argument otherwise, when
   --  Start / Goal are outside 1 .. N, or when N = 0.

   function Distance
     (G : Graph; Start, Goal : Vertex_Id) return Natural
     with Global => null;
   --  Fewest arcs from Start to Goal via bidirectional BFS, or Infinity
   --  when unreachable. Start = Goal yields 0. Raises Invalid_Argument when
   --  Start or Goal is outside 1 .. N, or when N = 0.

   function BFS_Distance
     (G : Graph; Start, Goal : Vertex_Id) return Natural
     with Global => null;
   --  Unidirectional (one-sided) BFS distance on forward out-edges only —
   --  educational oracle that Distance / Shortest_Path must match on every
   --  reachable pair. Same Invalid_Argument rules as Distance.

   function Reachable
     (G : Graph; Start, Goal : Vertex_Id) return Boolean
     with Global => null;
   --  True iff Goal is reachable from Start by a directed walk
   --  (including Start = Goal). Equivalent to Distance (G, Start, Goal)
   --  /= Infinity. Raises Invalid_Argument when Start or Goal is outside
   --  1 .. N, or when N = 0.

private

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Edge_Index is Positive range 1 .. Max_Edges;

   --  Dual adjacency via intrusive singly-linked edge nodes in dense pools:
   --  Head_F(V) / Head_R(V) are first edge indices (0 = none); To_* / Next_*
   --  store the head and the remainder. Add_Edge writes one forward and one
   --  reverse slot at the same Edge_Index.
   type Head_Array is array (Vertex_Id) of Natural;
   type To_Array is array (Edge_Index) of Vertex_Id;
   type Next_Array is array (Edge_Index) of Natural;

   type Graph is limited record
      N      : Natural := 0;
      E      : Edge_Count_T := 0;
      Head_F : Head_Array := [others => 0];
      To_F   : To_Array := [others => Vertex_Id'First];
      Next_F : Next_Array := [others => 0];
      Head_R : Head_Array := [others => 0];
      To_R   : To_Array := [others => Vertex_Id'First];
      Next_R : Next_Array := [others => 0];
   end record;

end Bidirectional_Search;
