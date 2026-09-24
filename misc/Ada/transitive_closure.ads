--  Transitive_Closure — Ada 2023 educational package for directed-graph
--  reachability and the transitive closure of a homogeneous binary relation.
--  Warshall Boolean-matrix closure O(n^3) and per-source DFS / BFS
--  reachability produce the same R+ (or optional reflexive R*).
--  Vertices indexed from 1. Fixed educational Boolean matrices sized to
--  Max_Vertices (no dynamic heap).
--  Reference: https://en.wikipedia.org/wiki/Transitive_closure
--  Sibling sheets (README only — do not `with`): Floyd–Warshall,
--  Tarjan SCC — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Transitive_Closure
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices / relation elements (indices 1 .. Max_Vertices).
   --  Boolean n×n matrices fit comfortably in educational stack/workspace.
   Max_Vertices : constant Positive := 256;

   ---------------------------------------------------------------------------
   -- Vertex identifiers and Boolean matrices
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Square Boolean matrix over Vertex_Id ranges. Used for the adjacency
   --  relation R, the closure R+ / R*, and Is_Transitive checks.
   type Bool_Matrix is array (Vertex_Id range <>, Vertex_Id range <>) of Boolean;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count >
   --  Max_Vertices, empty-graph search APIs, or Bool_Matrix bounds that
   --  are not 1-based with Last >= N on both dimensions (when N > 0).

   ---------------------------------------------------------------------------
   -- Directed unweighted graph (Boolean adjacency)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty digraph on vertices 1 .. Vertex_Count (no edges).
   --  Vertex_Count = 0 yields an empty graph. Raises Invalid_Argument when
   --  Vertex_Count > Max_Vertices.

   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id)
     with Global => null;
   --  Add a directed unweighted edge From → To. Idempotent: repeating the
   --  same pair does not increase Edge_Count. Self-loops are permitted.
   --  Raises Invalid_Argument when From or To is outside 1 .. Vertex_Count(G).

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of distinct directed edges currently stored in G.

   function Has_Edge (G : Graph; From, To : Vertex_Id) return Boolean
     with Global => null;
   --  True iff the adjacency relation contains From → To.
   --  Raises Invalid_Argument when From or To is outside 1 .. N or N = 0.

   procedure Relation_Matrix (G : Graph; M : out Bool_Matrix)
     with Global => null;
   --  Copy the adjacency relation R into M (False elsewhere in 1 .. N).
   --  Requires M'First(1) = M'First(2) = 1 and M'Last(*) >= N when N > 0;
   --  raises Invalid_Argument otherwise. Vacuous: N = 0 raises.

   ---------------------------------------------------------------------------
   -- Algorithms
   ---------------------------------------------------------------------------
   --  Warshall (Boolean Floyd–Warshall without weights): initialise C ← R;
   --  optionally set diagonal for R*; then for k,i,j in 1 .. N:
   --    C(i,j) ← C(i,j) ∨ (C(i,k) ∧ C(k,j)).
   --  Time Θ(n^3), space Θ(n^2).
   --
   --  Reachability_DFS / Reachability_BFS: for each source s, explore the
   --  out-neighbourhood (DFS stack / BFS queue) and mark all vertices
   --  reachable by a walk of length ≥ 1. Same R+ as Warshall; with
   --  Reflexive => True, also force C(v,v) for all v (R*).
   --  Time O(n (n + m)) with Boolean adjacency scan, space Θ(n^2).

   procedure Warshall
     (G         : Graph;
      Closure   : out Bool_Matrix;
      Reflexive : Boolean := False)
     with Global => null;
   --  Transitive closure of G's adjacency via Warshall. Reflexive False
   --  yields R+ (paths of length ≥ 1); True yields R* = R+ ∪ I.
   --  Requires Closure First = 1 and Last >= N on both dims when N > 0;
   --  raises Invalid_Argument otherwise, or when N = 0.

   procedure Reachability_DFS
     (G         : Graph;
      Closure   : out Bool_Matrix;
      Reflexive : Boolean := False)
     with Global => null;
   --  Same result as Warshall, computed by DFS from each vertex.
   --  Same bound / empty-graph checks as Warshall.

   procedure Reachability_BFS
     (G         : Graph;
      Closure   : out Bool_Matrix;
      Reflexive : Boolean := False)
     with Global => null;
   --  Same result as Warshall, computed by BFS from each vertex.
   --  Same bound / empty-graph checks as Warshall.

   procedure Closure_Matrix
     (G         : Graph;
      Closure   : out Bool_Matrix;
      Reflexive : Boolean := False)
     with Global => null;
   --  Convenience: Warshall closure of G (default educational method).

   procedure Warshall_On_Matrix
     (Relation  : Bool_Matrix;
      Closure   : out Bool_Matrix;
      Reflexive : Boolean := False)
     with Global => null;
   --  Warshall on an explicit square relation matrix. Relation and Closure
   --  must share First = 1 and equal Last on both dimensions; raises
   --  Invalid_Argument when bounds are not a square 1 .. N with N ≥ 1.

   ---------------------------------------------------------------------------
   -- Queries
   ---------------------------------------------------------------------------

   function Reaches
     (G         : Graph;
      From, To  : Vertex_Id;
      Reflexive : Boolean := False) return Boolean
     with Global => null;
   --  True iff From R+ To (path of length ≥ 1), or From = To when Reflexive.
   --  Single-source DFS. Raises Invalid_Argument when From/To outside 1 .. N
   --  or N = 0.

   function Is_Transitive (M : Bool_Matrix; N : Natural) return Boolean
     with Global => null;
   --  True iff the 1 .. N principal submatrix of M is transitive:
   --  ∀ i,j,k in 1 .. N: M(i,j) ∧ M(j,k) ⇒ M(i,k). Requires
   --  M'First(1) = M'First(2) = 1 and M'Last(*) >= N with N ≥ 1; raises
   --  Invalid_Argument otherwise.

private

   type Adj_Matrix is array (Vertex_Id, Vertex_Id) of Boolean;

   type Graph is limited record
      N    : Natural := 0;
      E    : Natural := 0;
      Adj  : Adj_Matrix := [others => [others => False]];
   end record;

end Transitive_Closure;
