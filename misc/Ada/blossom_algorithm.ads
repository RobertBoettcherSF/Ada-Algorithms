--  Blossom_Algorithm — Ada 2023 educational package for Edmonds' blossom
--  algorithm: maximum-cardinality matching in a general undirected graph.
--  Vertices 1 .. N; undirected loopless edges via Add_Edge (U, V).
--  Alternating-forest search contracts odd cycles (blossoms) so an
--  augmenting path can be found even when the graph is non-bipartite;
--  O(E V^2) educational bound. Fixed arrays (no dynamic heap). Optional
--  subset-DP / bitset matching oracle for tiny instances (N ≤ Max_Oracle).
--  Cap N ≤ Max_Vertices, undirected edges ≤ Max_Edges.
--  Reference: https://en.wikipedia.org/wiki/Blossom_algorithm
--  Sibling sheets (README only — do not `with`): Hopcroft–Karp (bipartite
--  cardinality matching), Hungarian (weighted bipartite assignment) —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Blossom_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 256;

   --  Maximum number of undirected edges (each Add_Edge stores two
   --  directed adjacency arcs; Edge_Count counts undirected edges).
   Max_Edges : constant Positive := 16_384;

   --  Matching_Oracle_Brute is restricted to graphs with
   --  Vertex_Count ≤ Max_Oracle (subset DP / bitset, 2^N states).
   Max_Oracle : constant Positive := 16;

   ---------------------------------------------------------------------------
   -- Vertex identifiers and matching arrays
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Mate (V) = W means V is matched to W; 0 = unmatched / NIL.
   type Mate_Array is array (Positive range <>) of Natural;

   ---------------------------------------------------------------------------
   -- Solution
   ---------------------------------------------------------------------------

   --  Size is the matching cardinality. Mate holds partners for
   --  indices 1 .. N; unused slots hold 0.
   type Matching_Result is record
      Size : Natural := 0;
      N    : Natural := 0;
      Mate : Mate_Array (1 .. Max_Vertices) := [others => 0];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for Vertex_Count / Edge_Count overflow, vertex ids outside
   --  1 .. N, self-loops, Matching_Oracle_Brute when N > Max_Oracle, or
   --  inspector / helper bound violations.

   ---------------------------------------------------------------------------
   -- Undirected unweighted graph (adjacency lists; loopless)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty undirected graph on vertices 1 .. Vertex_Count
   --  (no edges). Vertex_Count = 0 yields an empty graph. Raises
   --  Invalid_Argument when Vertex_Count > Max_Vertices.

   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id)
     with Global => null;
   --  Append an undirected edge {U, V} (stored as two directed arcs).
   --  Parallel edges are permitted (they do not change the maximum
   --  matching). Self-loops are rejected. Raises Invalid_Argument when
   --  U = V, when U or V is outside 1 .. Vertex_Count(G), or when
   --  Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of undirected edges currently stored (including parallels).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Edmonds blossom)
   ---------------------------------------------------------------------------
   --  Maintain a partial matching via Mate (0 = NIL). Repeatedly search
   --  for an M-augmenting path from a free vertex with an alternating
   --  forest. An unmatched neighbour ends an augmenting path (flip along
   --  parent pointers). An edge between two even (outer / S) vertices
   --  in the same tree is an odd cycle — a blossom — contracted to its
   --  base (union of bases) so the search continues in the contracted
   --  graph. An S–S edge between different trees is an augmenting path
   --  through the two roots. Stop when no augmenting path remains.
   --  By Berge's lemma the matching is then maximum. Contrast (README
   --  only): Hopcroft–Karp is the bipartite special case (no odd cycles,
   --  so no blossoms); Hungarian optimizes edge weights under a perfect
   --  bipartite matching. Matching_Oracle_Brute enumerates induced
   --  matchings by subset DP for tiny N.

   procedure Maximum_Matching (G : Graph; Result : out Matching_Result)
     with Global => null;
   --  Edmonds blossom: compute a maximum-cardinality matching. Fills
   --  Result.Size, Result.N, and Mate (0 = unmatched). Empty N = 0
   --  yields Size = 0.

   ---------------------------------------------------------------------------
   -- Subset-DP / bitset matching oracle (tiny graphs)
   ---------------------------------------------------------------------------

   procedure Matching_Oracle_Brute (G : Graph; Result : out Matching_Result)
     with Global => null;
   --  Exact maximum matching by DP over vertex subsets (bitset of
   --  neighbours). Agrees with Maximum_Matching on cardinality for every
   --  valid instance with N ≤ Max_Oracle. Raises Invalid_Argument when
   --  Vertex_Count(G) > Max_Oracle.

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Is_Valid_Matching
     (G : Graph; Result : Matching_Result) return Boolean
     with Global => null;
   --  True iff Result.N matches Vertex_Count(G), Mate entries are mutual
   --  partners for a matching of Size edges that all exist in G
   --  (parallel edges count as present), and unmatched slots are 0.
   --  False (does not raise) when the dimension disagrees.

   function Edge_U (G : Graph; Index : Positive) return Vertex_Id
     with Global => null;
   function Edge_V (G : Graph; Index : Positive) return Vertex_Id
     with Global => null;
   --  Inspect the Index-th undirected edge (1 .. Edge_Count) in
   --  insertion order (endpoints as passed to Add_Edge). Raises
   --  Invalid_Argument when Index is outside 1 .. Edge_Count(G).

private

   --  Each undirected edge consumes two directed slots in the arc pool.
   Max_Arcs : constant Positive := 2 * Max_Edges;

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Arc_Index is Positive range 1 .. Max_Arcs;
   subtype Edge_Index is Positive range 1 .. Max_Edges;

   type Head_Array is array (Vertex_Id) of Natural;
   type To_Array is array (Arc_Index) of Vertex_Id;
   type Next_Array is array (Arc_Index) of Natural;
   type End_Array is array (Edge_Index) of Vertex_Id;

   type Graph is limited record
      N    : Natural := 0;
      M    : Edge_Count_T := 0;
      A    : Natural := 0;  -- directed arc count (= 2 * M)
      Head : Head_Array := [others => 0];
      To   : To_Array := [others => Vertex_Id'First];
      Next : Next_Array := [others => 0];
      EU   : End_Array := [others => Vertex_Id'First];
      EV   : End_Array := [others => Vertex_Id'First];
   end record;

end Blossom_Algorithm;
