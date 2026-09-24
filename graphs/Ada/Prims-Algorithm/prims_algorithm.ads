--  Prims_Algorithm — Ada 2023 educational package for Prim's (Jarník–
--  Prim–Dijkstra) algorithm that grows a minimum spanning tree (MST)
--  of an undirected weighted graph from a seed vertex, or a minimum
--  spanning forest (MSF) by restarting on every component. Dense
--  O(V^2) array scan for the lightest unsettled key (classic textbook
--  formulation). Vertices indexed from 1. Fixed educational arrays
--  sized to Max_Vertices / Max_Edges (no dynamic heap). Optional
--  in-package Kruskal_Reference for cross-checks on small graphs
--  (self-contained — do NOT `with` Kruskal / Reverse-delete siblings).
--  Reference: https://en.wikipedia.org/wiki/Prim%27s_algorithm
--  Sibling sheets (README only — do not `with`): Kruskal, Reverse-delete,
--  Borůvka — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Prims_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 512;

   --  Maximum number of undirected weighted edges (parallel edges allowed;
   --  each Add_Edge consumes one logical undirected slot until Clear).
   --  Internally each undirected edge is stored as two directed adjacency
   --  entries (self-loops once), so the directed pool is 2 * Max_Edges.
   Max_Edges : constant Positive := 20_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, weights, keys, parents, edge records
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Non-negative edge weight stored after Add_Edge validation.
   --  Add_Edge accepts Integer and raises Invalid_Argument when Weight < 0.
   --  Zero weights are allowed. Policy: reject negatives (document).
   type Weight_Type is range 0 .. 2**31 - 1;

   --  Sum of tree / forest edge weights. Wide enough for educational
   --  Max_Edges * Weight_Type'Last instances.
   type Weight_Sum is range 0 .. 2**63 - 1;

   --  Prim key / cut-weight. Infinity marks vertices not yet attached to
   --  the growing tree (or unreachable from Start / current seed).
   type Key_Value is range 0 .. 2**63 - 1;
   Infinity : constant Key_Value := Key_Value'Last;

   type Key_Array is array (Vertex_Id range <>) of Key_Value;

   --  Parent(V) = predecessor of V in the Prim tree / forest, or 0 if
   --  V is a root (Start / component seed) or unreachable / unset.
   type Parent_Array is array (Vertex_Id range <>) of Natural;

   --  One undirected edge (U, V) with Weight. Order of U / V is the
   --  order recorded when the edge entered the tree (Parent → child).
   --  Self-loops permitted in the input graph but never appear in an
   --  MST / MSF.
   type Edge_Record is record
      U, V   : Vertex_Id;
      Weight : Weight_Type;
   end record;

   --  Caller-supplied buffer for tree / forest edges.
   type Edge_List is array (Positive range <>) of Edge_Record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, negative edge weights, Start outside
   --  1 .. N, N = 0 on seeded Prim, or Parent / Key / Tree_Edges bounds
   --  that cannot hold the result (First /= 1 or Last < N / capacity).

   ---------------------------------------------------------------------------
   -- Undirected weighted graph (adjacency lists; non-negative weights)
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
   --  Stored once logically; adjacency is recorded in both directions
   --  (self-loops once). Parallel edges are permitted (Prim keeps the
   --  lightest cut edge via key updates). Raises Invalid_Argument when
   --  Weight < 0, when U or V is outside 1 .. Vertex_Count(G), or when
   --  Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of undirected edges currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (dense Prim, O(V^2))
   ---------------------------------------------------------------------------
   --  Initialise Key(v) ← ∞, Parent(v) ← 0 for all v; Key(Start) ← 0.
   --  Maintain unsettled set S = {1 .. N}. While S is nonempty:
   --    u ← argmin_{v in S} Key(v); remove u from S.
   --    If Key(u) = ∞ then remaining vertices are outside Start's
   --      component — stop (single-tree mode) or pick a new seed with
   --      Key ← 0 (forest mode).
   --    For each undirected neighbour w of u with weight c:
   --      if w unsettled and c < Key(w) then Key(w) ← c; Parent(w) ← u.
   --  Correct for non-negative weights: when u is settled, the cut edge
   --  of weight Key(u) is a safe MST edge (cut property).
   --  Time Θ(V^2 + E) with array scan for the minimum (classic dense
   --  formulation). Binary-heap / Fibonacci-heap variants achieve
   --  O(E log V) / O(E + V log V); this sheet uses the dense scan.

   ---------------------------------------------------------------------------
   -- Prim from Start (one tree in Start's connected component)
   ---------------------------------------------------------------------------

   procedure Minimum_Spanning_Tree
     (G            : Graph;
      Start        : Vertex_Id;
      Parent       : out Parent_Array;
      Key          : out Key_Array;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  Grow Prim's tree from Start. On success Parent / Key describe the
   --  tree: Parent(Start) = 0, Key(Start) = 0; for every other vertex v
   --  in Start's component, Parent(v) is the tree parent and Key(v) is
   --  the weight of edge {Parent(v), v}. Vertices outside the component
   --  keep Key = Infinity and Parent = 0. Total_Weight is the sum of
   --  Key(v) over vertices with Parent(v) /= 0. Requires Parent'First =
   --  Key'First = 1 and Parent'Last >= N, Key'Last >= N when N > 0;
   --  raises Invalid_Argument otherwise, when Start is outside 1 .. N,
   --  or when N = 0.

   procedure Minimum_Spanning_Tree
     (G            : Graph;
      Start        : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  Same growth from Start; writes Tree_Count edges to
   --  Tree_Edges(1 .. Tree_Count) as (Parent(v), v, Key(v)) for each
   --  attached v, and Total_Weight as their weight sum. Covers only
   --  Start's component (forest remainder is ignored). Requires
   --  Tree_Edges'First = 1 and Tree_Edges'Last >= N - 1 when N > 1
   --  (a tree has at most N−1 edges); raises Invalid_Argument under the
   --  same Start / N rules as the Parent/Key form, or on bad bounds.
   --  Vacuous N = 0 raises Invalid_Argument (seeded Prim needs a Start).

   procedure Prim
     (G            : Graph;
      Start        : Vertex_Id;
      Parent       : out Parent_Array;
      Key          : out Key_Array;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  Alias of Minimum_Spanning_Tree (Parent/Key form).

   procedure Prim
     (G            : Graph;
      Start        : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  Alias of Minimum_Spanning_Tree (edge-list form).

   ---------------------------------------------------------------------------
   -- Minimum spanning forest (multi-start Prim over all components)
   ---------------------------------------------------------------------------

   procedure Minimum_Spanning_Forest
     (G            : Graph;
      Parent       : out Parent_Array;
      Key          : out Key_Array;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  Run Prim restarted on every unsettled component (seeds in ascending
   --  vertex id). Each component root r has Parent(r) = 0 and Key(r) = 0;
   --  Total_Weight sums all tree edges across the forest. Empty graph
   --  (N = 0) yields Total_Weight = 0 with no raise. Requires Parent /
   --  Key bounds as for seeded Prim when N > 0.

   procedure Minimum_Spanning_Forest
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  MSF edge-list form. Tree_Count edges written to
   --  Tree_Edges(1 .. Tree_Count); Total_Weight their sum. Empty / edgeless
   --  graphs yield Tree_Count = 0, Total_Weight = 0. Requires
   --  Tree_Edges'First = 1 and Tree_Edges'Last >= N - 1 when N > 1
   --  (at most N−1 forest edges); when N <= 1 any First = 1 buffer is OK.
   --  Raises Invalid_Argument on bad bounds.

   ---------------------------------------------------------------------------
   -- Optional Kruskal reference (in-package; for cross-checks)
   ---------------------------------------------------------------------------
   --  Classic Kruskal: sort edges ascending; Union–Find add when the
   --  endpoints lie in different components. Same MSF total weight (and
   --  same edge count) as Minimum_Spanning_Forest; edge sets may differ
   --  when equal weights create alternate optima. Self-contained — no
   --  `with` of Kruskal / Reverse-delete sibling packages.

   procedure Kruskal_Reference
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  Kruskal MST / MSF of G. Same buffer / empty-graph contracts as
   --  Minimum_Spanning_Forest (edge-list). Raises Invalid_Argument under
   --  the same Tree_Edges bound rules. Buffer must hold up to Edge_Count
   --  edges in the worst case (or N−1 when N > 1 — we require
   --  Last >= Max(Edge_Count, N-1) when M > 0 for simplicity Last >= M
   --  when M > 0, matching reverse-delete style).

private

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Dir_Count_T is Natural range 0 .. 2 * Max_Edges;
   subtype Dir_Index is Positive range 1 .. 2 * Max_Edges;

   --  Adjacency via intrusive singly-linked edge nodes in a dense pool:
   --  Head(V) is the first directed edge index for V (0 = none);
   --  To(E) / Weight(E) / Next(E) store the head, weight, and remainder.
   --  Undirected Add_Edge appends two directed nodes (or one for a loop).
   --  Undirected_Edges mirrors the logical undirected multiset for Kruskal.
   type Head_Array is array (Vertex_Id) of Natural;
   type To_Array is array (Dir_Index) of Vertex_Id;
   type Weight_Array is array (Dir_Index) of Weight_Type;
   type Next_Array is array (Dir_Index) of Natural;

   type Undirected_Edge_Array is array (1 .. Max_Edges) of Edge_Record;

   type Graph is limited record
      N               : Natural := 0;
      M               : Edge_Count_T := 0;
      Dir_E           : Dir_Count_T := 0;
      Head            : Head_Array := [others => 0];
      To              : To_Array := [others => Vertex_Id'First];
      Weight          : Weight_Array := [others => 0];
      Next            : Next_Array := [others => 0];
      Undirected      : Undirected_Edge_Array;
   end record;

end Prims_Algorithm;
