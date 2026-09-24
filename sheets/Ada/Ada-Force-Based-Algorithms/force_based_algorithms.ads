--  Force_Based_Algorithms — Ada 2023 educational package for 2-D
--  force-directed (force-based) graph drawing. Implements a
--  Fruchterman–Reingold / spring-embedder layout: Hooke-like attraction
--  along undirected edges, Coulomb-like repulsion between all vertex
--  pairs, and a cooling temperature that caps per-iteration displacement.
--  Vertices are placed by a deterministic seeded circle+jitter so tests
--  are reproducible. Float coordinates with SPARK_Mode => Off.
--  Primary source:
--    https://en.wikipedia.org/wiki/Force-directed_graph_drawing
--  Sibling sheets (README only — do not `with`): Spectral Layout,
--  Barnes–Hut — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Force_Based_Algorithms
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   --  All-pairs repulsion is O(N^2) per iteration, so the classroom cap
   --  stays modest.
   Max_Vertices : constant Positive := 256;

   --  Maximum number of undirected edges (parallel edges allowed; each
   --  Add_Edge consumes one slot until Clear). Self-loops are stored but
   --  skipped by attraction / Mean_Edge_Length.
   Max_Edges : constant Positive := 8_192;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, 2-D positions, cooling schedule
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Euclidean plane position (Float; SPARK_Mode Off).
   type Point2D is record
      X, Y : Float := 0.0;
   end record;

   --  Caller-supplied buffer of vertex positions. Layout / Compute /
   --  Seed_Positions require 'First = 1 and 'Last >= Vertex_Count.
   type Position_Array is array (Vertex_Id range <>) of Point2D;

   --  Temperature (step-cap) decay. Linear: t_i = t0 * (I-i+1)/I.
   --  Exponential: t_i = t0 * γ^{i-1} with Cooling_Factor = γ ∈ (0, 1].
   type Temperature_Schedule is (Linear, Exponential);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, empty-graph Seed_Positions / Layout /
   --  Compute / Mean_Edge_Length, Ideal_Length <= 0, Scale <= 0,
   --  Initial_Temperature < 0, Exponential Cooling_Factor not in (0, 1],
   --  Position_Array bounds that cannot hold the result (First /= 1 or
   --  Last < Vertex_Count when N > 0), Position_Of out of range, or
   --  Mean_Edge_Length with no counted (non-loop) edges.

   ---------------------------------------------------------------------------
   -- Undirected unweighted graph
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty undirected graph on vertices 1 .. Vertex_Count
   --  (no edges). Vertex_Count = 0 yields an empty graph. Raises
   --  Invalid_Argument when Vertex_Count > Max_Vertices.

   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id)
     with Global => null;
   --  Append an undirected unweighted edge {U, V}. Parallel edges and
   --  self-loops are permitted (self-loops are ignored by the force
   --  model). Raises Invalid_Argument when U or V is outside
   --  1 .. Vertex_Count(G), or when Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of undirected edges currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Fruchterman–Reingold / spring-embedder)
   ---------------------------------------------------------------------------
   --  Ideal length k = Ideal_Length. Pairwise Euclidean distance d.
   --  Attractive force along each stored non-loop edge (Hooke / spring):
   --    f_a(d) = d^2 / k
   --  Repulsive force between every unordered pair of vertices
   --  (Coulomb / charge):
   --    f_r(d) = k^2 / d
   --  (d is floored away from zero so coincident vertices still separate).
   --  Equilibrium of a single isolated edge is d = k. Each iteration
   --  accumulates displacements, then moves every vertex by at most the
   --  current temperature t (cooling). Linear and exponential schedules
   --  are provided. Seed_Positions places vertices on a circle of radius
   --  Scale * sqrt(N) with deterministic LCG jitter from Seed.

   procedure Seed_Positions
     (G         : Graph;
      Seed      : Natural := 1;
      Scale     : Float := 1.0;
      Positions : out Position_Array)
     with Global => null;
   --  Deterministic initial placement of vertices 1 .. N. Extra slots of
   --  Positions are zeroed. Raises Invalid_Argument when N = 0, Scale
   --  <= 0, or Positions'First /= 1 or Positions'Last < N.

   procedure Layout
     (G                   : Graph;
      Iterations          : Positive := 100;
      Ideal_Length        : Float := 1.0;
      Initial_Temperature : Float := 1.0;
      Schedule            : Temperature_Schedule := Linear;
      Cooling_Factor      : Float := 0.95;
      Positions           : in out Position_Array)
     with Global => null;
   --  Run Iterations force-directed steps starting from Positions(1 .. N).
   --  Does not re-seed. Raises Invalid_Argument when N = 0, Ideal_Length
   --  <= 0, Initial_Temperature < 0, Exponential Cooling_Factor is not
   --  in (0, 1], or Positions bounds are wrong.

   procedure Compute
     (G                   : Graph;
      Iterations          : Positive := 100;
      Ideal_Length        : Float := 1.0;
      Initial_Temperature : Float := 1.0;
      Schedule            : Temperature_Schedule := Linear;
      Cooling_Factor      : Float := 0.95;
      Seed                : Natural := 1;
      Positions           : out Position_Array)
     with Global => null;
   --  Seed_Positions (Scale = Ideal_Length) then Layout. Same contracts
   --  as those two procedures combined.

   ---------------------------------------------------------------------------
   -- Geometry helpers
   ---------------------------------------------------------------------------

   function Euclidean (A, B : Point2D) return Float
     with Global => null;
   --  sqrt((A.X-B.X)^2 + (A.Y-B.Y)^2).

   function Position_Of
     (Positions : Position_Array; V : Vertex_Id) return Point2D
     with Global => null;
   --  Positions(V). Raises Invalid_Argument when V is outside
   --  Positions'Range.

   function Mean_Edge_Length
     (G : Graph; Positions : Position_Array) return Float
     with Global => null;
   --  Average Euclidean length of stored non-loop edges. Raises
   --  Invalid_Argument when N = 0, Positions bounds are wrong, or there
   --  is no counted edge.

   function Is_Finite (P : Point2D) return Boolean
     with Global => null;
   --  True iff both coordinates are finite Floats of modest magnitude
   --  (not NaN / Inf, abs < 1.0e30).

private

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Edge_Index is Positive range 1 .. Max_Edges;

   type Vertex_Array is array (Edge_Index) of Vertex_Id;

   type Graph is limited record
      N : Natural := 0;
      E : Edge_Count_T := 0;
      U : Vertex_Array;
      V : Vertex_Array;
   end record;

end Force_Based_Algorithms;
