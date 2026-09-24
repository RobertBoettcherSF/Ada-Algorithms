--  Minimum_Degree — Ada 2023 educational package for Wikipedia
--  "Minimum degree algorithm": classical fill-reducing ordering for
--  sparse symmetric positive-definite (SPD) patterns before Cholesky.
--  Explicit undirected graph (boolean adjacency, n ≤ 32); pick a
--  remaining vertex of minimum current degree (tie: lowest index),
--  add fill edges among its neighbors, remove it. No AMD/MMD
--  quotient-graph machinery — Approximate Minimum Degree is
--  Forthcoming. Primary source:
--  https://en.wikipedia.org/wiki/Minimum_degree_algorithm
--  Siblings: Ada-Cuthill-McKee / Ada-Sparse-Matrix /
--  Ada-Conjugate-Gradient (README links).

pragma Ada_2022;

package Minimum_Degree
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / domain types
   ---------------------------------------------------------------------------

   Max_Vertices : constant := 32;

   subtype Vertex_Count is Natural  range 0 .. Max_Vertices;
   subtype Vertex_Id    is Positive range 1 .. Max_Vertices;

   --  Elimination / permutation order: Ord (K) is the K-th eliminated
   --  vertex (1-based positions in the order array).
   type Order is array (Positive range <>) of Vertex_Id;

   type Bool_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Boolean;

   ---------------------------------------------------------------------------
   -- Graph: undirected simple graph via boolean adjacency (no loops)
   ---------------------------------------------------------------------------

   type Graph (N : Vertex_Count := 0) is record
      Adj : Bool_Matrix (1 .. N, 1 .. N) := [others => [others => False]];
   end record;

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Construction / queries
   ---------------------------------------------------------------------------

   function Empty_Graph (N : Vertex_Count) return Graph
     with Post => Empty_Graph'Result.N = N;

   procedure Clear (G : in out Graph);
   --  Remove all edges; keep vertex count.

   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id)
     with Pre => U in 1 .. G.N and then V in 1 .. G.N;
   --  Undirected; no-op if U = V or edge already present.
   --  Raises Invalid_Argument if U or V out of range (defensive).

   function Has_Edge (G : Graph; U, V : Vertex_Id) return Boolean
     with Pre => U in 1 .. G.N and then V in 1 .. G.N;

   function Degree (G : Graph; V : Vertex_Id) return Natural
     with Pre => V in 1 .. G.N;
   --  Number of neighbors of V in G.

   function Edge_Count (G : Graph) return Natural;
   --  Number of undirected edges (|E|).

   function Is_Symmetric_Pattern (G : Graph) return Boolean;
   --  Adj (I, J) = Adj (J, I) and diagonal False (educational check).

   ---------------------------------------------------------------------------
   -- Textbook graph builders
   ---------------------------------------------------------------------------

   function Path_Graph (N : Vertex_Count) return Graph
     with Pre => N <= Max_Vertices;
   --  Path 1—2—…—N.

   function Cycle_Graph (N : Vertex_Count) return Graph
     with Pre => N >= 3 and then N <= Max_Vertices;
   --  Cycle 1—2—…—N—1.

   function Star_Graph (N : Vertex_Count) return Graph
     with Pre => N >= 1 and then N <= Max_Vertices;
   --  Center = 1 connected to leaves 2 .. N.

   function Clique_Graph (N : Vertex_Count) return Graph
     with Pre => N <= Max_Vertices;
   --  Complete graph K_N.

   function Band_Graph (N : Vertex_Count; Bandwidth : Natural) return Graph
     with Pre => N <= Max_Vertices;
   --  Edges |i−j| ≤ Bandwidth (symmetric band pattern).

   ---------------------------------------------------------------------------
   -- Ordering
   ---------------------------------------------------------------------------

   function Natural_Order (G : Graph) return Order
     with Post => Natural_Order'Result'Length = G.N;
   --  1, 2, …, N.

   function Reverse_Natural_Order (G : Graph) return Order
     with Post => Reverse_Natural_Order'Result'Length = G.N;
   --  N, N−1, …, 1.

   function Is_Valid_Order (G : Graph; Ord : Order) return Boolean;
   --  Ord is a permutation of 1 .. G.N.

   function Minimum_Degree_Order (G : Graph) return Order
     with Post => Minimum_Degree_Order'Result'Length = G.N;
   --  Classical MD: while vertices remain, eliminate a remaining vertex
   --  of minimum current degree (tie → lowest Vertex_Id); add fill edges
   --  among its remaining neighbors; remove the vertex.

   ---------------------------------------------------------------------------
   -- Fill-in / symbolic Cholesky helpers
   ---------------------------------------------------------------------------

   function Fill_In_Count (G : Graph; Ord : Order) return Natural
     with Pre => Is_Valid_Order (G, Ord);
   --  New undirected edges created while simulating elimination in Ord.

   function Filled_Edge_Count (G : Graph; Ord : Order) return Natural
     with Pre => Is_Valid_Order (G, Ord);
   --  |E| + Fill_In_Count (edges in the filled graph after elimination).

   function Symbolic_Cholesky_Nnz (G : Graph; Ord : Order) return Natural
     with Pre => Is_Valid_Order (G, Ord);
   --  nnz(L) for the symbolic factor of an SPD matrix with pattern G
   --  under ordering Ord: N (diagonal) + Filled_Edge_Count (each
   --  undirected filled edge → one strict lower entry).

   function Natural_Fill (G : Graph) return Natural;
   --  Fill_In_Count (G, Natural_Order (G)).

   function MD_Fill (G : Graph) return Natural;
   --  Fill_In_Count (G, Minimum_Degree_Order (G)).

   function Fill_Reduction (G : Graph) return Integer;
   --  Natural_Fill − MD_Fill (positive ⇒ MD created fewer fills).

   ---------------------------------------------------------------------------
   -- Taxonomy (survey; only classical MD implemented)
   ---------------------------------------------------------------------------

   type Method_Kind is
     (Classical_Minimum_Degree,
      Multiple_Minimum_Degree,
      Approximate_Minimum_Degree,
      Nested_Dissection);

   function Method_Name (M : Method_Kind) return String;
   function Implemented (M : Method_Kind) return Boolean;
   function Forthcoming (M : Method_Kind) return Boolean;

end Minimum_Degree;
