--  Nearest_Neighbor_Algorithm — Ada 2023 educational package for the
--  classic nearest-neighbour constructive heuristic for the travelling
--  salesman problem (TSP). Given a complete digraph on vertices 1 .. N
--  encoded as a non-negative distance/cost matrix, start at a chosen
--  city and repeatedly append the nearest unvisited city; close the
--  tour by returning to the start. Also provided: try every start and
--  keep the best tour, plus an exact brute-force oracle for N ≤ 10 so
--  learners can see that NN is approximate. Asymmetric matrices are
--  allowed; default demos use symmetric metric instances.
--  Reference: https://en.wikipedia.org/wiki/Nearest_neighbour_algorithm
--  Sibling sheets (README only — do not `with`): Christofides, VRP,
--  Dijkstra, ACO / TSP metaheuristics — RobertBoettcherSF Ada series.

pragma Ada_2022;

package Nearest_Neighbor_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of cities / vertices (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 128;

   --  Exact brute-force oracle is restricted to this vertex count
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
   --  dimensions, Last(1) = Last(2) = N). Asymmetry is permitted:
   --  Distances(I, J) need not equal Distances(J, I). Diagonal entries
   --  are ignored by the constructive heuristic (they appear only in
   --  the N = 1 closed-tour cost Distances(1, 1)).
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

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for non-square or non-1-based Cost_Matrix, N = 0 on tour
   --  APIs, Start outside 1 .. N, indices outside 1 .. N, negative
   --  distances passed to Put_Distance / Put_Symmetric, Exact_Tour when
   --  N > Max_Exact_Vertices, or Tour_Cost on a Tour whose N does not
   --  match the matrix order.

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
   --  Same guards as Put_Distance.

   function Matrix_Order (Distances : Cost_Matrix) return Natural
     with Global => null;
   --  N = Distances'Length (1) when the matrix is square and 1-based;
   --  raises Invalid_Argument otherwise (including the empty 1 .. 0 case
   --  when First /= 1).

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
   -- Algorithm sketch (nearest neighbour)
   ---------------------------------------------------------------------------
   --  Input: complete digraph on {1 .. N} with c(u,v) ≥ 0; start s.
   --  1. Mark all vertices unvisited; set u ← s; mark s visited;
   --     append s to the tour.
   --  2. While unvisited vertices remain:
   --       v ← argmin { c(u,w) : w unvisited } (ties: smaller index);
   --       append v; mark v visited; u ← v.
   --  3. Return to s: tour cost = path cost + c(last, s).
   --  The sequence of visited vertices is the output tour.
   --  Best_Tour runs Tour_From for every start and keeps the minimum
   --  cost (ties: smaller start index). Exact_Tour enumerates all
   --  directed Hamiltonian cycles (fix start at 1) for N ≤ 10.
   --  NN is a greedy heuristic: it is fast but has no constant-factor
   --  approximation guarantee on arbitrary instances (for every r there
   --  is an instance where NN > r · OPT). Metric TSP admits better
   --  guarantees (e.g. Christofides 3/2); this sheet stays classical NN.

   function Closed_Tour_Cost
     (Distances : Cost_Matrix;
      Cities    : City_Seq;
      N         : Natural) return Cost_Value
     with Global => null;
   --  Sum of N closed-tour edges Cities(1)→…→Cities(N)→Cities(1).
   --  Requires Matrix_Order = N ≥ 1 and each Cities(i) in 1 .. N.
   --  Does not require Cities to be a permutation (callers that need
   --  that check Is_Valid_Tour). Raises Invalid_Argument on bad N /
   --  matrix / out-of-range city ids.

   function Is_Valid_Tour (T : Tour) return Boolean
     with Global => null;
   --  True iff T.N ∈ 1 .. Max_Vertices and Cities(1 .. N) is a
   --  permutation of 1 .. N. Does not inspect T.Cost.

   function Tour_Cost
     (Distances : Cost_Matrix; T : Tour) return Cost_Value
     with Global => null;
   --  Closed_Tour_Cost of T against Distances. Raises Invalid_Argument
   --  when Matrix_Order(Distances) /= T.N or T.N = 0 or any city id is
   --  out of range.

   function Tour_From
     (Distances : Cost_Matrix; Start : Vertex_Id) return Tour
     with Global => null;
   --  Nearest-neighbour tour starting at Start. Raises Invalid_Argument
   --  when the matrix is invalid, N = 0, or Start is outside 1 .. N.
   --  Tie-break: smallest vertex index among equal nearest distances.

   function Best_Tour (Distances : Cost_Matrix) return Tour
     with Global => null;
   --  Run Tour_From for every start in 1 .. N; return the tour of
   --  minimum Cost (ties: smaller Start). Same matrix guards as
   --  Tour_From; N = 0 raises Invalid_Argument.

   function Exact_Tour (Distances : Cost_Matrix) return Tour
     with Global => null;
   --  Brute-force optimal directed tour: fix Cities(1) = 1 and try all
   --  permutations of 2 .. N (covers every directed cycle once). Raises
   --  Invalid_Argument when the matrix is invalid, N = 0, or
   --  N > Max_Exact_Vertices. For N = 1 returns the trivial tour with
   --  Cost = Distances(1, 1).

end Nearest_Neighbor_Algorithm;
