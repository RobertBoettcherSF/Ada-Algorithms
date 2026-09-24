--  Hyperlink-Induced Topic Search (HITS) — Ada 2023 educational package
--  for Kleinberg hubs & authorities on a directed graph (Kleinberg, 1999).
--  Builds an unweighted digraph and iterates the mutual updates
--    a ← Aᵀ h ,   h ← A a
--  with L2 normalization of each vector every iteration, until the L1
--  change of (a,h) falls below Tolerance or Max_Iters is reached.
--  Vertices indexed from 1. Fixed educational arrays (no dynamic heap).
--  Float scores with SPARK_Mode => Off for clarity.
--  Primary source: https://en.wikipedia.org/wiki/HITS_algorithm
--  Sibling sheets (README only — do not `with`): PageRank, TrustRank —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Hyperlink_Induced_Topic_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 1_024;

   --  Maximum number of directed unweighted links (parallel edges allowed;
   --  each Add_Edge consumes one slot until Clear).
   Max_Edges : constant Positive := 50_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers and score vectors
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Authority or hub scores after Compute (non-negative; L2-normalized
   --  so ‖·‖₂ ≈ 1 when the graph has at least one contributing edge).
   type Score_Array is array (Vertex_Id range <>) of Float;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, Tolerance < 0, Score_Array bounds that
   --  cannot hold the result (First /= 1 or Last < Vertex_Count when
   --  N > 0), or Compute on an empty graph (N = 0).

   ---------------------------------------------------------------------------
   -- Directed unweighted link graph (adjacency lists)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty digraph on vertices 1 .. Vertex_Count (no edges).
   --  Vertex_Count = 0 yields an empty graph. Raises Invalid_Argument when
   --  Vertex_Count > Max_Vertices.

   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id)
     with Global => null;
   --  Append a directed unweighted link From → To. Parallel edges and
   --  self-loops are permitted. Raises Invalid_Argument when From or To
   --  is outside 1 .. Vertex_Count(G), or when Edge_Count would exceed
   --  Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of directed links currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Kleinberg HITS)
   ---------------------------------------------------------------------------
   --  Let A be the (unweighted) adjacency matrix of G: A(u,v) = 1 iff u → v
   --  (with multiplicity for parallel edges). HITS maintains authority
   --  scores a and hub scores h, initialized to the all-ones vector, and
   --  iterates:
   --    a ← Aᵀ h     (authority = sum of hubs that point here)
   --    h ← A  a     (hub       = sum of authorities this page points to)
   --  After each of the two updates the corresponding vector is
   --  L2-normalized (‖x‖₂ = 1), matching Kleinberg / Wikipedia. Iteration
   --  stops when ‖a'−a‖₁ + ‖h'−h‖₁ ≤ Tolerance or Max_Iters steps elapse.
   --  Relation to PageRank / TrustRank (README only): those maintain a
   --  single random-walk score; HITS keeps a mutually reinforcing hub /
   --  authority pair and is typically query-dependent on a focused subgraph.

   procedure Compute
     (G           : Graph;
      Max_Iters   : Positive := 100;
      Tolerance   : Float := 1.0e-6;
      Authorities : out Score_Array;
      Hubs        : out Score_Array;
      Iterations  : out Natural)
     with Global => null;
   --  Run Kleinberg HITS. On success Authorities(1 .. N) and Hubs(1 .. N)
   --  hold approximate L2-normalized scores (non-negative) and Iterations
   --  is the number of outer steps performed (1 .. Max_Iters). Requires
   --  Authorities'First = Hubs'First = 1 and both Last >= N. Raises
   --  Invalid_Argument when N = 0, when Tolerance < 0.0, or when score
   --  array bounds are wrong. An edgeless graph yields all-zero scores
   --  (zero L2 norms skip renormalization).

   function Score_Of
     (Scores : Score_Array; V : Vertex_Id) return Float
     with Global => null;
   --  Convenience accessor: Scores(V). Raises Invalid_Argument when V
   --  is outside Scores'Range.

private

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Edge_Index is Positive range 1 .. Max_Edges;

   --  Dual adjacency via intrusive singly-linked edge nodes in dense pools:
   --  Out_Head(V) / In_Head(V) are first edge indices (0 = none);
   --  Out_To / In_From store the neighbor; Out_Next / In_Next the remainder.
   --  Each Add_Edge allocates one out-slot and one in-slot.
   type Head_Array is array (Vertex_Id) of Natural;
   type Neighbor_Array is array (Edge_Index) of Vertex_Id;
   type Next_Array is array (Edge_Index) of Natural;

   type Graph is limited record
      N       : Natural := 0;
      E       : Edge_Count_T := 0;
      Out_Head : Head_Array := [others => 0];
      Out_To   : Neighbor_Array;
      Out_Next : Next_Array := [others => 0];
      In_Head  : Head_Array := [others => 0];
      In_From  : Neighbor_Array;
      In_Next  : Next_Array := [others => 0];
   end record;

end Hyperlink_Induced_Topic_Search;
