--  Dijkstras_Algorithm — Ada 2023 educational package for Dijkstra's
--  single-source shortest paths on directed graphs with non-negative
--  edge weights. Classic dense O(V^2) selection (Dijkstra 1959): at each
--  step pick the unsettled vertex with smallest tentative distance and
--  relax its outgoing edges. Vertices indexed from 1. Fixed educational
--  arrays sized to Max_Vertices / Max_Edges (no dynamic heap).
--  Reference: https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm
--  Sibling sheets (README only — do not `with`): IDDFS, Tarjan SCC,
--  Lex-BFS — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Dijkstras_Algorithm
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
   -- Vertex identifiers, weights, distances, paths
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Non-negative edge weight stored after Add_Edge validation.
   --  Add_Edge accepts Integer and raises Invalid_Argument when Weight < 0.
   type Weight_Type is range 0 .. 2**31 - 1;

   --  Path / cumulative distances. Infinity marks unreachable vertices.
   type Distance_Value is range 0 .. 2**63 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   type Distance_Array is array (Vertex_Id range <>) of Distance_Value;

   --  Prev(V) = predecessor of V on a shortest Source→V path, or 0 if
   --  none (Source itself, or unreachable).
   type Prev_Array is array (Vertex_Id range <>) of Natural;

   --  Vertex sequence for a Source→Target walk: Path(1) = Source,
   --  Path(Length) = Target when Length > 0. Length is the number of
   --  vertices (arc count = Length − 1 when Length ≥ 1).
   type Path_Array is array (Positive range <>) of Vertex_Id;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, negative edge weights, or Dist / Prev /
   --  Path bounds that cannot hold the result
   --  (First /= 1 or Last < Vertex_Count when N > 0).

   ---------------------------------------------------------------------------
   -- Directed weighted graph (adjacency lists, non-negative weights)
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
   --  Append a directed edge From → To with non-negative Weight.
   --  Parallel edges are permitted (Dijkstra uses the minimum implicitly
   --  via relaxation). Self-loops are permitted. Raises Invalid_Argument
   --  when Weight < 0, when From or To is outside 1 .. Vertex_Count(G),
   --  or when Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of directed edges currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (dense Dijkstra, O(V^2))
   ---------------------------------------------------------------------------
   --  Initialise Dist(v) ← ∞, Prev(v) ← 0 for all v; Dist(Source) ← 0.
   --  Maintain an unsettled set S = {1 .. N}. While S is nonempty:
   --    u ← argmin_{v in S} Dist(v); remove u from S.
   --    If Dist(u) = ∞ then remaining vertices are unreachable — stop.
   --    For each edge u → w with weight c:
   --      alt ← Dist(u) + c; if alt < Dist(w) then Dist(w) ← alt; Prev(w) ← u.
   --  Correct for non-negative weights: when u is settled, Dist(u) is final.
   --  Time Θ(V^2 + E) with array scan for the minimum (classic formulation).
   --  Binary-heap / Fibonacci-heap variants achieve O((V+E) log V) /
   --  O(E + V log V); this sheet uses the dense scan for clarity.

   procedure Shortest_Paths
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array)
     with Global => null;
   --  Classic Dijkstra from Source. On success Dist(V) is the shortest
   --  Source→V distance for every V in 1 .. N (Infinity if unreachable),
   --  and Prev encodes a shortest-path tree (Prev(Source) = 0). Requires
   --  Dist'First = Prev'First = 1 and Dist'Last >= N, Prev'Last >= N when
   --  N > 0; raises Invalid_Argument otherwise, or when Source is outside
   --  1 .. N, or when N = 0. Vacuous: N = 0 raises Invalid_Argument.

   function Distance
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
     with Global => null;
   --  Shortest Source→Target distance, or Infinity if unreachable.
   --  Raises Invalid_Argument when Source or Target is outside 1 .. N
   --  or when N = 0.

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

end Dijkstras_Algorithm;
