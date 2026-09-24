--  Kosarajus_Algorithm — Ada 2023 educational package for Kosaraju–Sharir
--  strongly connected components (SCC) on directed graphs. Two DFS forest
--  passes — first on G recording finish order, then on the transpose G^T
--  in reverse finish order — partition vertices into SCCs in O(V+E) time.
--  Vertices are indexed from 1. No dynamic heap allocation beyond fixed
--  educational arrays sized to Max_Vertices / Max_Edges.
--  Reference: https://en.wikipedia.org/wiki/Kosaraju%27s_algorithm
--  Sibling sheets (README only — do not `with`): Tarjan's SCC (low-link),
--  Path-Based Strong Component Algorithm — RobertBoettcherSF Ada series.

pragma Ada_2022;

package Kosarajus_Algorithm
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
   -- Algorithm sketch (Kosaraju–Sharir two DFS passes)
   ---------------------------------------------------------------------------
   --  (1) DFS on G: visit every vertex; after exploring all out-neighbours
   --      of v, push v onto a finish-order stack L (post-order).
   --  (2) Build the transpose adjacency G^T (every edge u→v becomes v→u)
   --      in a fixed educational edge pool (no heap).
   --  (3) DFS on G^T: repeatedly pop L; each unassigned vertex u starts a
   --      new Component_Id and Assign(u) labels every vertex reachable
   --      from u in G^T (i.e. every in-neighbour walk in G).
   --  Key fact: G and G^T have the same SCCs. Reverse finish order on G
   --  ensures each Assign root is a source of the remaining condensation.
   --  Contrast: Tarjan uses one DFS + stack + low-link; path-based uses
   --  one DFS + two stacks S,P. Kosaraju is the conceptually simplest
   --  linear algorithm but walks the graph twice.
   --  Condensation order: SCCs receive ids in topological order of the
   --  condensation DAG (first Assign root — a source SCC — gets id 1).

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
   --  Time O(V+E); workspace O(V+E) fixed arrays (no heap).

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

end Kosarajus_Algorithm;
