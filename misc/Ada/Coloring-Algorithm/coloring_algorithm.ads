--  Coloring_Algorithm — Ada 2023 educational package for undirected
--  graph vertex coloring: greedy colouring (natural or degree-descending
--  / Welsh–Powell order), bipartiteness / 2-colouring via BFS, and exact
--  chromatic number χ(G) by backtracking for tiny graphs (N ≤ Max_Exact).
--  Vertices indexed from 1. Fixed educational arrays sized to
--  Max_Vertices / Max_Edges (no dynamic heap). Loopless undirected edges
--  via Add_Edge (U, V); self-loops rejected. Colours are positive
--  integers 1, 2, …; 0 means uncoloured.
--  Reference: https://en.wikipedia.org/wiki/Graph_coloring
--  Sibling sheets (README only — do not `with`): Backtracking, BFS,
--  Hopcroft–Karp — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Coloring_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 512;

   --  Maximum number of undirected edges (each Add_Edge stores two
   --  directed adjacency arcs; Edge_Count counts undirected edges).
   Max_Edges : constant Positive := 50_000;

   --  Chromatic_Number_Exact is restricted to graphs with
   --  Vertex_Count ≤ Max_Exact (exponential backtracking).
   Max_Exact : constant Positive := 16;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, colours, order policy
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Colour assignment: Colors (V) = 0 means uncoloured; a proper
   --  colouring uses colours in 1 .. Num_Colors with no two adjacent
   --  vertices sharing a colour.
   type Color_Array is array (Vertex_Id range <>) of Natural;

   --  Vertex processing order for Greedy_Color.
   --  Natural_Order: vertices 1, 2, …, N in index order.
   --  Degree_Descending: Welsh–Powell style — nonincreasing degree,
   --  ties broken by smaller vertex id.
   type Order_Kind is (Natural_Order, Degree_Descending);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, self-loops, Chromatic_Number_Exact when
   --  N > Max_Exact, or Color_Array bounds that cannot hold the result
   --  (First /= 1 or Last < Vertex_Count when N > 0).

   ---------------------------------------------------------------------------
   -- Undirected unweighted graph (adjacency lists; loopless)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty undirected graph on vertices 1 .. Vertex_Count
   --  (no edges). Vertex_Count = 0 yields an empty graph. Raises
   --  Invalid_Argument when Vertex_Count > Max_Vertices.

   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id)
     with Global => null;
   --  Append an undirected edge {U, V} (stored as two directed arcs).
   --  Parallel edges are permitted (they do not change colourability).
   --  Self-loops are rejected (a loop prevents any proper colouring).
   --  Raises Invalid_Argument when U = V, when U or V is outside
   --  1 .. Vertex_Count(G), or when Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of undirected edges currently stored in G (including
   --  parallel duplicates).

   function Degree (G : Graph; V : Vertex_Id) return Natural
     with Global => null;
   --  Number of adjacency arcs out of V (each undirected edge {V, W}
   --  contributes one; parallels count multiply). Raises
   --  Invalid_Argument when V is outside 1 .. Vertex_Count(G) or N = 0.

   ---------------------------------------------------------------------------
   -- Algorithm sketch
   ---------------------------------------------------------------------------
   --  Greedy: process vertices in the chosen order; assign each the
   --  smallest positive colour not used by an already-coloured neighbour.
   --  Yields a proper colouring with at most Δ+1 colours (Brooks), but
   --  not necessarily χ(G) colours.
   --  Two_Color / Is_Bipartite: BFS 2-colouring of every component;
   --  bipartite ⇔ 2-colourable (χ ≤ 2 for nonempty graphs with an edge;
   --  edgeless graphs are 1-colourable).
   --  Chromatic_Number_Exact: backtracking search for the smallest k such
   --  that a proper k-colouring exists; try k = 1, 2, … with pruning by
   --  available colours and a greedy upper bound. Restricted to N ≤ 16.
   --  χ(K_n) = n; χ(bipartite with ≥1 edge) = 2; χ(edgeless, N≥1) = 1;
   --  χ(empty N=0) = 0.

   procedure Greedy_Color
     (G          : Graph;
      Colors     : out Color_Array;
      Num_Colors : out Natural;
      Order      : Order_Kind := Natural_Order)
     with Global => null;
   --  Greedy vertex colouring. Writes Colors (1 .. N) with colours in
   --  1 .. Num_Colors (proper). N = 0 yields Num_Colors = 0. Requires
   --  Colors'First = 1 and Colors'Last >= N when N > 0; raises
   --  Invalid_Argument otherwise.

   function Is_Bipartite (G : Graph) return Boolean
     with Global => null;
   --  True iff G admits a proper 2-colouring (equivalently: every
   --  connected component is bipartite). Empty and edgeless graphs are
   --  bipartite.

   procedure Two_Color
     (G       : Graph;
      Colors  : out Color_Array;
      Success : out Boolean)
     with Global => null;
   --  Attempt a proper 2-colouring with colours {1, 2}. On Success,
   --  Colors (1 .. N) is a proper colouring using at most 2 colours
   --  (edgeless N≥1 uses only colour 1). On failure Colors may be
   --  partially filled. N = 0 ⇒ Success True, nothing written. Requires
   --  Colors'First = 1 and Colors'Last >= N when N > 0; raises
   --  Invalid_Argument otherwise.

   function Chromatic_Number_Exact (G : Graph) return Natural
     with Global => null;
   --  Exact chromatic number χ(G) by backtracking. Returns 0 when N = 0,
   --  1 when N ≥ 1 and there are no edges. Raises Invalid_Argument when
   --  N > Max_Exact.

   function Is_Proper_Coloring
     (G : Graph; Colors : Color_Array) return Boolean
     with Global => null;
   --  True iff Colors'First = 1, Colors'Last >= N (when N > 0), every
   --  vertex 1 .. N has colour ≥ 1, and no edge joins two vertices of
   --  equal colour. False (does not raise) on bound mismatch or when
   --  some colour is 0. N = 0 is vacuously proper.

   function Colors_Used
     (Colors : Color_Array; N : Natural) return Natural
     with Global => null;
   --  Number of distinct positive colour values among Colors (1 .. N).
   --  Requires Colors'First = 1 and Colors'Last >= N when N > 0; raises
   --  Invalid_Argument otherwise. Returns 0 when N = 0.

private

   --  Each undirected edge consumes two directed slots in the arc pool.
   Max_Arcs : constant Positive := 2 * Max_Edges;

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Arc_Index is Positive range 1 .. Max_Arcs;

   type Head_Array is array (Vertex_Id) of Natural;
   type To_Array is array (Arc_Index) of Vertex_Id;
   type Next_Array is array (Arc_Index) of Natural;

   type Graph is limited record
      N    : Natural := 0;
      M    : Edge_Count_T := 0;
      A    : Natural := 0;  -- directed arc count (= 2 * M when no self-loops)
      Head : Head_Array := [others => 0];
      To   : To_Array := [others => Vertex_Id'First];
      Next : Next_Array := [others => 0];
   end record;

end Coloring_Algorithm;
