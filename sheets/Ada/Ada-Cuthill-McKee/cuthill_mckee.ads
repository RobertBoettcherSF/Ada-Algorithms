--  Cuthill_Mckee — Ada 2023 educational package for Wikipedia
--  "Cuthill–McKee algorithm" / Reverse Cuthill–McKee (RCM):
--  bandwidth-reducing orderings for sparse matrices with a
--  symmetric sparsity pattern. Explicit undirected graph
--  (boolean adjacency, n ≤ 32). CM builds a BFS level structure
--  from a (pseudo-)peripheral start and numbers neighbors in
--  increasing degree order; RCM reverses that order. Primary
--  source: https://en.wikipedia.org/wiki/Cuthill%E2%80%93McKee_algorithm
--  Siblings: Ada-Minimum-Degree / Ada-Sparse-Matrix (README links).

pragma Ada_2022;

package Cuthill_Mckee
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / domain types
   ---------------------------------------------------------------------------

   Max_Vertices : constant := 32;

   subtype Vertex_Count is Natural  range 0 .. Max_Vertices;
   subtype Vertex_Id    is Positive range 1 .. Max_Vertices;

   --  Permutation: Ord (K) is the vertex that receives new label K.
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

   function Band_Graph (N : Vertex_Count; Half_Bandwidth : Natural) return Graph
     with Pre => N <= Max_Vertices;
   --  Edges |i−j| ≤ Half_Bandwidth (symmetric band pattern).

   function Grid_Graph (Rows, Cols : Positive) return Graph
     with Pre => Rows * Cols <= Max_Vertices;
   --  Rows×Cols grid (4-neighbor mesh); vertices row-major 1 .. Rows*Cols.

   ---------------------------------------------------------------------------
   -- Ordering helpers
   ---------------------------------------------------------------------------

   function Natural_Order (G : Graph) return Order
     with Post => Natural_Order'Result'Length = G.N;
   --  1, 2, …, N.

   function Reverse_Natural_Order (G : Graph) return Order
     with Post => Reverse_Natural_Order'Result'Length = G.N;
   --  N, N−1, …, 1.

   function Is_Valid_Order (G : Graph; Ord : Order) return Boolean;
   --  Ord is a permutation of 1 .. G.N.

   function Reverse_Order (Ord : Order) return Order
     with Post => Reverse_Order'Result'Length = Ord'Length;
   --  Reverse a permutation array (used by RCM).

   ---------------------------------------------------------------------------
   -- Bandwidth / profile metrics
   ---------------------------------------------------------------------------

   function Bandwidth (G : Graph) return Natural;
   --  max |i−j| over edges {i,j} under the natural labeling 1 .. N.
   --  Isolated / empty graph → 0.

   function Bandwidth (G : Graph; Ord : Order) return Natural
     with Pre => Is_Valid_Order (G, Ord);
   --  Bandwidth after renumbering: Ord (K) gets new index K.
   --  max |new(u)−new(v)| over edges {u,v}.

   function Profile (G : Graph) return Natural;
   --  Envelope / profile under natural labeling:
   --  sum_i (i − min{j : Adj(i,j) or j=i}).

   function Profile (G : Graph; Ord : Order) return Natural
     with Pre => Is_Valid_Order (G, Ord);
   --  Profile after renumbering by Ord.

   ---------------------------------------------------------------------------
   -- CM / RCM / pseudo-peripheral
   ---------------------------------------------------------------------------

   function Pseudo_Peripheral_Vertex
     (G     : Graph;
      Start : Vertex_Id := 1) return Vertex_Id
     with Pre => G.N >= 1 and then Start in 1 .. G.N;
   --  George–Liu-style heuristic: iterate farthest-from-farthest
   --  (prefer min-degree vertex in the last BFS level) a few times.

   function Cuthill_Mckee_Order
     (G     : Graph;
      Start : Natural := 0) return Order
     with
       Pre  => Start = 0 or else Start in 1 .. G.N,
       Post => Cuthill_Mckee_Order'Result'Length = G.N;
   --  Classical CM. If Start = 0 (default), use Pseudo_Peripheral_Vertex
   --  (rooted at a minimum-degree vertex). Otherwise start at Start.
   --  Disconnected graphs: restart CM on each remaining component from
   --  a pseudo-peripheral of that component.

   function Reverse_Cuthill_Mckee_Order
     (G     : Graph;
      Start : Natural := 0) return Order
     with
       Pre  => Start = 0 or else Start in 1 .. G.N,
       Post => Reverse_Cuthill_Mckee_Order'Result'Length = G.N;
   --  RCM = reverse (Cuthill_Mckee_Order (...)). Same Start convention.

   ---------------------------------------------------------------------------
   -- Taxonomy (survey)
   ---------------------------------------------------------------------------

   type Method_Kind is
     (Classical_CM,
      Classical_RCM,
      Sloan,
      Nested_Dissection);

   function Method_Name (M : Method_Kind) return String;
   function Implemented (M : Method_Kind) return Boolean;
   function Forthcoming (M : Method_Kind) return Boolean;

end Cuthill_Mckee;
