--  Shortest_Path_Problem — Ada 2023 educational survey package for the
--  classical shortest-path problem on directed graphs: find a path of
--  minimum total edge weight between vertices (single-source or
--  all-pairs). Self-contained educational re-implementations of the
--  standard methods (do NOT `with` sibling packages):
--    * BFS_Shortest — unit / unweighted SSSP (every edge length 1);
--    * Dijkstra — dense O(V^2) SSSP for non-negative weights;
--    * Bellman_Ford — SSSP with negatives + negative-cycle status;
--    * Floyd_Warshall — dense O(V^3) all-pairs DP (negatives OK).
--  Shared digraph API, Infinity sentinel, Dist / Prev helpers, and
--  Reconstruct_Path. Vertices indexed from 1. Fixed educational arrays
--  sized to Max_Vertices / Max_Edges (no dynamic heap).
--  Reference: https://en.wikipedia.org/wiki/Shortest_path_problem
--  Sibling sheets (README only — do not `with`): Dijkstra, Bellman–Ford,
--  Floyd–Warshall, Johnson — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Shortest_Path_Problem
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   --  Sized so an N×N Dist_Matrix fits educational workspace (APSP).
   Max_Vertices : constant Positive := 256;

   --  Maximum number of directed weighted edges (parallel edges allowed;
   --  each Add_Edge consumes one slot until Clear).
   Max_Edges : constant Positive := 50_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, weights, distances, matrices, paths
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Edge weight stored after Add_Edge. May be negative; method choice
   --  depends on the weight class (see procedure comments / README).
   type Weight_Type is range -(2**30) .. 2**30 - 1;

   --  Path / cumulative distances. May be negative when negative edges
   --  are present. Infinity marks unreachable vertices / pairs.
   type Distance_Value is range -(2**62) .. 2**62 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   type Distance_Array is array (Vertex_Id range <>) of Distance_Value;

   --  Dist(U, V) = shortest U→V distance (Infinity if unreachable).
   type Dist_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Distance_Value;

   --  Prev(V) = predecessor of V on a shortest Source→V path, or 0 if
   --  none (Source itself, or unreachable / undefined under a cycle).
   type Prev_Array is array (Vertex_Id range <>) of Natural;

   --  Prev(U, V) = predecessor of V on a shortest U→V path, or 0 if none.
   type Prev_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Natural;

   --  Vertex sequence for a Source→Target walk: Path(1) = Source,
   --  Path(Length) = Target when Length > 0. Length is the number of
   --  vertices (arc count = Length − 1 when Length ≥ 1).
   type Path_Array is array (Positive range <>) of Vertex_Id;

   ---------------------------------------------------------------------------
   -- Status / exceptions
   ---------------------------------------------------------------------------

   type Run_Status is (Success, Negative_Cycle);
   --  Success: Dist / Prev hold a valid result.
   --  Negative_Cycle: a negative-weight cycle was detected; Dist / Prev
   --  may be filled but are not numerically meaningful for affected
   --  vertices / pairs.

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, Weight outside Weight_Type, Dist / Prev /
   --  Path bounds that cannot hold the result (First /= 1 or Last < N
   --  when N > 0), N = 0 on search APIs, or Dijkstra when a negative
   --  edge weight is present in G.

   Negative_Cycle_Error : exception;
   --  Raised by raising Bellman_Ford / Floyd_Warshall / Distance_*
   --  overloads when a negative-weight cycle is detected.

   ---------------------------------------------------------------------------
   -- Directed weighted graph (adjacency lists; weights may be signed)
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
   --  Parallel edges are permitted (relaxation / BFS hop uses the
   --  stored arcs). Self-loops are permitted. Raises Invalid_Argument
   --  when Weight is outside Weight_Type, when From or To is outside
   --  1 .. Vertex_Count(G), or when Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of directed edges currently stored in G.

   function Has_Negative_Edge (G : Graph) return Boolean
     with Global => null;
   --  True iff some stored edge has Weight < 0. Useful to choose between
   --  Dijkstra and Bellman–Ford / Floyd–Warshall.

   ---------------------------------------------------------------------------
   -- BFS_Shortest — unit / unweighted SSSP (every edge length 1)
   ---------------------------------------------------------------------------
   --  Applies when all edges have equal positive length, or when the
   --  problem is hop-count / unweighted reachability. Ignores stored
   --  Weight values and treats every edge as cost 1. Time O(V+E).
   --  Incorrect for genuine unequal weights (use Dijkstra / BF / FW).

   procedure BFS_Shortest
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array)
     with Global => null;
   --  Breadth-first SSSP from Source. Dist(V) is the fewest edges on a
   --  Source→V path (Infinity if unreachable); Prev encodes a BFS tree.
   --  Requires Dist/Prev First = 1 and Last >= N; N > 0; Source in 1 .. N.

   function Distance_BFS
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
     with Global => null;
   --  Hop-count Source→Target, or Infinity if unreachable.

   ---------------------------------------------------------------------------
   -- Dijkstra — dense O(V^2) SSSP for non-negative weights
   ---------------------------------------------------------------------------
   --  Applies when every edge weight is ≥ 0. Raises Invalid_Argument if
   --  Has_Negative_Edge(G). Classic unsettled-min scan (Dijkstra 1959).
   --  Time Θ(V^2 + E). Prefer heap variants for sparse graphs in practice;
   --  this sheet keeps the dense educational form.

   procedure Dijkstra
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array)
     with Global => null;
   --  Dense Dijkstra from Source. Dist(V) shortest Source→V (Infinity if
   --  unreachable); Prev is a shortest-path tree (Prev(Source)=0).

   function Distance_Dijkstra
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
     with Global => null;
   --  Shortest Source→Target under non-negative weights, or Infinity.

   ---------------------------------------------------------------------------
   -- Bellman_Ford — SSSP with negatives + negative-cycle status
   ---------------------------------------------------------------------------
   --  Applies when weights may be negative. Classic |V|−1 full-edge
   --  relaxations plus one extra pass. Time O(VE). Prefer Dijkstra when
   --  all weights are non-negative.

   procedure Bellman_Ford
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array;
      Status : out Run_Status)
     with Global => null;
   --  On Success, Dist/Prev hold a valid SSSP tree. On Negative_Cycle, a
   --  negative-weight cycle is reachable from Source.

   procedure Bellman_Ford
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array)
     with Global => null;
   --  Raising overload: Success ⇒ filled; Negative_Cycle ⇒
   --  raises Negative_Cycle_Error.

   function Has_Negative_Cycle
     (G : Graph; Source : Vertex_Id) return Boolean
     with Global => null;
   --  True iff Bellman–Ford from Source detects a negative cycle
   --  reachable from Source.

   function Distance_Bellman_Ford
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
     with Global => null;
   --  Shortest Source→Target, or Infinity. Raises Negative_Cycle_Error
   --  when a negative cycle is reachable from Source.

   ---------------------------------------------------------------------------
   -- Floyd_Warshall — dense O(V^3) all-pairs DP
   ---------------------------------------------------------------------------
   --  Applies for all-pairs on dense digraphs; weights may be negative.
   --  Detects a negative cycle via Dist(V,V) < 0. Prefer repeated Dijkstra
   --  (non-neg) or Johnson (sparse + negatives, no cycles) for large
   --  sparse instances — see sibling sheets.

   procedure Floyd_Warshall
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Status : out Run_Status)
     with Global => null;
   --  Init Dist from G, run Floyd–Warshall. Status = Negative_Cycle when
   --  any Dist(V,V) < 0. Requires Dist First = 1, Last >= N; N > 0.

   procedure Floyd_Warshall
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Prev   : out Prev_Matrix;
      Status : out Run_Status)
     with Global => null;
   --  Same with Prev predecessor matrix for path reconstruction.

   procedure Floyd_Warshall
     (G    : Graph;
      Dist : out Dist_Matrix;
      Prev : out Prev_Matrix)
     with Global => null;
   --  Raising overload with Prev: Negative_Cycle ⇒ Negative_Cycle_Error.

   function Has_Negative_Cycle_APSP (G : Graph) return Boolean
     with Global => null;
   --  True iff Floyd–Warshall on G yields some Dist(V,V) < 0.
   --  Raises Invalid_Argument when N = 0.

   function Distance_Floyd_Warshall
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
     with Global => null;
   --  Shortest Source→Target via a full APSP run, or Infinity.
   --  Raises Negative_Cycle_Error on a negative cycle.

   ---------------------------------------------------------------------------
   -- Path reconstruction (shared Prev-array / Prev-matrix helpers)
   ---------------------------------------------------------------------------

   function Reconstruct_Path
     (Prev   : Prev_Array;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Walk Prev from Target back to Source and reverse into Path.
   --  Returns True with Path(1)=Source … Path(Length)=Target when a path
   --  exists (including Source=Target with Length=1 when Prev(Source)=0).
   --  Returns False and Length=0 when unreachable. Requires Path'First=1
   --  and Path'Last >= Prev'Last; raises Invalid_Argument on bad bounds.

   function Reconstruct_Path
     (Prev   : Prev_Matrix;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Walk Prev(Source, ·) from Target back to Source (APSP Prev row).

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

end Shortest_Path_Problem;
