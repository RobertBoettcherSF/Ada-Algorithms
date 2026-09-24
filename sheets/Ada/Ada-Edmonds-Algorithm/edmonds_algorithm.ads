--  Edmonds_Algorithm — Ada 2023 educational package for the
--  Chu–Liu/Edmonds algorithm that builds a minimum spanning arborescence
--  (optimum branching) of a directed weighted graph rooted at a given
--  vertex R. For each non-root vertex choose a cheapest incoming edge;
--  if the selection contains a cycle, contract it, adjust weights of
--  edges entering the cycle, recurse, then expand. Vertices indexed
--  from 1. Fixed educational arrays sized to Max_Vertices / Max_Edges
--  (no dynamic heap). Integer edge weights may be negative (the
--  algorithm permits arbitrary real weights; document). Optional
--  Brute_Minimum_Arborescence oracle for N ≤ 8 cross-checks.
--  Reference: https://en.wikipedia.org/wiki/Edmonds%27_algorithm
--  Sibling sheets (README only — do not `with`): Minimum Spanning Tree,
--  Kruskal, Dijkstra — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Edmonds_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 256;

   --  Maximum number of directed weighted edges (parallel edges allowed;
   --  each Add_Edge consumes one slot until Clear).
   Max_Edges : constant Positive := 10_000;

   --  Brute-force oracle is offered only for graphs with
   --  Vertex_Count ≤ Brute_Max_Vertices (combinatorial product of
   --  in-degrees).
   Brute_Max_Vertices : constant Positive := 8;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, weights, edge records
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Edge weight stored after Add_Edge. May be negative; Chu–Liu/Edmonds
   --  admits arbitrary real weights (no non-negativity requirement).
   --  Add_Edge accepts Integer and raises Invalid_Argument when Weight
   --  is outside Weight_Type.
   type Weight_Type is range -(2**30) .. 2**30 - 1;

   --  Sum of kept arborescence edge weights (may be negative).
   type Weight_Sum is range -(2**62) .. 2**62 - 1;

   --  One directed edge From → To with Weight. Self-loops permitted in
   --  the input but never appear in an arborescence. Parallel edges
   --  compete by weight.
   type Edge_Record is record
      From, To : Vertex_Id;
      Weight   : Weight_Type;
   end record;

   --  Caller-supplied buffer for kept arborescence edges.
   type Edge_List is array (Positive range <>) of Edge_Record;

   ---------------------------------------------------------------------------
   -- Status / exceptions
   ---------------------------------------------------------------------------

   type Run_Status is (Success, Impossible);
   --  Success: Tree_Edges / Total_Weight describe a minimum spanning
   --  arborescence rooted at Root (exactly N−1 edges when N ≥ 1).
   --  Impossible: no spanning arborescence rooted at Root exists
   --  (some vertex unreachable from Root via directed paths in the
   --  sense of the arborescence problem — equivalently, some non-root
   --  vertex has no usable incoming edge after contractions).

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, Weight outside Weight_Type, Root outside
   --  1 .. N, N = 0 on search APIs, or Tree_Edges bounds that cannot
   --  hold the result (First /= 1 or Last < N−1 when N > 0).

   Impossible_Arborescence : exception;
   --  Raised by the raising Minimum_Arborescence overload when no
   --  spanning arborescence rooted at Root exists.

   ---------------------------------------------------------------------------
   -- Directed weighted graph (edge list; weights may be negative)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty digraph on vertices 1 .. Vertex_Count (no
   --  edges). Vertex_Count = 0 yields an empty graph. Raises
   --  Invalid_Argument when Vertex_Count > Max_Vertices.

   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Weight : Integer)
     with Global => null;
   --  Append a directed edge From → To with Weight (may be negative).
   --  Parallel edges are permitted. Self-loops are permitted (they are
   --  never selected). Raises Invalid_Argument when Weight is outside
   --  Weight_Type, when From or To is outside 1 .. Vertex_Count(G), or
   --  when Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of directed edges currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Chu–Liu / Edmonds)
   ---------------------------------------------------------------------------
   --  Discard edges whose head is the root (and ignore self-loops).
   --  For each non-root v, let π(v) be a cheapest incoming edge.
   --  If P = {(π(v), v)} is acyclic, P is a minimum spanning arborescence.
   --  Otherwise pick a cycle C ⊂ P, contract C to a supernode v_C, and
   --  reweight every edge (u, v) with v ∈ C, u ∉ C by
   --    w'(u, v_C) = w(u, v) − w(π(v), v).
   --  Recurse on the contracted digraph; expand by restoring C minus the
   --  unique cycle edge whose head is the entry point of the edge chosen
   --  into v_C. Educational recursive contraction; O(V E) typical.
   --  Contrast (README only): undirected MST (Kruskal / Prim) has no
   --  distinguished root and uses undirected edges.

   procedure Minimum_Arborescence
     (G            : Graph;
      Root         : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum;
      Status       : out Run_Status)
     with Global => null;
   --  Chu–Liu/Edmonds minimum spanning arborescence of G rooted at Root.
   --  On Success, Tree_Count = N−1 edges are written to
   --  Tree_Edges(1 .. Tree_Count) and Total_Weight is their weight sum
   --  (N = Vertex_Count(G)). On Impossible, Tree_Count = 0 and
   --  Total_Weight = 0. Requires N ≥ 1, Root in 1 .. N, Tree_Edges'First
   --  = 1 and Tree_Edges'Last >= N−1; raises Invalid_Argument otherwise.
   --  Vacuous: N = 0 raises Invalid_Argument.

   procedure Minimum_Arborescence
     (G            : Graph;
      Root         : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
     with Global => null;
   --  Raising overload: same as the Status form, but raises
   --  Impossible_Arborescence when Status would be Impossible.

   procedure Edmonds
     (G            : Graph;
      Root         : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum;
      Status       : out Run_Status)
     with Global => null;
   --  Alias of Minimum_Arborescence with Status (same contract).

   ---------------------------------------------------------------------------
   -- Optional brute-force oracle (N ≤ Brute_Max_Vertices)
   ---------------------------------------------------------------------------
   --  Enumerate every choice of one incoming edge per non-root vertex
   --  and retain a minimum-weight spanning arborescence (if any).
   --  Self-contained cross-check — no `with` of sibling packages.

   procedure Brute_Minimum_Arborescence
     (G            : Graph;
      Root         : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum;
      Status       : out Run_Status)
     with Global => null;
   --  Exact oracle for N ≤ Brute_Max_Vertices. Raises Invalid_Argument
   --  when N = 0, N > Brute_Max_Vertices, Root outside 1 .. N, or
   --  Tree_Edges bounds are insufficient (same First/Last rules as
   --  Minimum_Arborescence).

private

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Edge_Index is Positive range 1 .. Max_Edges;

   type Edge_Array is array (Edge_Index) of Edge_Record;

   type Graph is limited record
      N     : Natural := 0;
      M     : Edge_Count_T := 0;
      Edges : Edge_Array :=
        [others => (From => Vertex_Id'First, To => Vertex_Id'First, Weight => 0)];
   end record;

end Edmonds_Algorithm;
