--  Cliques — Ada 2023 educational survey of clique concepts on undirected
--  simple graphs: definitions (clique / maximal / maximum), Bron–Kerbosch
--  maximal-clique enumeration with Tomita pivoting, and colouring-bound
--  branch-and-bound for one maximum clique and the clique number ω(G).
--  Vertices indexed from 1; adjacency as Unsigned_64 bitsets
--  (Max_Vertices = 64). Self-contained — algorithms are inlined here.
--  Reference: https://en.wikipedia.org/wiki/Clique_(graph_theory)
--  Sibling sheets (README only — do not `with`): Bron–Kerbosch,
--  MaxCliqueDyn — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

with Interfaces;

package Cliques
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; output / search can be exponential)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   --  Bitset adjacency uses Interfaces.Unsigned_64, so N ≤ 64.
   Max_Vertices : constant Positive := 64;

   --  Maximum number of maximal cliques retained by Enumerate_Maximal_Cliques.
   --  Moon–Moser: an n-vertex graph has ≤ 3^(n/3) maximal cliques; the cap
   --  guards educational callers against runaway output.
   Max_Cliques : constant Positive := 10_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers and clique membership
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Membership flags for vertices 1 .. Max_Vertices. After enumeration or
   --  Find_Maximum_Clique, S(V) is True iff V belongs to the reported set
   --  (and V ≤ Vertex_Count); entries beyond N are False.
   type Vertex_Set is array (Vertex_Id) of Boolean;

   type Clique_Array is array (1 .. Max_Cliques) of Vertex_Set;

   --  Fixed-capacity list of maximal cliques. Only indices 1 .. Count from
   --  Enumerate_Maximal_Cliques are meaningful.
   type Clique_List is record
      Items : Clique_Array := [others => [others => False]];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for Vertex_Count > Max_Vertices, vertex ids outside
   --  1 .. Vertex_Count(G), or other API precondition failures.

   Too_Many_Cliques : exception;
   --  Raised when enumeration would exceed Max_Cliques reported cliques.

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
   -- Predicates
   ---------------------------------------------------------------------------

   function Set_Size (S : Vertex_Set; N : Natural) return Natural
     with Global => null;
   --  Count True entries among S(1) .. S(N). Raises Invalid_Argument when
   --  N > Max_Vertices.

   function Is_Clique (G : Graph; S : Vertex_Set) return Boolean
     with Global => null;
   --  True iff every pair of distinct members of S ∩ {1..N} is adjacent
   --  in G (vacuously True for |S| ≤ 1).

   function Is_Maximal_Clique (G : Graph; S : Vertex_Set) return Boolean
     with Global => null;
   --  True iff S ∩ {1..N} is a non-empty clique and no vertex outside S
   --  is adjacent to every member of S. Empty S is not maximal.

   ---------------------------------------------------------------------------
   -- Maximal cliques — Bron–Kerbosch with Tomita pivoting (inline)
   ---------------------------------------------------------------------------
   --  Maintain R (growing clique), P (candidates), X (excluded). Report R
   --  when P = X = ∅. Pivot: choose u ∈ P ∪ X maximizing |P ∩ N(u)|, then
   --  recurse only on v ∈ P \ N(u). Maximal ≠ maximum: maximality is local;
   --  a maximum clique has size ω(G). See Find_Maximum_Clique / Clique_Number.

   procedure Enumerate_Maximal_Cliques
     (G       : Graph;
      Cliques : out Clique_List;
      Count   : out Natural)
     with Global => null;
   --  Enumerate all maximal cliques of G into Cliques.Items (1 .. Count).
   --  Empty graph ⇒ Count = 0. Edgeless n-vertex graph ⇒ n singleton
   --  cliques. Complete Kn ⇒ one clique of size n. Raises Too_Many_Cliques
   --  if more than Max_Cliques maximal cliques would be reported.

   function Maximal_Clique_Count (G : Graph) return Natural
     with Global => null;
   --  Number of maximal cliques (same search as Enumerate_Maximal_Cliques;
   --  discards the vertex sets). Raises Too_Many_Cliques on overflow.

   ---------------------------------------------------------------------------
   -- Maximum clique — colouring-bound BnB (inline, educational)
   ---------------------------------------------------------------------------
   --  Grow Q with incumbent Qmax. At each node greedily colour candidates R
   --  (degree order + ColorSort-style classes) and prune when
   --  |Q| + C(p) ≤ |Qmax|. Educational simplification of MaxCliqueDyn
   --  (always recolour; no Tlimit gate) — correct BnB, not bit-identical
   --  to Konc & Janežič 2007.

   procedure Find_Maximum_Clique
     (G      : Graph;
      Clique : out Vertex_Set;
      Size   : out Natural)
     with Global => null;
   --  Compute one maximum clique of G. On success Size is ω(G) and
   --  Clique marks exactly Size members. Empty graph ⇒ Size = 0.
   --  Singleton / edgeless ⇒ Size = 1 when N ≥ 1.

   function Clique_Number (G : Graph) return Natural
     with Global => null;
   --  Return ω(G) = size of a maximum clique (same search as
   --  Find_Maximum_Clique; discards the vertex set).

private

   subtype Bit_Word is Interfaces.Unsigned_64;

   type Adj_Array is array (Vertex_Id) of Bit_Word;

   type Graph is limited record
      N   : Natural := 0;
      E   : Natural := 0;
      Adj : Adj_Array := [others => 0];
   end record;

end Cliques;
