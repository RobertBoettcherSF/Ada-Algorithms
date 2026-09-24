--  Ford_Fulkerson_Algorithm — Ada 2023 educational package for the
--  Ford–Fulkerson method (maximum s–t flow via augmenting paths on a
--  residual graph with integer capacities). Classic Max_Flow uses DFS
--  to find augmenting paths; Max_Flow_BFS is the Edmonds–Karp sibling
--  (BFS / shortest residual path). After a successful max-flow call the
--  residual graph yields a min-cut partition (source-side reachability)
--  and per-edge flows. Vertices indexed from 1. Fixed educational arrays
--  sized to Max_Vertices / Max_Edges (no dynamic heap).
--  Reference: https://en.wikipedia.org/wiki/Ford%E2%80%93Fulkerson_algorithm
--  Sibling sheets (README only — do not `with`): Dinic, Push–relabel /
--  Karger's min-cut — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Ford_Fulkerson_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 512;

   --  Maximum number of directed capacity edges the user may Add_Edge
   --  (each call also installs a paired residual reverse arc internally).
   Max_Edges : constant Positive := 20_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, capacities, flows
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  Non-negative integer edge capacity stored after Add_Edge validation.
   --  Add_Edge accepts Integer and raises Invalid_Argument when Capacity < 0.
   type Capacity_Type is range 0 .. 2**31 - 1;

   --  Flow values / totals. Wide enough for sums of many capacities.
   type Flow_Value is range 0 .. 2**63 - 1;

   --  After Max_Flow / Max_Flow_BFS: In_S(V) = True iff V is reachable
   --  from Source in the residual graph (source side of a min-cut).
   type Reachability_Array is array (Vertex_Id range <>) of Boolean;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, negative capacities, empty graph on flow
   --  APIs, or Reachability_Array bounds that cannot hold the result
   --  (First /= 1 or Last < Vertex_Count when N > 0), or Edge_Index
   --  outside 1 .. Edge_Count for flow / edge queries.

   ---------------------------------------------------------------------------
   -- Directed flow network (adjacency lists, integer capacities)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty digraph on vertices 1 .. Vertex_Count (no edges).
   --  Vertex_Count = 0 yields an empty graph. Raises Invalid_Argument when
   --  Vertex_Count > Max_Vertices.

   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Capacity : Integer)
     with Global => null;
   --  Append a directed capacity edge From → To with Capacity ≥ 0 and
   --  install a paired residual reverse arc To → From with residual 0.
   --  Parallel edges are permitted. Self-loops are permitted (they never
   --  contribute to an s–t flow). Raises Invalid_Argument when
   --  Capacity < 0, when From or To is outside 1 .. Vertex_Count(G), or
   --  when Edge_Count would exceed Max_Edges.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of user-directed capacity edges currently stored in G
   --  (not counting residual reverse arcs).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Ford–Fulkerson / Edmonds–Karp)
   ---------------------------------------------------------------------------
   --  Maintain a residual capacity c_f(u,v) = c(u,v) − f(u,v) (and reverse
   --  residual f(u,v)). While an augmenting path Source ↝ Sink exists in
   --  the residual graph, push the bottleneck residual along that path.
   --  Max_Flow finds paths by DFS (classic FFA; terminates for integer
   --  capacities). Max_Flow_BFS finds a shortest residual path via BFS
   --  (Edmonds–Karp; O(VE²)). When no augmenting path remains, vertices
   --  reachable from Source in the residual graph form the source side S
   --  of a minimum s–t cut; |f| equals the cut capacity (max-flow min-cut).
   --  Contrast (README only): Dinic (level graph + blocking flow) and
   --  Push–relabel are faster practical max-flow algorithms; this sheet
   --  teaches the augmenting-path method.

   function Max_Flow
     (G : in out Graph; Source, Sink : Vertex_Id) return Flow_Value
     with Global => null;
   --  Classic Ford–Fulkerson: reset flows, then augment along DFS residual
   --  paths until none remain. Returns the maximum Source→Sink flow value.
   --  Leaves G's residual state ready for Min_Cut_Partition / Edge_Flow.
   --  Source = Sink yields 0. Raises Invalid_Argument when N = 0 or when
   --  Source / Sink is outside 1 .. N.

   function Max_Flow_BFS
     (G : in out Graph; Source, Sink : Vertex_Id) return Flow_Value
     with Global => null;
   --  Edmonds–Karp: same as Max_Flow but augmenting paths are found by
   --  BFS (shortest residual path in #edges). Same return / residual /
   --  exception contract as Max_Flow. On integer capacities both return
   --  the same optimal flow value (path choice may differ).

   procedure Min_Cut_Partition
     (G      : Graph;
      Source : Vertex_Id;
      In_S   : out Reachability_Array)
     with Global => null;
   --  After Max_Flow or Max_Flow_BFS: set In_S(V) True iff V is reachable
   --  from Source in the residual graph (source side of a min s–t cut).
   --  Requires In_S'First = 1 and In_S'Last >= N; raises Invalid_Argument
   --  otherwise, or when Source is outside 1 .. N, or when N = 0.

   function Edge_From (G : Graph; Index : Positive) return Vertex_Id
     with Global => null;
   function Edge_To (G : Graph; Index : Positive) return Vertex_Id
     with Global => null;
   function Edge_Capacity (G : Graph; Index : Positive) return Capacity_Type
     with Global => null;
   function Edge_Flow (G : Graph; Index : Positive) return Flow_Value
     with Global => null;
   --  Inspect the Index-th user edge (1 .. Edge_Count) in insertion order.
   --  Edge_Flow is meaningful after Max_Flow / Max_Flow_BFS (0 before any
   --  flow call, after Clear / Add_Edge resets). Raises Invalid_Argument
   --  when Index is outside 1 .. Edge_Count(G).

   function Cut_Capacity
     (G : Graph; In_S : Reachability_Array) return Flow_Value
     with Global => null;
   --  Sum of original capacities of user edges with From ∈ S and To ∉ S
   --  (S = {V | In_S(V)}). After a max-flow call with matching Source,
   --  equals the max-flow value (max-flow min-cut). Requires
   --  In_S'First = 1 and In_S'Last >= N; raises Invalid_Argument
   --  otherwise or when N = 0.

private

   --  Residual pool holds 2 slots per user edge (forward + reverse).
   Max_Residual : constant Positive := 2 * Max_Edges;

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype User_Edge_Index is Positive range 1 .. Max_Edges;
   subtype Residual_Index is Positive range 1 .. Max_Residual;

   type Head_Array is array (Vertex_Id) of Natural;
   type Residual_To_Array is array (Residual_Index) of Vertex_Id;
   type Residual_Cap_Array is array (Residual_Index) of Capacity_Type;
   type Residual_Rev_Array is array (Residual_Index) of Residual_Index;
   type Residual_Next_Array is array (Residual_Index) of Natural;

   type User_Vertex_Array is array (User_Edge_Index) of Vertex_Id;
   type User_Cap_Array is array (User_Edge_Index) of Capacity_Type;
   type User_Fwd_Array is array (User_Edge_Index) of Residual_Index;

   type Graph is limited record
      N         : Natural := 0;
      M         : Edge_Count_T := 0;
      Pool      : Natural := 0;  -- residual arcs allocated (0 .. Max_Residual)
      Head      : Head_Array := [others => 0];
      To        : Residual_To_Array := [others => Vertex_Id'First];
      Cap       : Residual_Cap_Array := [others => 0];
      Rev       : Residual_Rev_Array := [others => Residual_Index'First];
      Next      : Residual_Next_Array := [others => 0];
      User_From : User_Vertex_Array := [others => Vertex_Id'First];
      User_To   : User_Vertex_Array := [others => Vertex_Id'First];
      User_Cap  : User_Cap_Array := [others => 0];
      User_Fwd  : User_Fwd_Array := [others => Residual_Index'First];
   end record;

end Ford_Fulkerson_Algorithm;
