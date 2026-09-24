--  Bellman_Ford_Algorithm — Ada 2023 educational package for the
--  Bellman–Ford single-source shortest paths algorithm on directed graphs
--  that may contain negative edge weights. Classic |V|−1 full-edge
--  relaxations (dynamic programming on path length) plus one extra pass
--  to detect a negative-weight cycle reachable from the source. Optional
--  marking of vertices whose distances are driven to −∞ by such a cycle.
--  Vertices indexed from 1. Fixed educational arrays sized to
--  Max_Vertices / Max_Edges (no dynamic heap). Self-contained (do not
--  `with` Dijkstra / Floyd–Warshall / Johnson siblings).
--  Reference: https://en.wikipedia.org/wiki/Bellman%E2%80%93Ford_algorithm
--  Sibling sheets (README only — do not `with`): Dijkstra, Floyd–Warshall,
--  Johnson — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Bellman_Ford_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 1_000;

   --  Maximum number of directed weighted edges (parallel edges allowed;
   --  each Add_Edge consumes one slot until Clear).
   Max_Edges : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, weights, distances, paths, flags
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Edge weight stored after Add_Edge. May be negative; negative cycles
   --  are detected by Shortest_Paths (not at Add_Edge time).
   type Weight_Type is range -(2**30) .. 2**30 - 1;

   --  Path / cumulative distances. May be negative when negative edges are
   --  present. Infinity marks unreachable vertices.
   type Distance_Value is range -(2**62) .. 2**62 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   type Distance_Array is array (Vertex_Id range <>) of Distance_Value;

   --  Prev(V) = predecessor of V on a shortest Source→V path, or 0 if
   --  none (Source itself, or unreachable / undefined under a cycle).
   type Prev_Array is array (Vertex_Id range <>) of Natural;

   --  Vertex sequence for a Source→Target walk: Path(1) = Source,
   --  Path(Length) = Target when Length > 0. Length is the number of
   --  vertices (arc count = Length − 1 when Length ≥ 1).
   type Path_Array is array (Positive range <>) of Vertex_Id;

   --  Per-vertex Boolean mask (e.g. Affected_By_Negative_Cycle).
   type Flag_Array is array (Vertex_Id range <>) of Boolean;

   ---------------------------------------------------------------------------
   -- Status / exceptions
   ---------------------------------------------------------------------------

   type Run_Status is (Success, Negative_Cycle);
   --  Success: Dist / Prev hold a valid single-source result.
   --  Negative_Cycle: a negative-weight cycle is reachable from Source;
   --  Dist / Prev after |V|−1 passes are left filled but distances of
   --  vertices reachable from the cycle are not numerically meaningful.

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, Weight outside Weight_Type, Dist / Prev /
   --  Path / Flag bounds that cannot hold the result (First /= 1 or
   --  Last < N when N > 0), or N = 0 on search APIs.

   Negative_Cycle_Error : exception;
   --  Raised by the raising Shortest_Paths overload and by Distance when
   --  a negative-weight cycle reachable from Source is detected.

   ---------------------------------------------------------------------------
   -- Directed weighted graph (adjacency lists; weights may be negative)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty digraph on vertices 1 .. Vertex_Count (no edges).
   --  Vertex_Count = 0 yields an empty graph. Raises Invalid_Argument when
   --  Vertex_Count > Max_Vertices.

   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Weight : Integer)
     with Global => null;
   --  Append a directed edge From → To with Weight (may be negative).
   --  Parallel edges are permitted (relaxation uses the minimum).
   --  Self-loops are permitted. Raises Invalid_Argument when Weight is
   --  outside Weight_Type, when From or To is outside 1 .. Vertex_Count(G),
   --  or when Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of directed edges currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Bellman–Ford)
   ---------------------------------------------------------------------------
   --  Initialise Dist(v) ← ∞, Prev(v) ← 0 for all v; Dist(Source) ← 0.
   --  For i = 1 .. |V|−1, relax every edge (u,v):
   --    if Dist(u) ≠ ∞ and Dist(u) + w(u,v) < Dist(v) then
   --      Dist(v) ← Dist(u) + w(u,v); Prev(v) ← u.
   --  One extra pass: if any edge can still improve a finite Dist(u), a
   --  negative-weight cycle is reachable from Source → Negative_Cycle.
   --  Correctness: a simple shortest path has ≤ |V|−1 edges; each round
   --  finalises one more hop (induction on path length).
   --  Time O(V·E); space O(V) for Dist / Prev (plus the graph).

   procedure Shortest_Paths
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array;
      Status : out Run_Status)
     with Global => null;
   --  Classic Bellman–Ford from Source. On Success, Dist(V) is the
   --  shortest Source→V distance (Infinity if unreachable) and Prev
   --  encodes a shortest-path tree (Prev(Source) = 0). On Negative_Cycle,
   --  Dist/Prev hold the state after |V|−1 passes (not −∞-closed).
   --  Requires Dist'First = Prev'First = 1 and Dist'Last >= N,
   --  Prev'Last >= N when N > 0; raises Invalid_Argument otherwise, or
   --  when Source is outside 1 .. N, or when N = 0.

   procedure Shortest_Paths
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array)
     with Global => null;
   --  Raising overload: Success ⇒ Dist/Prev filled; Negative_Cycle ⇒
   --  raises Negative_Cycle_Error. Same Invalid_Argument guards.

   function Has_Negative_Cycle
     (G : Graph; Source : Vertex_Id) return Boolean
     with Global => null;
   --  True iff Bellman–Ford from Source detects a negative-weight cycle
   --  reachable from Source. Raises Invalid_Argument when Source is
   --  outside 1 .. N or N = 0.

   procedure Affected_By_Negative_Cycle
     (G        : Graph;
      Source   : Vertex_Id;
      Affected : out Flag_Array;
      Found    : out Boolean)
     with Global => null;
   --  After a Bellman–Ford run from Source: Found is True iff a negative
   --  cycle is reachable from Source. When Found, Affected(V) is True for
   --  every vertex V that is reachable from some vertex whose distance
   --  can still improve on the Nth pass (i.e. Dist(V) is −∞ in the
   --  extended reals). When Found is False, Affected is all False.
   --  Requires Affected'First = 1 and Affected'Last >= N; raises
   --  Invalid_Argument for bad Source / N = 0 / bounds.

   function Distance
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
     with Global => null;
   --  Shortest Source→Target distance, or Infinity if unreachable.
   --  Raises Invalid_Argument when Source or Target is outside 1 .. N
   --  or when N = 0; raises Negative_Cycle_Error on a negative cycle
   --  reachable from Source.

   function Reconstruct_Path
     (Prev   : Prev_Array;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Walk Prev from Target back to Source and reverse into Path.
   --  Returns True with Path(1) = Source … Path(Length) = Target when a
   --  path exists in the tree (including Source = Target with Length = 1
   --  when Prev(Source) = 0). Returns False and Length = 0 when Target is
   --  unreachable (Prev chain does not reach Source). Requires
   --  Path'First = 1 and Path'Last >= Prev'Last; raises Invalid_Argument
   --  when Source/Target are outside Prev'Range or Path bounds are wrong.

private

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Edge_Index is Positive range 1 .. Max_Edges;

   --  Adjacency via intrusive singly-linked edge nodes in a dense pool:
   --  Head(V) is the first edge index for V (0 = none); To(E) / Weight(E)
   --  / Next(E) store the head, weight, and remainder of the list.
   type Head_Array is array (Vertex_Id) of Natural;
   type To_Array is array (Edge_Index) of Vertex_Id;
   type Weight_Array is array (Edge_Index) of Weight_Type;
   type Next_Array is array (Edge_Index) of Natural;

   type Graph is limited record
      N      : Natural := 0;
      E      : Edge_Count_T := 0;
      Head   : Head_Array := [others => 0];
      To     : To_Array := [others => Vertex_Id'First];
      Weight : Weight_Array := [others => 0];
      Next   : Next_Array := [others => 0];
   end record;

end Bellman_Ford_Algorithm;
