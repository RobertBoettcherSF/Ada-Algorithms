--  Depth_First_Search — Ada 2023 educational package for depth-first
--  search (DFS) on directed unweighted graphs. Traverses as far as
--  possible along each branch before backtracking; records discovery
--  (preorder) order, optional full forest over all vertices, reachability,
--  and discover/finish timestamps (parenthesization; reverse finish order
--  is a topological order on DAGs). Vertices indexed from 1. Fixed
--  educational arrays sized to Max_Vertices / Max_Edges (no dynamic heap).
--  Reference: https://en.wikipedia.org/wiki/Depth-first_search
--  Sibling sheets (README only — do not `with`): IDDFS, Dijkstra,
--  Lex-BFS, Tarjan SCC — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Depth_First_Search
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
   -- Vertex identifiers, orders, timestamps
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Discovery / visit sequence: Order (1) is the start (or first forest
   --  root); Order (1 .. Count) lists each reached vertex once (preorder).
   type Order_Array is array (Positive range <>) of Vertex_Id;

   --  Discover (V) / Finish (V) are DFS clock values in 1 .. 2N for
   --  vertices 1 .. N after DFS_Timestamps (0 means unused / out of range).
   type Time_Array is array (Vertex_Id range <>) of Natural;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, or Order / Time array bounds that cannot
   --  hold the result (First /= 1 or Last < Vertex_Count when N > 0).

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
   --  Max_Edges. Edges are prepended to the adjacency list of From, so
   --  the most recently added out-edge is explored first by DFS.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of directed edges currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketch
   ---------------------------------------------------------------------------
   --  Classic recursive DFS (Wikipedia): mark v discovered, then for each
   --  out-neighbour w not yet discovered recurse on w; on return mark
   --  finish. This package uses an explicit stack of adjacency iterators
   --  that yields the same discovery and finish order without deep
   --  recursion (safe up to Max_Vertices). Visited set prevents revisits
   --  (finite termination on cyclic digraphs). Time O(V+E); auxiliary
   --  space O(V) for the stack / visited bitset plus fixed O(V+E) graph
   --  storage. DFS records preorder (discovery) of the reachable set;
   --  DFS_Forest repeats from every unused vertex in id order; timestamps
   --  support the parenthesization theorem and reverse-finish topo on DAGs.

   procedure DFS
     (G     : Graph;
      Start : Vertex_Id;
      Order : out Order_Array;
      Count : out Natural)
     with Global => null;
   --  Depth-first discovery order of vertices reachable from Start
   --  (including Start). Writes Order (1 .. Count); Count = 0 only when
   --  N = 0 (vacuous). Requires Order'First = 1 and Order'Last >= N when
   --  N > 0; raises Invalid_Argument otherwise, or when Start is outside
   --  1 .. N. Each reachable vertex appears exactly once (preorder).

   procedure DFS_Forest
     (G     : Graph;
      Order : out Order_Array;
      Count : out Natural)
     with Global => null;
   --  Full DFS forest: for V = 1 .. N in increasing order, if V is not
   --  yet visited, run DFS from V and append its discovery sequence.
   --  Count = N when N > 0 (every vertex appears once); Count = 0 when
   --  N = 0. Same Order bound checks as DFS.

   function Reachable
     (G : Graph; Start, Target : Vertex_Id) return Boolean
     with Global => null;
   --  True iff Target is reachable from Start by a directed walk
   --  (including Start = Target). Raises Invalid_Argument when Start or
   --  Target is outside 1 .. N, or when N = 0.

   procedure DFS_Timestamps
     (G        : Graph;
      Discover : out Time_Array;
      Finish   : out Time_Array)
     with Global => null;
   --  Forest DFS assigning discovery and finish times: a global clock
   --  ticks on each discover and each finish, so times lie in 1 .. 2N.
   --  Discover (V) < Finish (V) for every V in 1 .. N; intervals nest or
   --  are disjoint (parenthesization). Reverse finish order is a
   --  topological order when G is a DAG. Requires Discover'First =
   --  Finish'First = 1 and both Last >= N when N > 0; raises
   --  Invalid_Argument otherwise. Vacuous: N = 0 raises Invalid_Argument.

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

end Depth_First_Search;
