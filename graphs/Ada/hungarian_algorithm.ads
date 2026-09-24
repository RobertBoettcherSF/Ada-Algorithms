--  Hungarian_Algorithm — Ada 2023 educational package for the
--  Hungarian method / Kuhn–Munkres algorithm on the assignment
--  problem: given an n×n integer cost matrix, find a permutation
--  π of columns that minimizes (or maximizes) Σ_i C(i, π(i)).
--  Equivalently, a min-/max-cost perfect matching in the complete
--  bipartite graph of n workers and n jobs. Dual O(n³) formulation
--  (row/column potentials, tight edges, successive augmentations).
--  Cap n ≤ Max_N (educational). Optional brute-force oracle for
--  n ≤ Max_Brute_N. Fixed arrays; no dynamic heap.
--  Reference: https://en.wikipedia.org/wiki/Hungarian_algorithm
--  Sibling sheets (README only — do not `with`): Hopcroft–Karp
--  (cardinality bipartite matching), Blossom / Edmonds (general
--  matching) — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Hungarian_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum matrix order n (indices 1 .. Max_N). O(n³) time.
   Max_N : constant Positive := 64;

   --  Brute-force permutation oracle is restricted to this order.
   Max_Brute_N : constant Positive := 8;

   ---------------------------------------------------------------------------
   -- Identifiers and costs
   ---------------------------------------------------------------------------

   type Index is range 1 .. Max_N;

   --  Signed integer costs (negatives allowed; maximize uses −C).
   type Cost_Value is range -(2**62) .. 2**62 - 1;

   --  Sentinel larger than any reduced cost arising for n ≤ Max_N with
   --  |C(i,j)| bounded well below Cost_Value'Last / Max_N.
   Large_Cost : constant Cost_Value := Cost_Value'Last / 8;

   --  Unconstrained matrix view (must be 1-based and square to Load).
   type Cost_Matrix is array (Positive range <>, Positive range <>)
     of Cost_Value;

   --  Assignment(I) = J means row I is matched to column J.
   --  Unassigned / unused slots hold 0.
   type Assignment_Array is array (Positive range <>) of Natural;

   ---------------------------------------------------------------------------
   -- Solution
   ---------------------------------------------------------------------------

   --  Column assigned to each row 1 .. N; Total_Cost is the objective
   --  on the original (non-negated) cost scale.
   type Solution is record
      N          : Natural := 0;
      Total_Cost : Cost_Value := 0;
      Assignment : Assignment_Array (1 .. Max_N) := [others => 0];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for Size > Max_N, non-square Load_Matrix, First /= 1,
   --  row/col outside 1 .. N, Solve_Brute_* when N > Max_Brute_N, or
   --  Assignment_Cost when the mapping is not a permutation of 1 .. N.

   ---------------------------------------------------------------------------
   -- Problem instance (square n×n cost matrix)
   ---------------------------------------------------------------------------

   type Problem is limited private;

   procedure Clear (P : in out Problem; Size : Natural)
     with Global => null;
   --  Reset P to an n×n zero cost matrix with n = Size. Size = 0 is the
   --  empty instance. Raises Invalid_Argument when Size > Max_N.

   procedure Set_Cost
     (P : in out Problem; Row, Col : Index; Cost : Integer)
     with Global => null;
   --  Store Cost at (Row, Col). Raises Invalid_Argument when Row or Col
   --  is outside 1 .. Size(P).

   procedure Load_Matrix (P : in out Problem; Costs : Cost_Matrix)
     with Global => null;
   --  Copy Costs into P. Requires Costs'First(1) = Costs'First(2) = 1,
   --  square, and order ≤ Max_N. Raises Invalid_Argument otherwise.

   function Size (P : Problem) return Natural
     with Global => null;
   --  Current order n (0 .. Max_N).

   function Get_Cost
     (P : Problem; Row, Col : Index) return Cost_Value
     with Global => null;
   --  Entry C(Row, Col). Raises Invalid_Argument when Row or Col is
   --  outside 1 .. Size(P).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (dual Kuhn–Munkres, minimize)
   ---------------------------------------------------------------------------
   --  Maintain potentials U(i), V(j) with C(i,j) − U(i) − V(j) ≥ 0 and
   --  grow a matching of tight (reduced-cost 0) edges until perfect.
   --  Each of n augmentations is an O(n²) Dijkstra-like scan on reduced
   --  costs; total O(n³). Maximize solves the same problem on −C and
   --  restores the objective sign.

   procedure Solve_Minimize (P : Problem; Result : out Solution)
     with Global => null;
   --  Kuhn–Munkres: permutation π minimizing Σ_i C(i, π(i)).
   --  Empty n = 0 yields Total_Cost = 0 and an empty assignment.

   procedure Solve_Maximize (P : Problem; Result : out Solution)
     with Global => null;
   --  Permutation maximizing Σ_i C(i, π(i)) (via Solve_Minimize on −C).

   ---------------------------------------------------------------------------
   -- Brute-force oracle (n ≤ Max_Brute_N)
   ---------------------------------------------------------------------------

   procedure Solve_Brute_Minimize (P : Problem; Result : out Solution)
     with Global => null;
   --  Enumerate all n! permutations; return a min-cost one.
   --  Raises Invalid_Argument when Size(P) > Max_Brute_N.

   procedure Solve_Brute_Maximize (P : Problem; Result : out Solution)
     with Global => null;
   --  Enumerate all n! permutations; return a max-cost one.
   --  Raises Invalid_Argument when Size(P) > Max_Brute_N.

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Is_Permutation
     (A : Assignment_Array; N : Natural) return Boolean
     with Global => null;
   --  True iff A(1 .. N) is a permutation of 1 .. N (N = 0 ⇒ True).
   --  Requires A'First = 1 and A'Length ≥ N; otherwise False.

   function Assignment_Cost
     (P : Problem; A : Assignment_Array) return Cost_Value
     with Global => null;
   --  Σ_i C(i, A(i)) for i in 1 .. Size(P). Raises Invalid_Argument
   --  when A is not a permutation of 1 .. N (requires A'First = 1 and
   --  A'Length ≥ N).

private

   type Cost_Store is array (Index, Index) of Cost_Value;

   type Problem is limited record
      N     : Natural := 0;
      Costs : Cost_Store := [others => [others => 0]];
   end record;

end Hungarian_Algorithm;
