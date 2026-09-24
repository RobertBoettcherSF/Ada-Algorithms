--  Floyd_Warshall_Algorithm — Ada 2023 educational package for the
--  Floyd–Warshall all-pairs shortest paths algorithm on dense directed
--  graphs. Dynamic programming over intermediate vertices (Floyd 1962;
--  related to Roy 1959 / Warshall 1962 transitive closure). Allows
--  negative edge weights; detects negative cycles via a negative
--  diagonal entry after the run. Optional Next / Prev matrices support
--  path reconstruction. Vertices indexed from 1. Fixed educational
--  dense arrays sized to Max_Vertices (no dynamic heap).
--  Reference: https://en.wikipedia.org/wiki/Floyd%E2%80%93Warshall_algorithm
--  Sibling sheets (README only — do not `with`): Johnson, Dijkstra,
--  Bellman–Ford, Transitive_Closure — RobertBoettcherSF Ada series.

pragma Ada_2022;

package Floyd_Warshall_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices (indices 1 .. Max_Vertices).
   --  Dense N×N Dist / Next / Prev matrices fit educational workspace.
   Max_Vertices : constant Positive := 256;

   --  Maximum number of directed weighted edges stored in Graph
   --  (parallel edges allowed; each Add_Edge that introduces a new
   --  ordered pair consumes one distinct-slot count until Clear; when a
   --  parallel tighter weight updates an existing pair, Edge_Count is
   --  unchanged).
   Max_Edges : constant Positive := 50_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, weights, distances, matrices, paths
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Edge weight stored after Add_Edge / Put_Edge. May be negative;
   --  negative cycles are detected by Floyd–Warshall (not at insert).
   type Weight_Type is range -(2**30) .. 2**30 - 1;

   --  Path / cumulative distances. May be negative when negative edges
   --  are present. Infinity marks unreachable pairs.
   type Distance_Value is range -(2**62) .. 2**62 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   --  Dist(U, V) = shortest U→V distance (Infinity if unreachable).
   type Dist_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Distance_Value;

   --  Next(U, V) = successor of U on a shortest U→V path, or 0 if none.
   --  Next(U, U) = U after a successful init/run (trivial path).
   type Next_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Natural;

   --  Prev(U, V) = predecessor of V on a shortest U→V path, or 0 if none.
   --  Prev(U, U) = 0 (series convention; trivial path handled specially).
   type Prev_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Natural;

   type Next_Array is array (Vertex_Id range <>) of Natural;
   type Prev_Array is array (Vertex_Id range <>) of Natural;

   --  Vertex sequence for a Source→Target walk: Path(1) = Source,
   --  Path(Length) = Target when Length > 0. Length is the number of
   --  vertices (arc count = Length − 1 when Length ≥ 1).
   type Path_Array is array (Positive range <>) of Vertex_Id;

   ---------------------------------------------------------------------------
   -- Status / exceptions
   ---------------------------------------------------------------------------

   type Run_Status is (Success, Negative_Cycle);
   --  Success: Dist (and optional Next/Prev) hold a valid APSP result.
   --  Negative_Cycle: some Dist(V,V) < 0 after the run (or detected mid-
   --  loop); Dist / Next / Prev remain filled but distances involving a
   --  negative cycle are not numerically meaningful.

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, Weight outside Weight_Type, Dist / Next /
   --  Prev / Path bounds that cannot hold the result (First /= 1 or
   --  Last < N when N > 0), or N = 0 on search APIs.

   Negative_Cycle_Error : exception;
   --  Raised by raising overloads of All_Pairs / Floyd_Warshall / Distance
   --  when a negative-weight cycle is detected.

   ---------------------------------------------------------------------------
   -- Directed weighted graph (dense weight matrix; may be negative)
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
   --  Record a directed edge From → To with Weight (may be negative).
   --  Parallel edges keep the minimum weight. Self-loops are permitted.
   --  Raises Invalid_Argument when Weight is outside Weight_Type, when
   --  From or To is outside 1 .. Vertex_Count(G), or when a new distinct
   --  pair would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of distinct directed pairs currently stored in G.

   function Has_Edge (G : Graph; From, To : Vertex_Id) return Boolean
     with Global => null;
   --  True iff an edge From → To has been stored (after min-reduction).
   --  Raises Invalid_Argument when From/To outside 1 .. N or N = 0.

   function Edge_Weight
     (G : Graph; From, To : Vertex_Id) return Distance_Value
     with Global => null;
   --  Stored weight of From → To, or Infinity if absent.
   --  Raises Invalid_Argument when From/To outside 1 .. N or N = 0.

   ---------------------------------------------------------------------------
   -- Dist matrix initialisation (Graph and/or direct edge puts)
   ---------------------------------------------------------------------------
   --  Classic init before the triple loop:
   --    Dist(i,j) ← Infinity; Dist(i,i) ← 0;
   --    for each edge (u,v,w): Dist(u,v) ← min(Dist(u,v), w).
   --  Negative self-loops make Dist(v,v) < 0 immediately.

   procedure Init_Dist (Dist : out Dist_Matrix; N : Natural)
     with Global => null;
   --  Fill the 1 .. N principal submatrix: Infinity off-diagonal, 0 on
   --  the diagonal. Requires Dist First = 1 and Last >= N on both dims
   --  when N > 0; raises Invalid_Argument otherwise, or when N = 0.

   procedure Put_Edge
     (Dist : in out Dist_Matrix; From, To : Vertex_Id; Weight : Integer)
     with Global => null;
   --  Dist(From, To) ← min(Dist(From, To), Weight). Requires From/To in
   --  Dist'Range(1)/'Range(2); raises Invalid_Argument on bad ids or
   --  Weight outside Weight_Type.

   procedure Init_Dist (G : Graph; Dist : out Dist_Matrix)
     with Global => null;
   --  Init_Dist(Dist, N) then Put_Edge every stored edge of G.
   --  Same Dist bound checks; raises Invalid_Argument when N = 0.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Floyd–Warshall DP)
   ---------------------------------------------------------------------------
   --  After init, for k, i, j in 1 .. N:
   --    d_ij^(k) = min( d_ij^(k-1), d_ik^(k-1) + d_kj^(k-1) )
   --  provided both summands are finite (Infinity absorbs).
   --  Optional bookkeeping:
   --    Next(i,j) ← Next(i,k) when the k-bypass improves;
   --    Prev(i,j) ← Prev(k,j) when the k-bypass improves.
   --  Time Θ(N³), space Θ(N²). Correct loop order is K-I-J.
   --  Negative cycle: some Dist(v,v) < 0 after (or during) the run.

   procedure All_Pairs
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Status : out Run_Status)
     with Global => null;
   --  Init Dist from G, run Floyd–Warshall. Status = Negative_Cycle when
   --  any Dist(V,V) < 0. Requires Dist First = 1, Last >= N; N > 0.

   procedure All_Pairs
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Next   : out Next_Matrix;
      Status : out Run_Status)
     with Global => null;
   --  Same with Next successor matrix for path reconstruction.

   procedure All_Pairs
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Prev   : out Prev_Matrix;
      Status : out Run_Status)
     with Global => null;
   --  Same with Prev predecessor matrix for path reconstruction.

   procedure All_Pairs
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Next   : out Next_Matrix;
      Prev   : out Prev_Matrix;
      Status : out Run_Status)
     with Global => null;
   --  Same with both Next and Prev filled.

   procedure Floyd_Warshall
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Status : out Run_Status)
     with Global => null;
   --  Alias of All_Pairs without Next/Prev.

   procedure Floyd_Warshall
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Next   : out Next_Matrix;
      Status : out Run_Status)
     with Global => null;
   --  Alias of All_Pairs with Next.

   procedure Floyd_Warshall
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Prev   : out Prev_Matrix;
      Status : out Run_Status)
     with Global => null;
   --  Alias of All_Pairs with Prev.

   procedure Floyd_Warshall
     (Dist   : in out Dist_Matrix;
      N      : Natural;
      Status : out Run_Status)
     with Global => null;
   --  In-place APSP on an already-initialised Dist (direct matrix init).
   --  Does not fill Next/Prev. Same bound / empty checks.

   procedure Floyd_Warshall
     (Dist   : in out Dist_Matrix;
      Next   : in out Next_Matrix;
      N      : Natural;
      Status : out Run_Status)
     with Global => null;
   --  In-place APSP updating Dist and Next. Next must already be
   --  initialised consistently with Dist (use Init_Next_From_Dist).

   procedure Floyd_Warshall
     (Dist   : in out Dist_Matrix;
      Prev   : in out Prev_Matrix;
      N      : Natural;
      Status : out Run_Status)
     with Global => null;
   --  In-place APSP updating Dist and Prev.

   procedure All_Pairs
     (G    : Graph;
      Dist : out Dist_Matrix;
      Next : out Next_Matrix)
     with Global => null;
   --  Raising overload with Next: Success ⇒ filled; Negative_Cycle ⇒
   --  raises Negative_Cycle_Error.

   procedure All_Pairs
     (G    : Graph;
      Dist : out Dist_Matrix;
      Prev : out Prev_Matrix)
     with Global => null;
   --  Raising overload with Prev.

   procedure Floyd_Warshall
     (G    : Graph;
      Dist : out Dist_Matrix;
      Next : out Next_Matrix)
     with Global => null;
   --  Raising alias of All_Pairs with Next.

   procedure Floyd_Warshall
     (G    : Graph;
      Dist : out Dist_Matrix;
      Prev : out Prev_Matrix)
     with Global => null;
   --  Raising alias of All_Pairs with Prev.

   procedure Init_Next_From_Dist
     (Dist : Dist_Matrix; Next : out Next_Matrix; N : Natural)
     with Global => null;
   --  Next(i,j) = j when Dist(i,j) is a finite direct estimate and i≠j;
   --  Next(i,i) = i; else 0. Call after Init_Dist / Put_Edge and before
   --  an in-place Floyd_Warshall that updates Next.

   procedure Init_Prev_From_Dist
     (Dist : Dist_Matrix; Prev : out Prev_Matrix; N : Natural)
     with Global => null;
   --  Prev(i,j) = i when Dist(i,j) is finite and i≠j; Prev(i,i) = 0;
   --  else 0. Pair with in-place Floyd_Warshall that updates Prev.

   function Has_Negative_Cycle (G : Graph) return Boolean
     with Global => null;
   --  True iff Floyd–Warshall on G yields some Dist(V,V) < 0.
   --  Raises Invalid_Argument when N = 0.

   function Has_Negative_Cycle
     (Dist : Dist_Matrix; N : Natural) return Boolean
     with Global => null;
   --  True iff Dist(V,V) < 0 for some V in 1 .. N (post-run probe).
   --  Raises Invalid_Argument when N = 0 or Dist bounds are insufficient.

   function Distance
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
     with Global => null;
   --  Shortest Source→Target via a full Floyd–Warshall run, or Infinity
   --  if unreachable. Raises Invalid_Argument when Source/Target outside
   --  1 .. N or N = 0; raises Negative_Cycle_Error on a negative cycle.

   function Reconstruct_Path
     (Next   : Next_Matrix;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Walk Next from Source toward Target into Path.
   --  Returns True with Path(1)=Source … Path(Length)=Target when a path
   --  exists (including Source=Target with Length=1).
   --  Returns False and Length=0 when unreachable. Requires Path'First=1
   --  and Path'Last >= max index needed; raises Invalid_Argument when
   --  Source/Target outside Next ranges or Path bounds are wrong.

   function Reconstruct_Path
     (Prev   : Prev_Matrix;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Walk Prev from Target back to Source and reverse into Path.
   --  Same success / failure / bound conventions as the Next overload.

   function Reconstruct_Path
     (Prev   : Prev_Array;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Single-source Prev row form (Prev(V) = predecessor of V).

private

   --  Dense weight storage: Infinity means “no edge recorded”.
   type Weight_Matrix is
     array (Vertex_Id, Vertex_Id) of Distance_Value;

   type Present_Matrix is
     array (Vertex_Id, Vertex_Id) of Boolean;

   type Graph is limited record
      N       : Natural := 0;
      E       : Natural := 0;
      Weight  : Weight_Matrix := [others => [others => Infinity]];
      Present : Present_Matrix := [others => [others => False]];
   end record;

end Floyd_Warshall_Algorithm;
