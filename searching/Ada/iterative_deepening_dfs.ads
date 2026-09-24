--  Iterative_Deepening_DFS — Ada 2023 educational package for iterative
--  deepening depth-first search (IDDFS / IDS) on directed unweighted
--  graphs. Repeated depth-limited DFS with increasing limits finds a
--  shallowest (fewest-arcs) Start→Goal path, combining DFS space with
--  BFS optimality for unit-cost graphs. Vertices indexed from 1. No
--  dynamic heap beyond fixed educational arrays sized to Max_Vertices /
--  Max_Edges.
--  Reference: https://en.wikipedia.org/wiki/Iterative_deepening_depth-first_search
--  Sibling sheets (README only — do not `with`): Lex-BFS, Tarjan SCC —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Iterative_Deepening_DFS
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
   -- Vertex identifiers and paths
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Vertex sequence for a Start→Goal walk: Path (1) = Start,
   --  Path (Length) = Goal when Length > 0. Length is the number of
   --  vertices (arc count = Length − 1 when Length ≥ 1).
   type Path_Array is array (Positive range <>) of Vertex_Id;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, or Path bounds that cannot hold a shortest
   --  path (Path'First /= 1 or Path'Last < Vertex_Count when N > 0).

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
   --  Append a directed edge From → To. Parallel edges are permitted.
   --  Self-loops are permitted. Raises Invalid_Argument when From or To
   --  is outside 1 .. Vertex_Count(G), or when Edge_Count would exceed
   --  Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of directed edges currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketch
   ---------------------------------------------------------------------------
   --  IDDFS (Korf, 1985): for depth limit L = 0, 1, 2, … run a recursive
   --  depth-limited DFS (DLS) that expands the search-tree unfolding of G
   --  to depth L. The first successful limit yields a shallowest goal
   --  (fewest arcs) because every shallower depth was fully explored.
   --  DLS returns a “remaining / cutoff” flag so IDDFS can stop when the
   --  finite unfolding is exhausted. Time O(b^d) for branching factor b
   --  and goal depth d; space O(d) for the recursion / path stack (plus
   --  fixed O(V+E) graph storage). No global closed set — cycles are
   --  truncated by the depth limit (Wikipedia directed-graph presentation).

   function Depth_Limited_Search
     (G      : Graph;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      Limit  : Natural;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  One depth-limited DFS from Start looking for Goal with recursion
   --  budget Limit (maximum number of arcs on the explored path). On
   --  success returns True and writes Path (1 .. Length) with
   --  Path (1) = Start and Path (Length) = Goal. On failure returns False
   --  and sets Length = 0. Requires Path'First = 1 and
   --  Path'Last >= Vertex_Count(G) when N > 0; raises Invalid_Argument
   --  otherwise, or when Start / Goal are outside 1 .. N. Vacuous False
   --  for N = 0.

   function Search
     (G      : Graph;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Iterative deepening: call Depth_Limited_Search for Limit = 0, 1, …
   --  up to N − 1 (or until a DLS reports no remaining cutoffs). Returns
   --  True with a shortest Start→Goal path (fewest arcs) when one exists;
   --  False and Length = 0 otherwise. Same Path bound and vertex checks
   --  as Depth_Limited_Search. Start = Goal succeeds with Length = 1.

   function BFS_Shortest_Path
     (G      : Graph;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Breadth-first oracle for tests: same contract as Search (shortest
   --  unweighted path). Uses O(V) queue / parent workspace. Educational
   --  cross-check that IDDFS matches BFS optimality on small digraphs.

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

end Iterative_Deepening_DFS;
