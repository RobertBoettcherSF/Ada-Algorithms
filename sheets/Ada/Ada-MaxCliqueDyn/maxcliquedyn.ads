--  MaxCliqueDyn — Ada 2023 educational package for the MaxCliqueDyn
--  maximum-clique algorithm on undirected simple graphs. Branch-and-bound
--  search with a greedy ColorSort-style colouring upper bound (Konc &
--  Janezic, 2007 spirit). Vertices indexed from 1; adjacency stored as
--  Unsigned_64 bitsets (Max_Vertices = 64). No dynamic heap beyond fixed
--  educational workspaces.
--  Reference: https://en.wikipedia.org/wiki/MaxCliqueDyn_algorithm
--  Sibling sheets (README only — do not `with`): Branch-and-Bound,
--  Bron–Kerbosch — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

with Interfaces;

package MaxCliqueDyn
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; clique is NP-hard — keep N small)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   --  Bitset adjacency uses Interfaces.Unsigned_64, so N ≤ 64.
   Max_Vertices : constant Positive := 64;

   ---------------------------------------------------------------------------
   -- Vertex identifiers and clique membership
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Membership flags for vertices 1 .. Max_Vertices. After a successful
   --  Find_Maximum_Clique, Clique(V) is True iff V belongs to the reported
   --  maximum clique (and V ≤ Vertex_Count); entries beyond N are False.
   type Vertex_Set is array (Vertex_Id) of Boolean;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for Vertex_Count > Max_Vertices, vertex ids outside
   --  1 .. Vertex_Count(G), or other API precondition failures.

   ---------------------------------------------------------------------------
   -- Undirected simple graph (bitset adjacency)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty undirected graph on vertices 1 .. Vertex_Count
   --  (no edges). Vertex_Count = 0 yields an empty graph. Raises
   --  Invalid_Argument when Vertex_Count > Max_Vertices.

   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id)
     with Global => null;
   --  Insert an undirected edge {U,V}. Self-loops (U = V) and duplicate
   --  edges are ignored (no-op). Raises Invalid_Argument when U or V is
   --  outside 1 .. Vertex_Count(G).

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of undirected edges currently stored in G.

   function Is_Adjacent (G : Graph; U, V : Vertex_Id) return Boolean
     with Global => null;
   --  True iff {U,V} is an edge. Raises Invalid_Argument when U or V is
   --  outside 1 .. Vertex_Count(G). Returns False for U = V.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (MaxCliqueDyn colouring-bound BnB spirit)
   ---------------------------------------------------------------------------
   --  Maintain a growing clique Q and an incumbent Qmax. At each node the
   --  candidate set R is greedily coloured (ColorSort): vertices are first
   --  ordered by nonincreasing degree in the induced subgraph G[R], then
   --  assigned the smallest colour class compatible with non-adjacency.
   --  Colour numbers supply the optimistic bound
   --    |Q| + C(p)  ≤  |Qmax|  ⇒  prune (no better clique through p).
   --  Candidates are expanded from highest colour downward. This package
   --  always recolours with degree order (educational simplification of
   --  MaxCliqueDyn's Tlimit-gated dynamic reordering); it is correct BnB
   --  with colouring pruning, not bit-identical to the 2007 paper.
   --  Worst-case time is exponential (NP-hard); bitset ops are O(1) per
   --  vertex for N ≤ 64.

   procedure Find_Maximum_Clique
     (G      : Graph;
      Clique : out Vertex_Set;
      Size   : out Natural)
     with Global => null;
   --  Compute one maximum clique of G. On success Size is ω(G) and
   --  Clique marks exactly Size members (a maximum clique). Empty graph
   --  ⇒ Size = 0 and Clique all False. Singleton / edgeless ⇒ Size = 1
   --  (any vertex) when N ≥ 1.

   function Maximum_Clique_Size (G : Graph) return Natural
     with Global => null;
   --  Return ω(G) = size of a maximum clique (same search as
   --  Find_Maximum_Clique; discards the vertex set).

   function Set_Size (S : Vertex_Set; N : Natural) return Natural
     with Global => null;
   --  Count True entries among S(1) .. S(N). Raises Invalid_Argument when
   --  N > Max_Vertices.

   function Is_Clique (G : Graph; S : Vertex_Set) return Boolean
     with Global => null;
   --  True iff every pair of distinct members of S ∩ {1..N} is adjacent
   --  in G (vacuously True for |S| ≤ 1).

private

   subtype Bit_Word is Interfaces.Unsigned_64;

   type Adj_Array is array (Vertex_Id) of Bit_Word;

   type Graph is limited record
      N   : Natural := 0;
      E   : Natural := 0;
      Adj : Adj_Array := [others => 0];
   end record;

end MaxCliqueDyn;
