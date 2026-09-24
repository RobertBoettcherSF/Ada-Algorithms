--  Lexicographic_Breadth_First_Search — Ada 2023 educational package for
--  Lex-BFS (lexicographic breadth-first search) on undirected simple
--  graphs. Partition-refinement implementation following Rose, Tarjan &
--  Lueker (1976): an ordered sequence of vertex sets replaces the BFS
--  queue and breaks predecessor ties lexicographically. Vertices are
--  indexed from 1. No dynamic heap beyond fixed educational arrays sized
--  to Max_Vertices / Max_Edges.
--  Reference: https://en.wikipedia.org/wiki/Lexicographic_breadth-first_search
--  Sibling sheets (README only — do not `with`): Tarjan SCC, Bron–Kerbosch
--  — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Lexicographic_Breadth_First_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 1_000;

   --  Maximum number of undirected edges (self-loops and duplicates ignored).
   --  Each undirected edge occupies two directed adjacency slots.
   Max_Edges : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers and orderings
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Lex-BFS (or elimination) ordering: Order(I) is the I-th vertex in
   --  the produced sequence (I = 1 is first selected / first in Lex-BFS
   --  output; for a PEO, I = 1 is the first eliminated vertex).
   type Order_Array is array (Vertex_Id range <>) of Vertex_Id;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, empty / mismatched Order bounds, or other
   --  API precondition failures.

   ---------------------------------------------------------------------------
   -- Undirected simple graph (adjacency lists)
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
   --  outside 1 .. Vertex_Count(G), or when Edge_Count would exceed
   --  Max_Edges.

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
   -- Algorithm sketch (partition refinement / Rose–Tarjan–Lueker)
   ---------------------------------------------------------------------------
   --  Maintain an ordered sequence Σ of disjoint sets that partition the
   --  yet-unnumbered vertices. Initially Σ = [{Start}, V \ {Start}]
   --  (or a single set V when no distinguished start is required).
   --  Repeatedly:
   --    • remove a vertex v from the first set of Σ (and drop the set if
   --      empty);
   --    • append v to the Lex-BFS output;
   --    • for each still-unnumbered neighbour w ∈ S ∈ Σ, move w into a
   --      new set T placed immediately before S (one T per refined S per
   --      pivot), deleting S if it becomes empty.
   --  The first set of Σ always holds the vertices with the currently
   --  best lexicographic predecessor label, so each choice matches the
   --  declarative Lex-BFS rule. Time O(|V|+|E|) with list representation.
   --
   --  Chordal graphs: the reverse of a Lex-BFS ordering is always a
   --  perfect elimination ordering (PEO). Use Is_PEO on the reversed
   --  order to recognise chordal examples in tests.

   procedure Lex_BFS
     (G     : Graph;
      Start : Vertex_Id;
      Order : out Order_Array)
     with Global => null;
   --  Compute a Lex-BFS ordering of G that begins with Start. On success
   --  Order(1) = Start and Order(1 .. N) is a permutation of 1 .. N
   --  (N = Vertex_Count(G)). Requires Order'First = 1 and
   --  Order'Last >= N when N > 0; raises Invalid_Argument otherwise, or
   --  when Start is outside 1 .. N. Empty graph (N = 0) leaves Order
   --  unused (Start is still validated only when N > 0 — callers should
   --  use the Start-free overload for N = 0).

   procedure Lex_BFS (G : Graph; Order : out Order_Array)
     with Global => null;
   --  Lex-BFS with default start vertex 1 when N >= 1. Empty graph is
   --  accepted (no writes to Order). Same Order bounds as the Start
   --  overload.

   function Is_PEO (G : Graph; Order : Order_Array) return Boolean
     with Global => null;
   --  True iff Order(1 .. N) is a perfect elimination ordering of G:
   --  for every position I, the neighbours of Order(I) that occur later
   --  in Order form a clique. Requires Order'First = 1 and
   --  Order'Last >= N covering a permutation of 1 .. N; raises
   --  Invalid_Argument on bad bounds or when Order is not a permutation
   --  of 1 .. N. Vacuously True for N <= 1.

private

   --  Directed adjacency slots: two per undirected edge.
   Max_Arcs : constant Positive := 2 * Max_Edges;

   subtype Arc_Count_T is Natural range 0 .. Max_Arcs;
   subtype Arc_Index is Positive range 1 .. Max_Arcs;

   type Head_Array is array (Vertex_Id) of Natural;
   type To_Array is array (Arc_Index) of Vertex_Id;
   type Next_Array is array (Arc_Index) of Natural;

   type Graph is limited record
      N    : Natural := 0;
      E    : Natural := 0;  -- undirected edge count
      Arcs : Arc_Count_T := 0;
      Head : Head_Array := [others => 0];
      To   : To_Array := [others => Vertex_Id'First];
      Next : Next_Array := [others => 0];
   end record;

end Lexicographic_Breadth_First_Search;
