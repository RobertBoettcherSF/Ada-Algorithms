--  Reverse_Delete_Algorithm — Ada 2023 educational package for the
--  reverse-delete algorithm that builds a minimum spanning tree (MST)
--  or minimum spanning forest (MSF) of an undirected weighted graph.
--  Start with every edge present; consider edges in decreasing weight
--  order; delete an edge when its endpoints remain connected afterward.
--  Dual of Kruskal (which adds light edges). Vertices indexed from 1.
--  Fixed educational arrays sized to Max_Vertices / Max_Edges (no
--  dynamic heap). Optional in-package Kruskal_Reference for cross-checks
--  on small graphs (self-contained — do NOT `with` Prim/Kruskal siblings).
--  Reference: https://en.wikipedia.org/wiki/Reverse-delete_algorithm
--  Sibling sheets (README only — do not `with`): Kruskal, Prim —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Reverse_Delete_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 512;

   --  Maximum number of undirected weighted edges (parallel edges allowed;
   --  each Add_Edge consumes one slot until Clear).
   Max_Edges : constant Positive := 20_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, weights, edge records
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Non-negative edge weight stored after Add_Edge validation.
   --  Add_Edge accepts Integer and raises Invalid_Argument when Weight < 0.
   --  Zero weights are allowed. Policy: reject negatives (document).
   type Weight_Type is range 0 .. 2**31 - 1;

   --  Sum of kept edge weights (MST / MSF total). Wide enough for
   --  Max_Edges * Weight_Type'Last educational instances.
   type Weight_Sum is range 0 .. 2**63 - 1;

   --  One undirected edge (U, V) with Weight. Order of U / V is the
   --  order passed to Add_Edge (not canonicalized). Self-loops permitted
   --  in the input graph but never appear in an MST / MSF.
   type Edge_Record is record
      U, V   : Vertex_Id;
      Weight : Weight_Type;
   end record;

   --  Caller-supplied buffer for kept MST / MSF edges.
   type Edge_List is array (Positive range <>) of Edge_Record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, negative edge weights, or Tree_Edges bounds
   --  that cannot hold the result (First /= 1 or Last < Edge_Count when
   --  the algorithm may keep up to Edge_Count edges).

   ---------------------------------------------------------------------------
   -- Undirected weighted graph (edge list; non-negative weights)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty undirected graph on vertices 1 .. Vertex_Count
   --  (no edges). Vertex_Count = 0 yields an empty graph. Raises
   --  Invalid_Argument when Vertex_Count > Max_Vertices.

   procedure Add_Edge
     (G : in out Graph; U, V : Vertex_Id; Weight : Integer)
     with Global => null;
   --  Append one undirected edge {U, V} with non-negative Weight.
   --  Parallel edges are permitted. Self-loops are permitted (they are
   --  always deleted by reverse-delete / never selected by Kruskal).
   --  Raises Invalid_Argument when Weight < 0, when U or V is outside
   --  1 .. Vertex_Count(G), or when Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of undirected edges currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (reverse-delete)
   ---------------------------------------------------------------------------
   --  Let E be the multiset of undirected edges. Mark every edge kept.
   --  Sort edges by weight descending (ties broken by insertion index).
   --  For each edge e = {u, v} in that order:
   --    Tentatively un-keep e.
   --    If u and v remain connected via the other kept edges, leave e
   --    deleted; otherwise restore e (it is a bridge of the current
   --    kept graph and must stay).
   --  Connectivity is tested with Union–Find rebuilt on the kept edges
   --  (or equivalently DFS / BFS). The surviving edges form an MST when
   --  G is connected, otherwise an MSF. Time O(E^2 α(V)) educational.
   --  Contrast (README only): Kruskal adds light edges; Prim grows a
   --  tree from a seed — reverse-delete removes heavy edges.

   procedure Minimum_Spanning_Tree
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  Reverse-delete MST / MSF of G. On success Tree_Count edges are
   --  written to Tree_Edges(1 .. Tree_Count) and Total_Weight is their
   --  weight sum. Empty graph (N = 0) or edgeless graphs yield
   --  Tree_Count = 0 and Total_Weight = 0. Requires Tree_Edges'First = 1
   --  and Tree_Edges'Last >= Edge_Count(G) when Edge_Count > 0 (buffer
   --  must be able to hold every input edge in the worst case); raises
   --  Invalid_Argument otherwise. Vacuous N = 0 is allowed (no raise).

   procedure Reverse_Delete
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  Alias of Minimum_Spanning_Tree (same contract and result).

   ---------------------------------------------------------------------------
   -- Optional Kruskal reference (in-package; for cross-checks)
   ---------------------------------------------------------------------------
   --  Classic Kruskal: sort edges ascending; Union–Find add when the
   --  endpoints lie in different components. Same MST / MSF total weight
   --  (and same edge count) as reverse-delete; edge sets may differ when
   --  equal weights create alternate optima. Self-contained — no `with`
   --  of Prim / Kruskal sibling packages.

   procedure Kruskal_Reference
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  Kruskal MST / MSF of G. Same buffer / empty-graph contracts as
   --  Minimum_Spanning_Tree. Raises Invalid_Argument under the same
   --  Tree_Edges bound rules.

private

   type Edge_Array is array (1 .. Max_Edges) of Edge_Record;

   type Graph is limited record
      N     : Natural := 0;
      M     : Natural := 0;
      Edges : Edge_Array;
   end record;

end Reverse_Delete_Algorithm;
