--  PageRank — Ada 2023 educational package for classic PageRank power
--  iteration on a directed graph (Brin & Page, 1998). Builds an
--  unweighted digraph and iterates the damped random-surfer update
--    r ← α T r + (1−α) s
--  until the L1 change falls below Tolerance or Max_Iters is reached.
--  Default teleport s is uniform 1/N; Set_Teleport installs a personalized
--  probability vector. Dangling nodes (outdeg = 0) redistribute mass
--  according to s. Vertices indexed from 1. Fixed educational arrays
--  (no dynamic heap). Float scores with SPARK_Mode => Off for clarity.
--  Primary source: https://en.wikipedia.org/wiki/PageRank
--  Sibling sheets (README only — do not `with`): TrustRank, HITS —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package PageRank
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
   -- Vertex identifiers and score / teleport vectors
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  PageRank scores after Compute (non-negative; sum ≈ 1).
   type Score_Array is array (Vertex_Id range <>) of Float;

   --  Non-negative teleport masses for Set_Teleport (normalized inside
   --  Compute to a probability vector s with support on positive entries).
   type Teleport_Array is array (Vertex_Id range <>) of Float;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, zero total teleport mass, Damping outside
   --  [0, 1], Tolerance < 0, Score_Array / Teleport_Array bounds that
   --  cannot hold the result (First /= 1 or Last < Vertex_Count when
   --  N > 0), or Compute on an empty graph (N = 0).

   ---------------------------------------------------------------------------
   -- Directed unweighted link graph (adjacency lists)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty digraph on vertices 1 .. Vertex_Count (no edges,
   --  uniform teleport). Vertex_Count = 0 yields an empty graph. Raises
   --  Invalid_Argument when Vertex_Count > Max_Vertices.

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
   -- Teleport / personalization vector
   ---------------------------------------------------------------------------

   procedure Clear_Teleport (G : in out Graph)
     with Global => null;
   --  Forget any custom teleport; Compute will use the uniform vector
   --  s(v) = 1/N. Does not modify vertices or edges.

   procedure Set_Teleport (G : in out Graph; Mass : Teleport_Array)
     with Global => null;
   --  Install a custom non-negative teleport mass vector (personalized
   --  PageRank). Mass must satisfy Mass'First = 1 and
   --  Mass'Last >= Vertex_Count; entries outside 1 .. N are ignored.
   --  Negative entries raise Invalid_Argument. Zero total mass over
   --  1 .. N raises Invalid_Argument. Compute will normalize Mass to a
   --  probability vector s. Raises Invalid_Argument when N = 0 or bounds
   --  are wrong.

   function Has_Custom_Teleport (G : Graph) return Boolean
     with Global => null;
   --  True iff Set_Teleport was the last teleport configuration.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic / personalized PageRank)
   ---------------------------------------------------------------------------
   --  Let outdeg(u) be the number of stored outgoing links from u.
   --  The column-stochastic transition T sends mass along reverse links:
   --    T(v,u) = 1/outdeg(u)  if u → v and outdeg(u) > 0,
   --    and dangling nodes (outdeg = 0) redistribute according to s.
   --  With damping α ∈ [0,1] and teleport distribution s (∑ s = 1, s ≥ 0):
   --    r ← α T r + (1−α) s
   --  is iterated from r₀ = s until ‖r_{k+1} − r_k‖₁ ≤ Tolerance or
   --  Max_Iters steps elapse. Default s is uniform 1/N (classic PageRank).
   --  Relation to TrustRank (README only): TrustRank replaces uniform s by
   --  a seed-biased teleport; the iteration is otherwise identical.
   --  Relation to HITS (README only): HITS maintains separate hub /
   --  authority scores; PageRank is a single random-walk score.

   procedure Compute
     (G          : Graph;
      Damping    : Float := 0.85;
      Max_Iters  : Positive := 100;
      Tolerance  : Float := 1.0e-6;
      Scores     : out Score_Array;
      Iterations : out Natural)
     with Global => null;
   --  Run PageRank power iteration. On success Scores(1 .. N) holds an
   --  approximate stationary distribution (non-negative, sum ≈ 1) and
   --  Iterations is the number of power steps performed (1 .. Max_Iters).
   --  Requires Scores'First = 1 and Scores'Last >= N. Raises
   --  Invalid_Argument when N = 0, when Damping is outside [0.0, 1.0],
   --  when Tolerance < 0.0, or when Scores bounds are wrong.

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
   type Mass_Storage is array (Vertex_Id) of Float;

   type Graph is limited record
      N               : Natural := 0;
      E               : Edge_Count_T := 0;
      Head            : Head_Array := [others => 0];
      To              : To_Array;
      Next            : Next_Array := [others => 0];
      Outdeg          : Outdeg_Array := [others => 0];
      Custom_Teleport : Boolean := False;
      Teleport_Mass   : Mass_Storage := [others => 0.0];
   end record;

end PageRank;
