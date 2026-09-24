--  TrustRank — Ada 2023 educational package for biased / personalized
--  PageRank from a seed set of trusted nodes (Gyöngyi, Garcia-Molina,
--  Pedersen, 2004). Builds a directed unweighted link graph, marks a
--  seed set (uniform or custom seed mass), and iterates
--    r ← α T r + (1−α) s
--  until the L1 change falls below Tolerance or Max_Iters is reached.
--  Trust mass concentrates near seeds and decays with link distance.
--  Vertices indexed from 1. Fixed educational arrays (no dynamic heap).
--  Float scores with SPARK_Mode => Off for clarity.
--  Primary source: https://en.wikipedia.org/wiki/TrustRank
--  Sibling sheets (README only — do not `with`): PageRank, HITS —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package TrustRank
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 1_024;

   --  Maximum number of directed unweighted links (parallel edges allowed;
   --  each Add_Edge consumes one slot until Clear).
   Max_Edges : constant Positive := 50_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers and score / seed vectors
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Trust / PageRank-style scores after Compute (non-negative; sum ≈ 1).
   type Score_Array is array (Vertex_Id range <>) of Float;

   --  Non-negative seed masses for Set_Seed_Distribution (normalized inside
   --  Compute to a probability vector s with support on positive entries).
   type Seed_Mass_Array is array (Vertex_Id range <>) of Float;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, empty seed set / zero total seed mass,
   --  Damping outside [0, 1], Tolerance < 0, Score_Array / Seed_Mass_Array
   --  bounds that cannot hold the result (First /= 1 or Last < Vertex_Count
   --  when N > 0), or Compute on an empty graph (N = 0).

   ---------------------------------------------------------------------------
   -- Directed unweighted link graph (adjacency lists)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty digraph on vertices 1 .. Vertex_Count (no edges,
   --  no seeds, no custom seed mass). Vertex_Count = 0 yields an empty
   --  graph. Raises Invalid_Argument when Vertex_Count > Max_Vertices.

   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id)
     with Global => null;
   --  Append a directed unweighted link From → To. Parallel edges and
   --  self-loops are permitted. Raises Invalid_Argument when From or To
   --  is outside 1 .. Vertex_Count(G), or when Edge_Count would exceed
   --  Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of directed links currently stored in G.

   ---------------------------------------------------------------------------
   -- Seed set (trusted pages)
   ---------------------------------------------------------------------------

   procedure Clear_Seeds (G : in out Graph)
     with Global => null;
   --  Forget all Mark_Seed marks and any custom seed distribution.
   --  Does not modify vertices or edges.

   procedure Mark_Seed (G : in out Graph; V : Vertex_Id)
     with Global => null;
   --  Mark V as a trusted seed. Duplicate marks are idempotent. After
   --  Mark_Seed calls (and no Set_Seed_Distribution), Compute uses the
   --  uniform seed vector s(v) = 1/|S| on marked seeds and 0 elsewhere.
   --  Raises Invalid_Argument when V is outside 1 .. Vertex_Count(G) or
   --  when Vertex_Count = 0.

   function Is_Seed (G : Graph; V : Vertex_Id) return Boolean
     with Global => null;
   --  True iff V was Mark_Seed'd since the last Clear / Clear_Seeds /
   --  Set_Seed_Distribution. Raises Invalid_Argument when V is outside
   --  1 .. Vertex_Count(G) or when Vertex_Count = 0.

   function Seed_Count (G : Graph) return Natural
     with Global => null;
   --  Number of currently marked seeds (0 after Clear / Clear_Seeds /
   --  Set_Seed_Distribution until Mark_Seed is used again).

   procedure Set_Seed_Distribution
     (G : in out Graph; Mass : Seed_Mass_Array)
     with Global => null;
   --  Install a custom non-negative seed mass vector. Clears any prior
   --  Mark_Seed marks. Mass must satisfy Mass'First = 1 and
   --  Mass'Last >= Vertex_Count; entries outside 1 .. N are ignored.
   --  Negative entries raise Invalid_Argument. Zero total mass over
   --  1 .. N raises Invalid_Argument. Compute will normalize Mass to a
   --  probability vector s. Raises Invalid_Argument when N = 0 or bounds
   --  are wrong.

   function Has_Custom_Seeds (G : Graph) return Boolean
     with Global => null;
   --  True iff Set_Seed_Distribution was the last seed configuration.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (biased PageRank / TrustRank)
   ---------------------------------------------------------------------------
   --  Let outdeg(u) be the number of stored outgoing links from u.
   --  The column-stochastic transition T sends mass along reverse links:
   --    T(v,u) = 1/outdeg(u)  if u → v and outdeg(u) > 0,
   --    and dangling nodes (outdeg = 0) redistribute according to s.
   --  With damping α ∈ [0,1] and seed distribution s (∑ s = 1, s ≥ 0):
   --    r ← α T r + (1−α) s
   --  is iterated from r₀ = s until ‖r_{k+1} − r_k‖₁ ≤ Tolerance or
   --  Max_Iters steps elapse. When α = 0 the result is exactly s; when
   --  α → 1 trust follows the link structure more aggressively.
   --  Relation to PageRank (README only): ordinary PageRank uses the
   --  uniform teleport 1/N; TrustRank replaces it by a seed-biased s.
   --  Relation to HITS (README only): HITS maintains separate hub /
   --  authority scores; TrustRank is a single biased random-walk score.

   procedure Compute
     (G          : Graph;
      Damping    : Float := 0.85;
      Max_Iters  : Positive := 100;
      Tolerance  : Float := 1.0e-6;
      Scores     : out Score_Array;
      Iterations : out Natural)
     with Global => null;
   --  Run TrustRank / personalized PageRank power iteration. On success
   --  Scores(1 .. N) holds an approximate stationary trust vector
   --  (non-negative, sum ≈ 1) and Iterations is the number of power
   --  steps performed (1 .. Max_Iters). Requires Scores'First = 1 and
   --  Scores'Last >= N. Raises Invalid_Argument when N = 0, when no
   --  seeds are configured (Seed_Count = 0 and not Has_Custom_Seeds),
   --  when Damping is outside [0.0, 1.0], when Tolerance < 0.0, or when
   --  Scores bounds are wrong.

   function Score_Of
     (Scores : Score_Array; V : Vertex_Id) return Float
     with Global => null;
   --  Convenience accessor: Scores(V). Raises Invalid_Argument when V
   --  is outside Scores'Range.

private

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Edge_Index is Positive range 1 .. Max_Edges;

   --  Adjacency via intrusive singly-linked edge nodes in a dense pool:
   --  Head(V) is the first edge index for V (0 = none); To(E) / Next(E)
   --  store the head and remainder of the out-list. Outdeg(V) caches the
   --  out-degree for the transition matrix.
   type Head_Array is array (Vertex_Id) of Natural;
   type To_Array is array (Edge_Index) of Vertex_Id;
   type Next_Array is array (Edge_Index) of Natural;
   type Outdeg_Array is array (Vertex_Id) of Natural;
   type Seed_Flag_Array is array (Vertex_Id) of Boolean;
   type Mass_Storage is array (Vertex_Id) of Float;

   type Graph is limited record
      N              : Natural := 0;
      E              : Edge_Count_T := 0;
      Head           : Head_Array := [others => 0];
      To             : To_Array;
      Next           : Next_Array := [others => 0];
      Outdeg         : Outdeg_Array := [others => 0];
      Seed_Marked    : Seed_Flag_Array := [others => False];
      Seed_N         : Natural := 0;
      Custom_Seeds   : Boolean := False;
      Custom_Mass    : Mass_Storage := [others => 0.0];
   end record;

end TrustRank;
