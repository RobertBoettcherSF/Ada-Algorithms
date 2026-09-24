--  Johnsons_Algorithm — Ada 2023 educational package for Johnson's
--  all-pairs shortest paths on directed graphs that may contain negative
--  edge weights but must not contain a negative-weight cycle. Named after
--  Donald B. Johnson (1977). Pipeline:
--    1. Add a virtual super-source q with 0-weight edges to every vertex.
--    2. Bellman–Ford from q → potentials h(v).
--    3. Reweight every edge: w'(u,v) = w(u,v) + h(u) − h(v) ≥ 0.
--    4. Dense Dijkstra from every vertex on the reweighted digraph;
--       recover original distances via d(u,v) = d'(u,v) + h(v) − h(u).
--  Bellman–Ford and dense Dijkstra are implemented inside this package
--  (self-contained; do not `with` sibling packages).
--  Vertices indexed from 1. Fixed educational arrays sized to
--  Max_Vertices / Max_Edges (no dynamic heap).
--  Reference: https://en.wikipedia.org/wiki/Johnson%27s_algorithm
--  Sibling sheets (README only — do not `with`): Dijkstra, Floyd–Warshall,
--  Bellman–Ford — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Johnsons_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   --  Sized for an N×N distance matrix in educational stack/workspace.
   Max_Vertices : constant Positive := 256;

   --  Maximum number of directed weighted edges (parallel edges allowed;
   --  each Add_Edge consumes one slot until Clear).
   Max_Edges : constant Positive := 50_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, weights, distances, matrices, paths
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Edge weight stored after Add_Edge. May be negative; negative cycles
   --  are detected by Johnson / All_Pairs (not at Add_Edge time).
   type Weight_Type is range -(2**30) .. 2**30 - 1;

   --  Path / cumulative distances. May be negative when negative edges are
   --  present. Infinity marks unreachable pairs.
   type Distance_Value is range -(2**62) .. 2**62 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   type Distance_Array is array (Vertex_Id range <>) of Distance_Value;

   --  Dist(U, V) = shortest U→V distance (Infinity if unreachable).
   type Dist_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Distance_Value;

   --  Prev(U, V) = predecessor of V on a shortest U→V path, or 0 if none
   --  (U itself on the diagonal, or unreachable).
   type Prev_Array is array (Vertex_Id range <>) of Natural;
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
   --  Success: Dist / Prev hold a valid all-pairs result.
   --  Negative_Cycle: a negative-weight cycle is reachable (from the
   --  virtual super-source, i.e. anywhere in the digraph); Dist / Prev
   --  are unspecified.

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, Weight outside Weight_Type, Dist / Prev /
   --  Path bounds that cannot hold the result (First /= 1 or Last < N
   --  when N > 0), or N = 0 on search APIs.

   Negative_Cycle_Error : exception;
   --  Raised by the raising overloads of Johnson / All_Pairs when a
   --  negative-weight cycle is detected.

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
   -- Algorithm sketch (Johnson 1977)
   ---------------------------------------------------------------------------
   --  Potentials: imagine super-source q with edges q→v of weight 0 for
   --  every v. Bellman–Ford from q yields h(v) = δ(q,v). Equivalent
   --  implementation: initialise h(v)←0 for all v, then relax original
   --  edges |V|−1 times; one extra pass detects a negative cycle.
   --  Reweight: w'(u,v) = w(u,v) + h(u) − h(v). Every s–t path gains the
   --  same additive h(s)−h(t), so shortest paths are preserved and
   --  w' ≥ 0 when no negative cycle exists.
   --  Dijkstra: for each source s run dense O(V^2) Dijkstra on w'; fill
   --  Dist'(s,·) and Prev(s,·); recover Dist(s,v) = Dist'(s,v)+h(v)−h(s)
   --  (Infinity stays Infinity).
   --  Time O(V·E + V^2 log V) with heaps; this sheet uses dense Dijkstra
   --  ⇒ O(V·E + V^3) educational bound. Sparse graphs beat Floyd–Warshall
   --  O(V^3) when E ≪ V^2 and a heap Dijkstra is used; dense scan here
   --  keeps the sheet free of priority-queue machinery.

   procedure All_Pairs
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Prev   : out Prev_Matrix;
      Status : out Run_Status)
     with Global => null;
   --  Johnson APSP. On Success, Dist(U,V) is the shortest U→V distance
   --  (Infinity if unreachable) and Prev encodes predecessor trees per
   --  source (Prev(U,U) = 0). On Negative_Cycle, Dist/Prev are unspecified.
   --  Requires Dist/Prev First = 1 and Last >= N on both dims when N > 0;
   --  raises Invalid_Argument otherwise, or when N = 0.

   procedure All_Pairs
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Status : out Run_Status)
     with Global => null;
   --  Same as All_Pairs with Prev, but does not fill a predecessor matrix
   --  (slightly less bookkeeping). Same bound / empty-graph checks.

   procedure Johnson
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Prev   : out Prev_Matrix;
      Status : out Run_Status)
     with Global => null;
   --  Alias of All_Pairs with Prev (Johnson's algorithm by name).

   procedure Johnson
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Status : out Run_Status)
     with Global => null;
   --  Alias of All_Pairs without Prev.

   procedure All_Pairs
     (G    : Graph;
      Dist : out Dist_Matrix;
      Prev : out Prev_Matrix)
     with Global => null;
   --  Raising overload: Success ⇒ Dist/Prev filled; Negative_Cycle ⇒
   --  raises Negative_Cycle_Error. Same Invalid_Argument guards.

   procedure Johnson
     (G    : Graph;
      Dist : out Dist_Matrix;
      Prev : out Prev_Matrix)
     with Global => null;
   --  Raising alias of All_Pairs with Prev.

   function Has_Negative_Cycle (G : Graph) return Boolean
     with Global => null;
   --  True iff Bellman–Ford from the virtual super-source detects a
   --  negative-weight cycle. Raises Invalid_Argument when N = 0.

   function Distance
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
     with Global => null;
   --  Shortest Source→Target distance via a full Johnson run, or Infinity
   --  if unreachable. Raises Invalid_Argument when Source/Target outside
   --  1 .. N or N = 0; raises Negative_Cycle_Error on a negative cycle.

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
   --  and Path'Last >= Prev'Last; raises Invalid_Argument when Source /
   --  Target are outside Prev'Range or Path bounds are wrong.

   function Reconstruct_Path
     (Prev   : Prev_Matrix;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Same as the Prev_Array overload, using row Prev(Source, ·).

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

end Johnsons_Algorithm;
