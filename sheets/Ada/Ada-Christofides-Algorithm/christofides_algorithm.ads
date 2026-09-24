--  Christofides_Algorithm — Ada 2023 educational package for the
--  Christofides–Serdyukov 3/2-approximation for metric TSP. Given a
--  complete undirected graph on vertices 1 .. N with a symmetric
--  non-negative distance matrix that is assumed to obey the triangle
--  inequality, build: (1) an MST, (2) a minimum-weight perfect matching
--  on the odd-degree MST vertices, (3) an Eulerian circuit of the
--  multigraph MST ∪ matching, (4) a Hamiltonian tour by shortcutting.
--  Also exposed: MST_Cost, Odd_Vertices, Matching_Cost, Tour_Cost, and
--  an Exact_Tour brute-force oracle for N ≤ 10. Exact matching uses
--  subset DP and is capped at Max_Matching_Odd odd vertices.
--  Reference: https://en.wikipedia.org/wiki/Christofides_algorithm
--  Sibling sheets (README only — do not `with`): Nearest Neighbour TSP,
--  VRP / CVRP, Dijkstra — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Christofides_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of cities / vertices (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 24;

   --  Exact minimum-weight perfect matching via subset DP is restricted
   --  to this many odd MST vertices (2^Max_Matching_Odd DP states).
   --  Trees can have up to N odd vertices (e.g. a star when N is even);
   --  Approximate_Tour raises Invalid_Argument when the odd set exceeds
   --  this cap. Prefer Max_Matching_Odd ≥ N, or use instances whose MST
   --  has few odd vertices (paths have exactly two).
   Max_Matching_Odd : constant Positive := 12;

   --  Exact brute-force TSP oracle is restricted to this vertex count
   --  ((N−1)! directed cycles with a fixed start).
   Max_Exact_Vertices : constant Positive := 10;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, costs, matrices, tours
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Non-negative edge / tour cost. Put_Distance accepts Integer and
   --  raises Invalid_Argument when Value < 0.
   type Cost_Value is range 0 .. 2**63 - 1;

   --  Complete-graph distance matrix on Distances'Range (1) × (2).
   --  Callers must pass a square 1-based matrix (First = 1 on both
   --  dimensions, Last(1) = Last(2) = N). The Christofides guarantee
   --  assumes a symmetric metric (c(u,v)=c(v,u) and triangle inequality);
   --  symmetry is enforced for tour construction (the undirected view
   --  uses min(c(u,v),c(v,u)) only inside helpers that need an undirected
   --  weight — public Matrix_Order / Distance return the stored entry).
   --  Triangle inequality is assumed for the 3/2 proof and is not checked
   --  at runtime; the algorithm may still run on non-metric tables.
   type Cost_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Cost_Value;

   --  Cities(1 .. N) holds a permutation of 1 .. N. Cost is the closed
   --  tour length: sum of Distances(Cities(i), Cities(i+1)) for
   --  i = 1 .. N−1, plus Distances(Cities(N), Cities(1)).
   type City_Seq is array (1 .. Max_Vertices) of Vertex_Id;

   type Tour is record
      N      : Natural := 0;
      Cities : City_Seq := [others => Vertex_Id'First];
      Cost   : Cost_Value := 0;
   end record;

   --  Ordered list of vertex ids (e.g. odd-degree MST vertices).
   type Vertex_List is record
      Count    : Natural := 0;
      Vertices : City_Seq := [others => Vertex_Id'First];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for non-square or non-1-based Cost_Matrix, N < 2 on tour /
   --  MST APIs, indices outside 1 .. N, negative distances passed to
   --  Put_Distance / Put_Symmetric, Exact_Tour when N > Max_Exact_Vertices,
   --  Matching_Cost / Approximate_Tour when the odd set size exceeds
   --  Max_Matching_Odd or is odd (corrupt input), Tour_Cost on a Tour
   --  whose N does not match the matrix order, or an odd Vertex_List
   --  Count for Matching_Cost.

   ---------------------------------------------------------------------------
   -- Matrix builders / queries
   ---------------------------------------------------------------------------

   procedure Put_Distance
     (Distances : in out Cost_Matrix;
      From, To  : Vertex_Id;
      Value     : Integer)
     with Global => null;
   --  Store a non-negative distance From → To. Raises Invalid_Argument
   --  when Value < 0 or when From / To lie outside Distances'Range.

   procedure Put_Symmetric
     (Distances : in out Cost_Matrix;
      A, B      : Vertex_Id;
      Value     : Integer)
     with Global => null;
   --  Store Value on both A → B and B → A (and once when A = B).
   --  Same guards as Put_Distance. Preferred for metric TSP instances.

   function Matrix_Order (Distances : Cost_Matrix) return Natural
     with Global => null;
   --  N = Distances'Length (1) when the matrix is square and 1-based;
   --  raises Invalid_Argument otherwise.

   function Distance
     (Distances : Cost_Matrix; From, To : Vertex_Id) return Cost_Value
     with Global => null;
   --  Matrix entry. Raises Invalid_Argument when From / To are outside
   --  Distances'Range or the matrix is not a valid square 1-based form.

   function Rounded_Euclidean
     (X1, Y1, X2, Y2 : Integer) return Cost_Value
     with Global => null;
   --  Nearest-integer Euclidean distance √((X2−X1)²+(Y2−Y1)²), for
   --  building metric test instances. Ties use Ada Float'Rounding.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Christofides–Serdyukov)
   ---------------------------------------------------------------------------
   --  Input: complete undirected metric graph on {1 .. N}, N ≥ 2, with
   --  symmetric c(u,v) ≥ 0 obeying the triangle inequality.
   --  1. T ← MST(G)           (Prim on the dense matrix; tie: smaller id)
   --  2. O ← { v : deg_T(v) odd }; |O| is even (handshaking lemma)
   --  3. M ← minimum-weight perfect matching on G[O]
   --       (subset DP for |O| ≤ Max_Matching_Odd)
   --  4. H ← multigraph (V, E(T) ∪ E(M)); every degree is even
   --  5. Find an Eulerian circuit of H (Hierholzer)
   --  6. Shortcut repeated vertices → Hamiltonian tour
   --  Guarantee (metric): cost(tour) ≤ (3/2) · OPT.
   --  Sibling nearest-neighbour sheet: greedy TSP heuristic, no 3/2
   --  guarantee — prefer that package rather than duplicating NN here.

   function Undirected_Weight
     (Distances : Cost_Matrix; A, B : Vertex_Id) return Cost_Value
     with Global => null;
   --  min(Distances(A,B), Distances(B,A)) for the undirected view used
   --  by MST / matching. Raises Invalid_Argument on bad matrix / ids.

   function MST_Cost (Distances : Cost_Matrix) return Cost_Value
     with Global => null;
   --  Weight of a minimum spanning tree (Prim). Requires N ≥ 2.
   --  Tie-break when growing the tree: smaller vertex index.

   function Odd_Vertices (Distances : Cost_Matrix) return Vertex_List
     with Global => null;
   --  Vertices of odd degree in the Prim MST, listed in increasing id
   --  order. Count is even for every tree on N ≥ 2. Requires N ≥ 2.

   function Matching_Cost
     (Distances : Cost_Matrix; Odds : Vertex_List) return Cost_Value
     with Global => null;
   --  Minimum-weight perfect matching on the complete subgraph induced
   --  by Odds (undirected weights). Odds.Count must be even, ≥ 0, and
   --  ≤ Max_Matching_Odd; each Odds.Vertices(i) must lie in 1 .. N.
   --  Count = 0 yields cost 0. Raises Invalid_Argument otherwise.

   function Closed_Tour_Cost
     (Distances : Cost_Matrix;
      Cities    : City_Seq;
      N         : Natural) return Cost_Value
     with Global => null;
   --  Sum of N closed-tour edges Cities(1)→…→Cities(N)→Cities(1)
   --  using stored directed entries Distances(A,B). Requires
   --  Matrix_Order = N ≥ 2 and each Cities(i) in 1 .. N.

   function Is_Valid_Tour (T : Tour) return Boolean
     with Global => null;
   --  True iff T.N ∈ 2 .. Max_Vertices and Cities(1 .. N) is a
   --  permutation of 1 .. N. Does not inspect T.Cost.

   function Tour_Cost
     (Distances : Cost_Matrix; T : Tour) return Cost_Value
     with Global => null;
   --  Closed_Tour_Cost of T against Distances. Raises Invalid_Argument
   --  when Matrix_Order(Distances) /= T.N or T.N < 2 or any city id is
   --  out of range.

   function Approximate_Tour (Distances : Cost_Matrix) return Tour
     with Global => null;
   --  Christofides–Serdyukov approximate tour. Requires N ≥ 2 and an
   --  odd-MST set of size ≤ Max_Matching_Odd. The returned Cities
   --  sequence starts at vertex 1 after shortcutting (rotation only;
   --  the cycle is otherwise determined by the Euler tour). Raises
   --  Invalid_Argument on bad matrix, N < 2, or matching overflow.

   function Exact_Tour (Distances : Cost_Matrix) return Tour
     with Global => null;
   --  Brute-force optimal directed tour: fix Cities(1) = 1 and try all
   --  permutations of 2 .. N (covers every directed cycle once). On
   --  symmetric matrices this is the undirected OPT. Raises
   --  Invalid_Argument when the matrix is invalid, N < 2, or
   --  N > Max_Exact_Vertices.

end Christofides_Algorithm;
