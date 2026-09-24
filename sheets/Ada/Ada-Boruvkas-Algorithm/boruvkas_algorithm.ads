--  Boruvkas_Algorithm — Ada 2023 educational package for Borůvka's
--  algorithm that builds a minimum spanning tree (MST) or minimum
--  spanning forest (MSF) of an undirected weighted graph. In phases,
--  every component selects its cheapest outgoing edge; selected edges
--  are contracted / unioned; repeat until each connected piece is a
--  single tree. Vertices indexed from 1. Fixed educational arrays
--  sized to Max_Vertices / Max_Edges (no dynamic heap). Optional
--  in-package Kruskal_Reference for cross-checks on small graphs
--  (self-contained — do NOT `with` Kruskal / Prim / Reverse-delete
--  siblings). Union–Find (Make-Set / Find with path compression /
--  Union by rank) is a package-body private implementation detail.
--  Reference: https://en.wikipedia.org/wiki/Bor%C5%AFvka%27s_algorithm
--  Sibling sheets (README only — do not `with`): Kruskal, Prim,
--  Reverse-delete — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Boruvkas_Algorithm
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
   --  never selected by Borůvka / Kruskal). Raises Invalid_Argument when
   --  Weight < 0, when U or V is outside 1 .. Vertex_Count(G), or when
   --  Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of undirected edges currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Borůvka)
   ---------------------------------------------------------------------------
   --  Initialize a forest F of |V| single-vertex components (Make-Set).
   --  While true:
   --    For each component, record its cheapest outgoing edge (None if
   --    the component is isolated within its connected piece).
   --    Preference: smaller Weight; on ties smaller min(U,V); then
   --    smaller max(U,V); then smaller insertion index (deterministic).
   --    If every component has None, halt (F is an MSF / MST).
   --    Otherwise Union along each selected edge that still joins
   --    distinct components, and keep those edges in the result.
   --  Each phase at most halves the number of components inside a
   --  connected piece ⇒ O(log V) phases; educational scan is O(E) per
   --  phase ⇒ O(E log V). Contrast (README only): Kruskal sorts and
   --  adds; Prim grows from a seed; reverse-delete removes heavy
   --  non-bridges.

   procedure Minimum_Spanning_Tree
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  Borůvka MST / MSF of G. On success Tree_Count edges are written
   --  to Tree_Edges(1 .. Tree_Count) and Total_Weight is their weight
   --  sum. Empty graph (N = 0) or edgeless graphs yield Tree_Count = 0
   --  and Total_Weight = 0. Requires Tree_Edges'First = 1 and
   --  Tree_Edges'Last >= Edge_Count(G) when Edge_Count > 0 (buffer must
   --  be able to hold every input edge in the worst case); raises
   --  Invalid_Argument otherwise. Vacuous N = 0 is allowed (no raise).

   procedure Boruvka
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
   --  (and same edge count) as Borůvka; edge sets may differ when equal
   --  weights create alternate optima. Self-contained — no `with` of
   --  Kruskal / Prim / Reverse-delete sibling packages.

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

   --  Union–Find lives in the package body (path compression +
   --  union-by-rank). Graph storage is a fixed undirected edge list.

   type Edge_Array is array (1 .. Max_Edges) of Edge_Record;

   type Graph is limited record
      N     : Natural := 0;
      M     : Natural := 0;
      Edges : Edge_Array;
   end record;

end Boruvkas_Algorithm;
