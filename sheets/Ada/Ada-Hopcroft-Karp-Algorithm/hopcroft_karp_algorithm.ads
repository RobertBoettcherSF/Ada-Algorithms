--  Hopcroft_Karp_Algorithm — Ada 2023 educational package for the
--  Hopcroft–Karp (Hopcroft–Karp–Karzanov) algorithm: maximum-cardinality
--  matching in a bipartite graph. Left vertices 1 .. L, right vertices
--  1 .. R; undirected bipartite edges via Add_Edge (Left, Right).
--  Classic BFS layering of shortest augmenting paths plus multi-DFS
--  augmentation phases; O(E √V) worst case. Fixed educational arrays
--  (no dynamic heap). Optional DFS-only Ford–Fulkerson matching oracle
--  for tiny instances. Cap L, R ≤ Max_Left / Max_Right, edges ≤ Max_Edges.
--  Reference: https://en.wikipedia.org/wiki/Hopcroft%E2%80%93Karp_algorithm
--  Sibling sheets (README only — do not `with`): Hungarian (weighted
--  bipartite assignment), Blossom / Edmonds (general matching) —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Hopcroft_Karp_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of left-side vertices (indices 1 .. Max_Left).
   Max_Left : constant Positive := 1024;

   --  Maximum number of right-side vertices (indices 1 .. Max_Right).
   Max_Right : constant Positive := 1024;

   --  Maximum number of bipartite edges the user may Add_Edge.
   Max_Edges : constant Positive := 50_000;

   --  DFS-only Ford–Fulkerson matching oracle is restricted to graphs
   --  with Left_Count ≤ Max_Oracle_Side and Right_Count ≤ Max_Oracle_Side.
   Max_Oracle_Side : constant Positive := 64;

   ---------------------------------------------------------------------------
   -- Vertex identifiers and matching arrays
   ---------------------------------------------------------------------------

   type Left_Id is range 1 .. Max_Left;
   type Right_Id is range 1 .. Max_Right;

   --  Pair_U(U) = V means left U is matched to right V; 0 = unmatched.
   --  Pair_V(V) = U means right V is matched to left U; 0 = unmatched.
   type Pair_U_Array is array (Positive range <>) of Natural;
   type Pair_V_Array is array (Positive range <>) of Natural;

   ---------------------------------------------------------------------------
   -- Solution
   ---------------------------------------------------------------------------

   --  Size is the matching cardinality. Pair_U / Pair_V hold mates for
   --  indices 1 .. Left_N / 1 .. Right_N; unused slots hold 0.
   type Matching_Result is record
      Size    : Natural := 0;
      Left_N  : Natural := 0;
      Right_N : Natural := 0;
      Pair_U  : Pair_U_Array (1 .. Max_Left) := [others => 0];
      Pair_V  : Pair_V_Array (1 .. Max_Right) := [others => 0];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for Left_Count / Right_Count / Edge_Count overflow, vertex
   --  ids outside 1 .. L or 1 .. R, Matching_Oracle_DFS when a side
   --  exceeds Max_Oracle_Side, or inspector / helper bound violations.

   ---------------------------------------------------------------------------
   -- Bipartite graph (adjacency lists from left to right)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear
     (G : in out Graph; Left_Count, Right_Count : Natural)
     with Global => null;
   --  Reset G to an empty bipartite graph on left vertices 1 .. Left_Count
   --  and right vertices 1 .. Right_Count (no edges). Either side may be 0.
   --  Raises Invalid_Argument when Left_Count > Max_Left or
   --  Right_Count > Max_Right.

   procedure Add_Edge
     (G : in out Graph; Left : Left_Id; Right : Right_Id)
     with Global => null;
   --  Append an undirected bipartite edge Left — Right (stored as a
   --  left→right adjacency arc). Parallel edges are permitted (they do
   --  not change the maximum matching). Raises Invalid_Argument when
   --  Left is outside 1 .. Left_Count(G), Right is outside
   --  1 .. Right_Count(G), or Edge_Count would exceed Max_Edges.

   function Left_Count (G : Graph) return Natural
     with Global => null;
   --  Number of left vertices L; valid left ids are 1 .. L (empty ⇒ 0).

   function Right_Count (G : Graph) return Natural
     with Global => null;
   --  Number of right vertices R; valid right ids are 1 .. R (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of edges currently stored in G (including parallel duplicates).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Hopcroft–Karp)
   ---------------------------------------------------------------------------
   --  Maintain a partial matching via Pair_U / Pair_V (0 = NIL). Each
   --  phase: BFS from all free left vertices builds a layered DAG of
   --  shortest augmenting paths (Dist on left vertices; Dist_Nil for the
   --  dummy free-right sink). Then DFS from each free left vertex finds
   --  a maximal set of vertex-disjoint shortest augmenting paths and
   --  flips them, increasing the matching size by their count. Repeat
   --  until BFS finds no augmenting path. Number of phases is O(√V);
   --  each phase is O(E); total O(E √V).
   --  Contrast (README only): Hungarian optimizes edge weights under a
   --  perfect matching; Blossom / Edmonds handles general (non-bipartite)
   --  graphs. Matching_Oracle_DFS finds one augmenting path per
   --  iteration (classic Ford–Fulkerson style) for tiny graphs.

   procedure Maximum_Matching (G : Graph; Result : out Matching_Result)
     with Global => null;
   --  Hopcroft–Karp: compute a maximum-cardinality matching. Fills
   --  Result.Size, Result.Left_N / Right_N, and mate arrays Pair_U /
   --  Pair_V (0 = unmatched). Empty L = 0 or R = 0 yields Size = 0.

   ---------------------------------------------------------------------------
   -- DFS-only Ford–Fulkerson matching oracle (tiny graphs)
   ---------------------------------------------------------------------------

   procedure Matching_Oracle_DFS (G : Graph; Result : out Matching_Result)
     with Global => null;
   --  Repeated single-path DFS augmentation until no augmenting path
   --  remains (Ford–Fulkerson style bipartite matching). Agrees with
   --  Maximum_Matching on cardinality for every valid instance.
   --  Raises Invalid_Argument when Left_Count(G) > Max_Oracle_Side or
   --  Right_Count(G) > Max_Oracle_Side.

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Is_Valid_Matching
     (G : Graph; Result : Matching_Result) return Boolean
     with Global => null;
   --  True iff Result.Left_N / Right_N match G's sides, Pair_U / Pair_V
   --  are mutual mates for a matching of Size edges that all exist in G
   --  (parallel edges count as present), and unmatched slots are 0.
   --  False (does not raise) when dimensions disagree.

   function Edge_Left (G : Graph; Index : Positive) return Left_Id
     with Global => null;
   function Edge_Right (G : Graph; Index : Positive) return Right_Id
     with Global => null;
   --  Inspect the Index-th edge (1 .. Edge_Count) in insertion order.
   --  Raises Invalid_Argument when Index is outside 1 .. Edge_Count(G).

private

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Edge_Index is Positive range 1 .. Max_Edges;

   type Head_Array is array (Left_Id) of Natural;
   type To_Array is array (Edge_Index) of Right_Id;
   type From_Array is array (Edge_Index) of Left_Id;
   type Next_Array is array (Edge_Index) of Natural;

   type Graph is limited record
      L    : Natural := 0;
      R    : Natural := 0;
      M    : Edge_Count_T := 0;
      Head : Head_Array := [others => 0];
      To   : To_Array := [others => Right_Id'First];
      From : From_Array := [others => Left_Id'First];
      Next : Next_Array := [others => 0];
   end record;

end Hopcroft_Karp_Algorithm;
