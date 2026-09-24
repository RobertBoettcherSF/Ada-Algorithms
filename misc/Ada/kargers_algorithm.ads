--  Kargers_Algorithm — Ada 2023 educational package for Karger's
--  randomized min-cut algorithm on undirected multigraphs. Repeatedly
--  contract a uniformly random edge until two supernodes remain; the
--  multiplicity of edges between them is the cut size of one trial.
--  Min_Cut repeats independent seeded trials and keeps the best
--  (smallest) cut. Optional Exact_Min_Cut enumerates bipartitions for
--  N ≤ Exact_Max_Vertices. Vertices indexed from 1. Fixed educational
--  arrays sized to Max_Vertices / Max_Edges (no dynamic heap).
--  Deterministic LCG seeded RNG for reproducible tests.
--  Reference: https://en.wikipedia.org/wiki/Karger%27s_algorithm
--  Sibling sheets (README only — do not `with`): flow-based min-cut /
--  max-flow — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Kargers_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 128;

   --  Maximum number of undirected edges counting multiplicity (each
   --  Add_Edge consumes one slot until Clear). Parallel edges encode
   --  multiplicity for the unweighted multigraph model.
   Max_Edges : constant Positive := 16_384;

   --  Exact_Min_Cut is offered only for graphs with
   --  Vertex_Count ≤ Exact_Max_Vertices (subset enumeration).
   Exact_Max_Vertices : constant Positive := 10;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, edge records
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  One undirected edge {U, V}. Order of U / V is the order passed to
   --  Add_Edge (not canonicalized). Self-loops are rejected.
   type Edge_Record is record
      U, V : Vertex_Id;
   end record;

   --  Cut size = number of edges crossing a bipartition (multiplicity
   --  counted). Wide enough for Max_Edges.
   subtype Cut_Size is Natural range 0 .. Max_Edges;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, self-loops on Add_Edge, N < 2 on cut APIs,
   --  Trials = 0 (Positive prevents this), or Exact_Min_Cut when
   --  N > Exact_Max_Vertices.

   ---------------------------------------------------------------------------
   -- Undirected unweighted multigraph (edge list; multiplicity via parallels)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty undirected multigraph on vertices
   --  1 .. Vertex_Count (no edges). Vertex_Count = 0 yields an empty
   --  graph. Raises Invalid_Argument when Vertex_Count > Max_Vertices.

   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id)
     with Global => null;
   --  Append one undirected edge {U, V}. Parallel edges are permitted
   --  and encode multiplicity. Raises Invalid_Argument when U = V
   --  (self-loop), when U or V is outside 1 .. Vertex_Count(G), or when
   --  Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of undirected edges currently stored in G (with
   --  multiplicity).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Karger contraction)
   ---------------------------------------------------------------------------
   --  While more than two supernodes remain, pick a uniformly random
   --  non-loop edge and contract its endpoints (merge supernodes;
   --  discard self-loops). The multiplicity of edges between the final
   --  two supernodes is the cut size of that trial. One trial succeeds
   --  with probability at least 1 / binom(n,2) = Ω(1/n²). Min_Cut runs
   --  Trials independent seeded contractions and returns the minimum
   --  observed cut. Exact_Min_Cut enumerates all bipartitions for
   --  N ≤ Exact_Max_Vertices.
   --  Contrast (README only): flow-based global min-cut via repeated
   --  s–t max-flow / Stoer–Wagner is deterministic polynomial-time;
   --  Karger is a Monte Carlo randomized alternative.

   function Contract_Once (G : Graph; Seed : Natural) return Cut_Size
     with Global => null;
   --  One Karger contraction trial seeded by Seed (deterministic LCG).
   --  Returns the cut size of the random bipartition produced. Same
   --  (G, Seed) always yields the same result. Requires N ≥ 2; raises
   --  Invalid_Argument otherwise. Disconnected graphs may yield 0.

   function Min_Cut
     (G : Graph; Trials : Positive; Seed : Natural) return Cut_Size
     with Global => null;
   --  Run Trials independent contraction trials with seeds
   --  Seed, Seed+1, …, Seed+Trials−1 and return the smallest cut size
   --  observed. Thus Min_Cut(G, 1, S) = Contract_Once(G, S). Requires
   --  N ≥ 2; raises Invalid_Argument otherwise.

   function Exact_Min_Cut (G : Graph) return Cut_Size
     with Global => null;
   --  Exact global min-cut by enumerating bipartitions (fix vertex 1
   --  on the S side). Requires 2 ≤ N ≤ Exact_Max_Vertices; raises
   --  Invalid_Argument otherwise. Self-contained cross-check — no
   --  `with` of sibling packages.

private

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Edge_Index is Positive range 1 .. Max_Edges;

   type Edge_Array is array (Edge_Index) of Edge_Record;

   type Graph is limited record
      N     : Natural := 0;
      M     : Edge_Count_T := 0;
      Edges : Edge_Array :=
        [others => (U => Vertex_Id'First, V => Vertex_Id'First)];
   end record;

end Kargers_Algorithm;
