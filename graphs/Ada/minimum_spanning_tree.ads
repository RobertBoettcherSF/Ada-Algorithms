--  Minimum_Spanning_Tree — Ada 2023 educational survey package for the
--  classical minimum spanning tree (MST) / minimum spanning forest (MSF)
--  problem on undirected weighted graphs. Self-contained educational
--  re-implementations of the standard methods (do NOT `with` sibling
--  packages):
--    * Kruskal — sort ascending; Union–Find add when endpoints differ;
--    * Prim — dense multi-start O(V^2+VE) grow from each unsettled seed;
--    * Boruvka — phased cheapest-outgoing merges / contractions;
--    * Reverse_Delete — delete heavy non-bridges (dual of Kruskal).
--  Shared undirected edge-list Graph API; non-negative weights; vertices
--  indexed from 1. Fixed educational arrays sized to Max_Vertices /
--  Max_Edges (no dynamic heap). All four methods agree on Total_Weight
--  (and edge count) for any input; edge sets may differ when equal
--  weights create alternate optima.
--  Reference: https://en.wikipedia.org/wiki/Minimum_spanning_tree
--  Sibling sheets (README only — do not `with`): Kruskal, Prim,
--  Borůvka, Reverse-delete — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Minimum_Spanning_Tree
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
   --  never selected by any of the four methods). Raises
   --  Invalid_Argument when Weight < 0, when U or V is outside
   --  1 .. Vertex_Count(G), or when Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of undirected edges currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketches (survey)
   ---------------------------------------------------------------------------
   --  Kruskal: sort edges ascending; Union–Find add when Find(u)≠Find(v).
   --  Prim (dense): multi-start grow attaching lightest cut edge; array
   --    scan over unsettled keys; edge-list neighbour scan ⇒ O(V^2+VE).
   --  Borůvka: each phase every component takes its cheapest outgoing
   --    edge; Union / contract; O(E log V) educational phases.
   --  Reverse-delete: start with all edges; delete heavy non-bridges
   --    (dual of Kruskal). Connectivity via rebuilt Union–Find.
   --  All four return the same Total_Weight and Tree_Count on every
   --  graph; when weights are unique the kept edge set is unique.

   procedure Kruskal
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  Kruskal MST / MSF of G. On success Tree_Count edges are written
   --  to Tree_Edges(1 .. Tree_Count) and Total_Weight is their weight
   --  sum. Empty graph (N = 0) or edgeless graphs yield Tree_Count = 0
   --  and Total_Weight = 0. Requires Tree_Edges'First = 1 and
   --  Tree_Edges'Last >= Edge_Count(G) when Edge_Count > 0; raises
   --  Invalid_Argument otherwise. Vacuous N = 0 is allowed (no raise).

   procedure Prim
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  Dense multi-start Prim MST / MSF of G (forest form). Same buffer
   --  / empty-graph contracts as Kruskal. Educational O(V^2+VE) scan.

   procedure Boruvka
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  Borůvka MST / MSF of G. Same buffer / empty-graph contracts as
   --  Kruskal. Deterministic tie-break: smaller weight, then smaller
   --  min(U,V), then smaller max(U,V), then smaller insertion index.

   procedure Reverse_Delete
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  Reverse-delete MST / MSF of G. Same buffer / empty-graph
   --  contracts as Kruskal. Dual of Kruskal (delete heavy non-bridges).

private

   --  Union–Find and sort helpers live in the package body. Graph
   --  storage is a fixed undirected edge list shared by all methods.

   type Edge_Array is array (1 .. Max_Edges) of Edge_Record;

   type Graph is limited record
      N     : Natural := 0;
      M     : Natural := 0;
      Edges : Edge_Array;
   end record;

end Minimum_Spanning_Tree;
