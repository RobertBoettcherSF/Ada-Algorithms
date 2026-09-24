--  Tarjans_SCC — Ada 2023 educational package for Tarjan's strongly
--  connected components (SCC) algorithm on directed graphs. One DFS
--  forest pass with an explicit stack and low-link values partitions
--  vertices into SCCs in O(V+E) time. Vertices are indexed from 1.
--  No dynamic heap allocation beyond fixed educational arrays sized
--  to Max_Vertices / Max_Edges.
--  Reference: https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm
--  Sibling sheets (README only — do not `with`): Kosaraju, Path-Based
--  Strong Component Algorithm — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Tarjans_SCC
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
   -- Algorithm sketch
   ---------------------------------------------------------------------------
   --  Tarjan (1972): DFS numbering Index(v), Low_Link(v), and an explicit
   --  stack of vertices that may still belong to an unfinished SCC.
   --  On first visit of v:
   --    Index(v) := Low_Link(v) := next DFS time; push v; On_Stack(v) := True
   --  For each edge v → w:
   --    if w unvisited then recurse; Low_Link(v) := min(Low_Link(v), Low_Link(w))
   --    elsif On_Stack(w) then Low_Link(v) := min(Low_Link(v), Index(w))
   --  When Low_Link(v) = Index(v), v is an SCC root: pop the stack until v
   --  inclusive and assign those vertices the next Component_Id.
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

end Tarjans_SCC;
