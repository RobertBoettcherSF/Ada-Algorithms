--  Best_First_Search — Ada 2023 educational package for greedy best-first
--  search (pure heuristic search) on directed unweighted / unit-cost graphs.
--  Expands the open vertex with smallest heuristic estimate H(v) toward a
--  Goal, using a priority queue (min-heap) and a closed/visited set to avoid
--  re-expansion loops. Yields a Start→Goal path when one is found. Not
--  optimal in general: contrast with BFS (fewest arcs), Dijkstra (non-
--  negative weighted SSSP), and A* (f = g + h). Undirected graphs are
--  modelled by inserting both directed edges. Vertices indexed from 1.
--  Fixed educational arrays sized to Max_Vertices / Max_Edges (no dynamic
--  heap beyond the priority-queue workspace).
--  Reference: https://en.wikipedia.org/wiki/Best-first_search
--  Sibling sheets (README only — do not `with`): BFS, Dijkstra, A*, IDDFS —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Best_First_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 1_000;

   --  Maximum number of directed edges (parallel edges allowed; each
   --  Add_Edge consumes one slot until Clear).
   Max_Edges : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, heuristics, paths
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  H(V) = estimated remaining cost from V to Goal (lower ⇒ more
   --  promising). Caller-supplied; typically H(Goal) = 0. Need not be
   --  admissible or consistent — greedy BeFS does not require either.
   type Heuristic_Array is array (Vertex_Id range <>) of Natural;

   --  Path sequence: Path (1) = Start; Path (Length) = Goal when found.
   --  Length is the number of vertices (arc count = Length − 1 when
   --  Length ≥ 1).
   type Path_Array is array (Positive range <>) of Vertex_Id;

   --  Expansion / discovery order for educational inspection (optional
   --  out-parameter on Search_With_Order).
   type Order_Array is array (Positive range <>) of Vertex_Id;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, N = 0 on Search, H range that does not cover
   --  1 .. N, or Path / Order array bounds that cannot hold the result
   --  (First /= 1 or Last < Vertex_Count when N > 0).

   ---------------------------------------------------------------------------
   -- Directed unweighted graph (adjacency lists)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty digraph on vertices 1 .. Vertex_Count (no edges).
   --  Vertex_Count = 0 yields an empty graph. Raises Invalid_Argument when
   --  Vertex_Count > Max_Vertices.

   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id)
     with Global => null;
   --  Append a directed edge From → To. Parallel edges and self-loops are
   --  permitted. For an undirected edge {u,v}, call Add_Edge twice (u→v
   --  and v→u). Raises Invalid_Argument when From or To is outside
   --  1 .. Vertex_Count(G), or when Edge_Count would exceed Max_Edges.
   --  Edges are prepended to the adjacency list of From.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of directed edges currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (greedy best-first / pure heuristic search)
   ---------------------------------------------------------------------------
   --  Judea Pearl: promise of node n estimated by f(n); greedy BeFS uses
   --  f(n) = h(n) only (Wikipedia "Greedy BeFS" / pure heuristic search).
   --  Maintain an open priority queue keyed by H(v) (min first; FIFO among
   --  equal keys) and a visited/closed set marked on enqueue:
   --    mark Start visited; push Start
   --    while open nonempty:
   --      u ← pop min-H
   --      if u = Goal then reconstruct Prev and succeed
   --      for each out-neighbour w of u not yet visited:
   --        Prev(w) ← u; mark w visited; if w = Goal then succeed; else push w
   --  Not optimal in general (a low-h detour can beat a higher-h short path).
   --  A* uses f = g + h; Dijkstra is A* with h = 0; BFS is unit-cost
   --  fewest-arcs. Time O((V+E) log V) with a binary heap open set;
   --  auxiliary space O(V).

   function Search
     (G      : Graph;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      H      : Heuristic_Array;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Greedy best-first search from Start to Goal guided by H.
   --  On success returns True and writes Path (1 .. Length) with
   --  Path (1) = Start, Path (Length) = Goal. On failure (unreachable)
   --  returns False and Length = 0. Start = Goal yields Length = 1.
   --  Requires Path'First = 1 and Path'Last >= N when N > 0; H'First <= 1
   --  and H'Last >= N; raises Invalid_Argument otherwise, when Start /
   --  Goal are outside 1 .. N, or when N = 0.

   function Search
     (G          : Graph;
      Start      : Vertex_Id;
      Goal       : Vertex_Id;
      H          : Heuristic_Array;
      Path       : out Path_Array;
      Length     : out Natural;
      Expansions : out Natural) return Boolean
     with Global => null;
   --  Same as Search, also reporting Expansions = number of vertices
   --  popped from the open set (educational: lower under a guiding
   --  heuristic than under a flat zero heuristic on many graphs).

   function Search_With_Order
     (G          : Graph;
      Start      : Vertex_Id;
      Goal       : Vertex_Id;
      H          : Heuristic_Array;
      Path       : out Path_Array;
      Length     : out Natural;
      Order      : out Order_Array;
      Count      : out Natural;
      Expansions : out Natural) return Boolean
     with Global => null;
   --  Same as Search with Expansions, also writing the pop (expansion)
   --  order into Order (1 .. Count). Requires Order'First = 1 and
   --  Order'Last >= N when N > 0.

private

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Edge_Index is Positive range 1 .. Max_Edges;

   --  Adjacency via intrusive singly-linked edge nodes in a dense pool:
   --  Head(V) is the first edge index for V (0 = none); To(E) / Next(E)
   --  store the head and the remainder of the list.
   type Head_Array is array (Vertex_Id) of Natural;
   type To_Array is array (Edge_Index) of Vertex_Id;
   type Next_Array is array (Edge_Index) of Natural;

   type Graph is limited record
      N    : Natural := 0;
      E    : Edge_Count_T := 0;
      Head : Head_Array := [others => 0];
      To   : To_Array := [others => Vertex_Id'First];
      Next : Next_Array := [others => 0];
   end record;

end Best_First_Search;
