--  Travelling_Salesman_Problem — Ada 2023 educational survey package for
--  the classical travelling salesman problem (TSP). Given a complete
--  digraph on vertices 1 .. N encoded as a non-negative distance/cost
--  matrix, find a closed tour that visits each city exactly once and
--  returns to the start. Exact TSP is NP-hard. This sheet exposes:
--    * cost-matrix builders (symmetric / asymmetric; Euclidean helper);
--    * exact solvers — Held–Karp bitmask DP (N ≤ Max_Held_Karp_Vertices)
--      and brute-force enumeration (N ≤ Max_Brute_Force_Vertices);
--    * educational heuristic copies (not `with` of sibling packages):
--        nearest-neighbour (one start / best over all starts),
--        optional 2-opt improvement,
--        MST double-tree 2-approximation for metric instances.
--  Types: Tour, Cost_Matrix; helpers Is_Valid_Tour, Closed_Tour_Cost.
--  Caps are documented; Invalid_Argument for bad dims / negatives /
--  exact overflow. Full Christofides (3/2) lives in the sibling sheet —
--  prefer double-tree here for a lighter 2-approx.
--  Reference: https://en.wikipedia.org/wiki/Travelling_salesman_problem
--  Sibling sheets (README only — do not `with`): Nearest Neighbour,
--  Christofides, Vehicle Routing / CVRP — RobertBoettcherSF Ada series.

pragma Ada_2022;

package Travelling_Salesman_Problem
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of cities / vertices (indices 1 .. Max_Vertices).
   --  Heuristics (NN, 2-opt, double-tree) may use the full range.
   Max_Vertices : constant Positive := 64;

   --  Exact brute-force oracle: (N−1)! directed cycles with a fixed start.
   Max_Brute_Force_Vertices : constant Positive := 10;

   --  Held–Karp / bitmask DP: O(N² 2^N) time and O(N 2^N) storage.
   --  Cap chosen for educational stack/heap comfort (N = 16 ⇒ ~1M states).
   Max_Held_Karp_Vertices : constant Positive := 16;

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
   --  are ignored by constructive heuristics except for the N = 1
   --  closed-tour cost Distances(1, 1). Metric double-tree uses the
   --  undirected view min(c(u,v), c(v,u)) for the MST; the returned tour
   --  cost is always measured on the stored directed entries.
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
   --  APIs (N < 2 for double-tree), Start outside 1 .. N, indices outside
   --  1 .. N, negative distances passed to Put_Distance / Put_Symmetric,
   --  Brute_Force_Tour when N > Max_Brute_Force_Vertices, Held_Karp_Tour /
   --  Exact_Tour when N > Max_Held_Karp_Vertices, or Tour_Cost on a Tour
   --  whose N does not match the matrix order.

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
   --  Same guards as Put_Distance. Preferred for metric instances.

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

   function Undirected_Weight
     (Distances : Cost_Matrix; A, B : Vertex_Id) return Cost_Value
     with Global => null;
   --  min(Distances(A,B), Distances(B,A)) for the undirected MST view
   --  used by Double_Tree_Tour. Raises Invalid_Argument on bad matrix / ids.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (survey)
   ---------------------------------------------------------------------------
   --  Exact — Held–Karp (bitmask DP), fix start s = 1:
   --    dp[S][j] = min cost of a path that starts at 1, visits exactly the
   --    cities in S ⊆ {1..N} (with 1 ∈ S), and ends at j ∈ S.
   --    Recurrence: dp[{1}][1] = 0;
   --      dp[S][j] = min_{i ∈ S\{j}} dp[S\{j}][i] + c(i,j).
   --    OPT = min_j dp[{1..N}][j] + c(j,1). Time O(N² 2^N).
   --  Exact — brute force: fix Cities(1)=1, permute 2..N; keep best.
   --  Nearest neighbour: from start s, repeatedly append the nearest
   --  unvisited city (ties: smaller index); close the tour. Best_* tries
   --  every start. Optional Improve_Two_Opt reverses pairs of edges while
   --  an improving move exists. Double-tree (metric 2-approx): MST →
   --  double every tree edge → Euler tour → shortcut to a Hamiltonian
   --  cycle; w(tour) ≤ 2 · OPT under triangle inequality. Full Christofides
   --  (3/2) is the sibling sheet — not duplicated here.

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

   ---------------------------------------------------------------------------
   -- Exact solvers
   ---------------------------------------------------------------------------

   function Brute_Force_Tour (Distances : Cost_Matrix) return Tour
     with Global => null;
   --  Brute-force optimal directed tour: fix Cities(1) = 1 and try all
   --  permutations of 2 .. N. Raises Invalid_Argument when the matrix is
   --  invalid, N = 0, or N > Max_Brute_Force_Vertices. For N = 1 returns
   --  the trivial tour with Cost = Distances(1, 1).

   function Held_Karp_Tour (Distances : Cost_Matrix) return Tour
     with Global => null;
   --  Optimal directed tour via Held–Karp bitmask DP (start fixed at 1
   --  for cycle rotation). Raises Invalid_Argument when the matrix is
   --  invalid, N = 0, or N > Max_Held_Karp_Vertices. For N = 1 returns
   --  Cost = Distances(1, 1). Agrees with Brute_Force_Tour on N ≤ 10.

   function Exact_Tour (Distances : Cost_Matrix) return Tour
     with Global => null;
   --  Survey exact entry point: Held_Karp_Tour. Same caps / guards.

   ---------------------------------------------------------------------------
   -- Heuristics (educational in-package copies)
   ---------------------------------------------------------------------------

   function Nearest_Neighbor_From
     (Distances : Cost_Matrix; Start : Vertex_Id) return Tour
     with Global => null;
   --  Classical nearest-neighbour tour starting at Start. Raises
   --  Invalid_Argument when the matrix is invalid, N = 0, or Start is
   --  outside 1 .. N. Tie-break: smallest vertex index among equal
   --  nearest distances.

   function Best_Nearest_Neighbor (Distances : Cost_Matrix) return Tour
     with Global => null;
   --  Run Nearest_Neighbor_From for every start in 1 .. N; return the
   --  tour of minimum Cost (ties: smaller Start). Same matrix guards;
   --  N = 0 raises Invalid_Argument.

   function Improve_Two_Opt
     (Distances : Cost_Matrix; Seed : Tour) return Tour
     with Global => null;
   --  Local-search 2-opt improvement of Seed: while an improving
   --  reversal of a contiguous city segment exists, apply the best
   --  improving move (or first-improvement; this sheet uses best
   --  improvement per pass). Requires Is_Valid_Tour(Seed) and
   --  Matrix_Order = Seed.N ≥ 1. Returns a valid tour whose Cost is
   --  ≤ Seed.Cost (measured on Distances). Raises Invalid_Argument on
   --  bad matrix / invalid seed / size mismatch. N = 1, 2 are no-ops
   --  (no improving move).

   function Double_Tree_Tour (Distances : Cost_Matrix) return Tour
     with Global => null;
   --  Metric 2-approximation: Prim MST → duplicate every tree edge →
   --  Euler tour (Hierholzer) → shortcut to a Hamiltonian cycle that
   --  starts at vertex 1. MST uses Undirected_Weight; the returned Cost
   --  uses stored directed entries. Requires N ≥ 2. Under triangle
   --  inequality, Cost ≤ 2 · OPT. Raises Invalid_Argument on bad matrix
   --  or N < 2. Prefer the Christofides sibling for the sharper 3/2
   --  guarantee.

end Travelling_Salesman_Problem;
