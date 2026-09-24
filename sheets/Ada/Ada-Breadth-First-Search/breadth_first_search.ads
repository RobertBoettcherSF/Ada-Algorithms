--  Breadth_First_Search — Ada 2023 educational package for breadth-first
--  search (BFS) on directed unweighted graphs. Explores vertices level by
--  level from a start vertex using a FIFO queue; yields visit (level)
--  order, unit-cost shortest-path distances and predecessors, distance /
--  reachability queries, and path reconstruction. Undirected graphs are
--  modelled by inserting both directed edges. Vertices indexed from 1.
--  Fixed educational arrays sized to Max_Vertices / Max_Edges (no dynamic
--  heap). Time O(V+E).
--  Reference: https://en.wikipedia.org/wiki/Breadth-first_search
--  Sibling sheets (README only — do not `with`): DFS, IDDFS, Dijkstra,
--  Lex-BFS — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Breadth_First_Search
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
   -- Vertex identifiers, orders, distances, predecessors
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Visit / path sequence: Order (1) is the start; Order (1 .. Count)
   --  lists each reached vertex once in BFS discovery (level) order.
   type Order_Array is array (Positive range <>) of Vertex_Id;

   --  Dist (V) is the fewest arcs from Start to V, or Infinity when
   --  unreachable. Dist (Start) = 0 after Shortest_Paths / Distance.
   type Distance_Array is array (Vertex_Id range <>) of Natural;

   --  Prev (V) is the predecessor of V on a shortest Start→V path
   --  (Natural code of a Vertex_Id), or 0 when V is Start or unreachable.
   type Prev_Array is array (Vertex_Id range <>) of Natural;

   --  Sentinel for unreachable distances (larger than any simple-path
   --  length on graphs with at most Max_Vertices vertices).
   Infinity : constant Natural := Natural'Last;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, or Order / Dist / Prev / Path array bounds
   --  that cannot hold the result (First /= 1 or Last < Vertex_Count when
   --  N > 0).

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
   --  Self-loops are permitted. For an undirected edge {u,v}, call
   --  Add_Edge twice (u→v and v→u). Raises Invalid_Argument when From or
   --  To is outside 1 .. Vertex_Count(G), or when Edge_Count would exceed
   --  Max_Edges. Edges are prepended to the adjacency list of From, so
   --  the most recently added out-edge is dequeued-for first among
   --  same-level neighbours.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of directed edges currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketch
   ---------------------------------------------------------------------------
   --  Classic BFS (Wikipedia): enqueue the start as explored; while the
   --  FIFO queue is nonempty, dequeue v and for each unexplored out-
   --  neighbour w mark w explored, set parent/distance, and enqueue w.
   --  First discovery of each vertex is along a fewest-arcs path from
   --  Start (unit-cost optimality). Visited-before-enqueue prevents
   --  revisits (finite termination on cyclic digraphs). Time O(V+E);
   --  auxiliary space O(V) for the queue / visited bitset plus fixed
   --  O(V+E) graph storage.

   procedure BFS
     (G     : Graph;
      Start : Vertex_Id;
      Order : out Order_Array;
      Count : out Natural)
     with Global => null;
   --  Breadth-first discovery order of vertices reachable from Start
   --  (including Start). Writes Order (1 .. Count); Count = 0 only when
   --  N = 0 (vacuous). Requires Order'First = 1 and Order'Last >= N when
   --  N > 0; raises Invalid_Argument otherwise, or when Start is outside
   --  1 .. N. Each reachable vertex appears exactly once (level order).

   procedure Shortest_Paths
     (G     : Graph;
      Start : Vertex_Id;
      Dist  : out Distance_Array;
      Prev  : out Prev_Array)
     with Global => null;
   --  Unit-cost single-source shortest paths from Start. For every V in
   --  1 .. N: Dist (V) is the fewest arcs Start→V, or Infinity if
   --  unreachable; Prev (V) is the predecessor on some shortest path
   --  (0 for Start and for unreachable vertices). Requires Dist'First =
   --  Prev'First = 1 and both Last >= N when N > 0; raises
   --  Invalid_Argument otherwise, or when Start is outside 1 .. N.
   --  Vacuous: N = 0 raises Invalid_Argument.

   function Distance
     (G : Graph; Start, Target : Vertex_Id) return Natural
     with Global => null;
   --  Fewest arcs from Start to Target, or Infinity when unreachable
   --  (including when N = 0 is not applicable — N = 0 raises). Start =
   --  Target yields 0. Raises Invalid_Argument when Start or Target is
   --  outside 1 .. N, or when N = 0.

   function Reconstruct_Path
     (Prev   : Prev_Array;
      Start  : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Order_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Walk Prev from Target back to Start and reverse into Path
   --  (1 .. Length). Returns True when a chain Prev… leads from Target
   --  to Start (including Start = Target with Length = 1 and Prev unused
   --  for Start). Returns False and Length = 0 when Target is unreachable
   --  from Start under Prev (Prev (Target) = 0 and Target /= Start, or a
   --  broken chain). Requires Path'First = 1 and Path'Last >= Prev'Length
   --  (sufficient for at most N vertices); raises Invalid_Argument when
   --  Path bounds are insufficient, or Start / Target outside Prev'Range.

   function Reachable
     (G : Graph; Start, Target : Vertex_Id) return Boolean
     with Global => null;
   --  True iff Target is reachable from Start by a directed walk
   --  (including Start = Target). Equivalent to Distance (G, Start,
   --  Target) /= Infinity. Raises Invalid_Argument when Start or Target
   --  is outside 1 .. N, or when N = 0.

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

end Breadth_First_Search;
