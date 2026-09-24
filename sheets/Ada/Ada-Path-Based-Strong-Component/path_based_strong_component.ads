--  Path_Based_Strong_Component — Ada 2023 educational package for the
--  path-based (Cheriyan–Mehlhorn / Gabow / Dijkstra) strongly connected
--  components algorithm on directed graphs. One DFS forest pass with
--  two stacks (S: unassigned vertices; P: current path / merge frontier)
--  partitions vertices into SCCs in O(V+E) time. Vertices are indexed
--  from 1. No dynamic heap allocation beyond fixed educational arrays
--  sized to Max_Vertices / Max_Edges.
--  Reference: https://en.wikipedia.org/wiki/Path-based_strong_component_algorithm
--  Sibling sheets (README only — do not `with`): Tarjan's SCC (low-link),
--  Kosaraju (two DFS) — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Path_Based_Strong_Component
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
   -- Vertex / component identifiers
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Component identifiers assigned by Compute_SCC: 1 .. Component_Count.
   --  Zero is unused / unset (never written by a successful Compute_SCC
   --  for vertices 1 .. Vertex_Count).
   type Component_Id is new Natural;

   type Component_Array is array (Vertex_Id range <>) of Component_Id;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, empty / mismatched Component_Of bounds, or
   --  Same_SCC on out-of-range vertex ids.

   ---------------------------------------------------------------------------
   -- Directed graph (adjacency lists)
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
   --  Raises Invalid_Argument when From or To is outside 1 .. Vertex_Count(G),
   --  or when Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of directed edges currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Gabow / Cheriyan–Mehlhorn two-stack DFS)
   ---------------------------------------------------------------------------
   --  Perform a depth-first search, maintaining:
   --    S — vertices not yet assigned to an SCC, in discovery order;
   --    P — vertices not yet known to belong to distinct SCCs (path /
   --        preorder merge stack);
   --    C — discovery counter used as preorder numbers (0 = unvisited).
   --  On first visit of v:
   --    C := C + 1; Preorder(v) := C; push v onto S and onto P.
   --  For each edge v → w:
   --    if Preorder(w) is unset then recurse on w (tree edge);
   --    else if w is not yet assigned to an SCC then
   --      pop P until Preorder(top(P)) <= Preorder(w)
   --      (contract the path so v and w share a prospective component).
   --  After scanning v's edges, if v is top(P) then v is an SCC root:
   --    pop S through v inclusive into a new Component_Id, then pop P.
   --  Contrast: Tarjan uses one stack plus low-link / index arrays;
   --  Kosaraju uses two full DFS passes (graph then transpose).
   --  Condensation order: SCCs are reported in reverse topological order
   --  of the condensation DAG (first finished SCC gets id 1).

   procedure Compute_SCC
     (G               : Graph;
      Component_Of    : out Component_Array;
      Component_Count : out Natural)
     with Global => null;
   --  Partition vertices 1 .. Vertex_Count(G) into strongly connected
   --  components. On success, Component_Of(V) ∈ 1 .. Component_Count for
   --  every V in 1 .. Vertex_Count(G), and Component_Count is the number
   --  of SCCs (0 when the graph is empty). Requires
   --  Component_Of'First = 1 and Component_Of'Last >= Vertex_Count(G)
   --  (when Vertex_Count > 0); raises Invalid_Argument otherwise.
   --  Time O(V+E); workspace O(V) fixed arrays (no heap).

   function Same_SCC
     (Component_Of : Component_Array;
      U, V         : Vertex_Id) return Boolean
     with Global => null;
   --  True iff Component_Of(U) = Component_Of(V) and both are nonzero.
   --  Raises Invalid_Argument when U or V is outside Component_Of'Range.

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

end Path_Based_Strong_Component;
