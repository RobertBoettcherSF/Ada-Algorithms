--  Longest_Path_Problem — Ada 2023 educational package for the longest
--  path problem: find a simple path of maximum length (edge count or
--  total edge weight) in a graph. In general the problem is NP-hard
--  (Hamiltonian-path reduction); this sheet provides two educational
--  solvers:
--    * DAG_Longest_Path — linear-time DP after topological sort on a
--      directed acyclic graph (critical-path style); reports / raises
--      when a cycle is present;
--    * Exact_Simple_Path — exhaustive DFS / backtracking with a bitset
--      visited mask for small N (≤ Max_Exact_Vertices), directed
--      digraphs (model undirected by adding both arcs).
--  Shared digraph API with optional unit weights (hop count) or
--  non-negative weighted sums. Vertices indexed from 1. Fixed educational
--  arrays (no dynamic heap). Max_Vertices supports larger DAG instances;
--  exact search is capped separately.
--  Reference: https://en.wikipedia.org/wiki/Longest_path_problem
--  Sibling sheets (README only — do not `with`): Shortest Path Problem,
--  Dijkstra — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Longest_Path_Problem
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   --  DAG routines may use the full range; exact search is capped below.
   Max_Vertices : constant Positive := 256;

   --  Maximum N for Exact_Simple_Path (bitset DFS). Raise Invalid_Argument
   --  when Vertex_Count(G) > Max_Exact_Vertices on exact APIs.
   Max_Exact_Vertices : constant Positive := 20;

   --  Maximum number of directed weighted edges (parallel edges allowed;
   --  each Add_Edge consumes one slot until Clear).
   Max_Edges : constant Positive := 50_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, weights, distances, paths
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Non-negative edge weight stored after Add_Edge validation.
   --  Unit weight 1 models unweighted hop count.
   type Weight_Type is range 0 .. 2**31 - 1;

   --  Path / cumulative weights along a simple path (sum of edge weights).
   --  A single-vertex path has weight 0. Infinity marks unreachable
   --  vertices in DAG_Longest_From.
   type Distance_Value is range 0 .. 2**63 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   type Distance_Array is array (Vertex_Id range <>) of Distance_Value;

   --  Prev(V) = predecessor of V on a reconstructed longest-path branch,
   --  or 0 if none (path start / unreachable).
   type Prev_Array is array (Vertex_Id range <>) of Natural;

   --  Vertex sequence: Path(1) .. Path(Length). Length is the number of
   --  vertices (arc count = Length − 1 when Length ≥ 1). Weight is the
   --  sum of edge weights along that walk (0 when Length ≤ 1).
   type Path_Array is array (Positive range <>) of Vertex_Id;

   ---------------------------------------------------------------------------
   -- Status / exceptions
   ---------------------------------------------------------------------------

   type Run_Status is (Success, Cycle_Detected);
   --  Success: Path / Weight / Dist hold a valid DAG result.
   --  Cycle_Detected: G is not a DAG; outputs are cleared / undefined.

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, negative edge weights, Weight outside
   --  Weight_Type, N = 0 on search APIs, Exact when N > Max_Exact_Vertices,
   --  or Path / Dist / Prev bounds that cannot hold the result
   --  (First /= 1 or Last < N when N > 0).

   Cycle_Error : exception;
   --  Raised by raising DAG overloads when a directed cycle is detected.

   ---------------------------------------------------------------------------
   -- Directed weighted graph (adjacency lists, non-negative weights)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty digraph on vertices 1 .. Vertex_Count (no edges).
   --  Vertex_Count = 0 yields an empty graph. Raises Invalid_Argument when
   --  Vertex_Count > Max_Vertices.

   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id)
     with Global => null;
   --  Append a directed unit-weight edge From → To (Weight = 1). Convenience
   --  for unweighted / hop-count longest paths.

   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Weight : Integer)
     with Global => null;
   --  Append a directed edge From → To with non-negative Weight.
   --  Parallel edges are permitted. Self-loops are permitted (they make
   --  the digraph cyclic for DAG routines; Exact never revisits a vertex).
   --  Raises Invalid_Argument when Weight < 0, when From or To is outside
   --  1 .. Vertex_Count(G), or when Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of directed edges currently stored in G.

   function Is_Acyclic (G : Graph) return Boolean
     with Global => null;
   --  True iff G has no directed cycle (Kahn topological pass). Vacuous
   --  True when N = 0.

   ---------------------------------------------------------------------------
   -- DAG_Longest_Path — linear-time DP on a directed acyclic graph
   ---------------------------------------------------------------------------
   --  Topological order + one DP pass: for each v, Dist(v) is the maximum
   --  total edge weight of a path ending at v (0 if v has no in-edges used).
   --  The global longest path is reconstructed from an argmax Dist vertex.
   --  Time O(V+E). Rejected when G has a cycle. Critical-path scheduling
   --  is the classic application.

   procedure DAG_Longest_Path
     (G      : Graph;
      Path   : out Path_Array;
      Length : out Natural;
      Weight : out Distance_Value;
      Status : out Run_Status)
     with Global => null;
   --  Global longest simple path in DAG G (by total edge weight). On
   --  Success, Path(1 .. Length) is one such path and Weight its sum.
   --  On Cycle_Detected, Length = 0 and Weight = 0. Requires Path'First = 1
   --  and Path'Last >= N when N > 0; raises Invalid_Argument when N = 0
   --  or Path bounds are insufficient.

   procedure DAG_Longest_Path
     (G      : Graph;
      Path   : out Path_Array;
      Length : out Natural;
      Weight : out Distance_Value)
     with Global => null;
   --  Raising overload: Cycle_Detected ⇒ raises Cycle_Error.

   procedure DAG_Longest_From
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array;
      Status : out Run_Status)
     with Global => null;
   --  Longest paths from Source in a DAG. Dist(Source) = 0; Dist(V) is
   --  the maximum Source→V weight when reachable, else Infinity.
   --  Prev encodes one such tree (Prev(Source) = 0). Status =
   --  Cycle_Detected when G is not a DAG. Requires Dist/Prev First = 1
   --  and Last >= N; N > 0; Source in 1 .. N.

   function DAG_Longest_Weight (G : Graph) return Distance_Value
     with Global => null;
   --  Weight of a global longest path in DAG G. Raises Cycle_Error on a
   --  cycle; Invalid_Argument when N = 0.

   ---------------------------------------------------------------------------
   -- Exact_Simple_Path — exhaustive DFS for small N (NP-hard in general)
   ---------------------------------------------------------------------------
   --  Backtracking over all simple paths with a bitset visited mask.
   --  Requires N ≤ Max_Exact_Vertices. Works on directed graphs; for an
   --  undirected graph, insert both directions with Add_Edge. Maximizes
   --  total edge weight (unit weights ⇒ maximum hop count). Time
   --  exponential in N — educational only.

   procedure Exact_Simple_Path
     (G      : Graph;
      Path   : out Path_Array;
      Length : out Natural;
      Weight : out Distance_Value)
     with Global => null;
   --  A globally longest simple path (max total weight; ties: more
   --  vertices, then smaller Path(1), then lexicographically smaller
   --  Path sequence). Raises Invalid_Argument when N = 0,
   --  N > Max_Exact_Vertices, or Path'First /= 1 or Path'Last < N.

   procedure Exact_Simple_Path
     (G              : Graph;
      Source, Target : Vertex_Id;
      Path           : out Path_Array;
      Length         : out Natural;
      Weight         : out Distance_Value;
      Found          : out Boolean)
     with Global => null;
   --  Longest simple Source→Target path by total weight. Found = False
   --  and Length = 0 when none exists. Source = Target ⇒ Found = True,
   --  Length = 1, Weight = 0. Raises Invalid_Argument on bad ids / N /
   --  Path bounds / N > Max_Exact_Vertices.

   procedure Exact_Simple_Path_From
     (G      : Graph;
      Source : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural;
      Weight : out Distance_Value)
     with Global => null;
   --  Longest simple path that starts at Source. For N > 0 always returns
   --  at least the singleton (Length = 1, Weight = 0). Raises
   --  Invalid_Argument on bad Source / N / bounds / N > Max_Exact_Vertices.

   ---------------------------------------------------------------------------
   -- Path reconstruction from Prev (DAG_Longest_From tree)
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
   --  Returns False and Length=0 when unreachable.

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

end Longest_Path_Problem;
