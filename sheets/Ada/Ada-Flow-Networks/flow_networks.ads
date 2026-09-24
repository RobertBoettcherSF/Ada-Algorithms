--  Flow_Networks — Ada 2023 educational *survey* of flow-network concepts
--  and maximum s–t flow. Models a directed capacity network (G, c, s, t)
--  with Clear / Add_Edge / Source–Sink helpers, and embeds two classical
--  max-flow algorithms in-package (no `with` of sibling Ada-* sheets):
--    Edmonds_Karp — Ford–Fulkerson with BFS shortest residual paths, O(VE²);
--    Dinic        — level graph + blocking flows, O(V²E).
--  After a successful Max_Flow the residual graph yields a min-cut
--  partition (source-side reachability) and per-edge flows; |f| equals
--  the cut capacity (max-flow min-cut theorem). Vertices indexed from 1.
--  Fixed educational arrays sized to Max_Vertices / Max_Edges (no heap).
--  Primary source: https://en.wikipedia.org/wiki/Flow_network
--  Sibling sheets (README only): Ford–Fulkerson, Edmonds–Karp, Dinic,
--  Push–relabel — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Flow_Networks
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Network (indices 1 .. Max_Vertices).
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

   --  After Max_Flow: In_S(V) = True iff V is reachable from Source in
   --  the residual graph (source side of a min-cut).
   type Reachability_Array is array (Vertex_Id range <>) of Boolean;

   ---------------------------------------------------------------------------
   -- Algorithm selector (survey)
   ---------------------------------------------------------------------------

   type Method is (Edmonds_Karp, Dinic);
   --  Edmonds_Karp — BFS shortest (fewest-edge) residual augmenting paths.
   --  Dinic        — BFS level graph + DFS blocking flow phases.

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, negative capacities, empty network on flow
   --  APIs, unset Source/Sink when required, Reachability_Array bounds
   --  that cannot hold the result (First /= 1 or Last < Vertex_Count when
   --  N > 0), or Edge_Index outside 1 .. Edge_Count for flow / edge queries.

   ---------------------------------------------------------------------------
   -- Directed flow network (adjacency lists, integer capacities, s/t)
   ---------------------------------------------------------------------------

   type Network is limited private;

   procedure Clear (N : in out Network; Vertex_Count : Natural)
     with Global => null;
   --  Reset N to an empty digraph on vertices 1 .. Vertex_Count (no edges).
   --  Clears stored Source / Sink (Has_Source / Has_Sink become False).
   --  Vertex_Count = 0 yields an empty network. Raises Invalid_Argument when
   --  Vertex_Count > Max_Vertices.

   procedure Add_Edge
     (N : in out Network; From, To : Vertex_Id; Capacity : Integer)
     with Global => null;
   --  Append a directed capacity edge From → To with Capacity ≥ 0 and
   --  install a paired residual reverse arc To → From with residual 0.
   --  Parallel edges are permitted. Self-loops are permitted (they never
   --  contribute to an s–t flow). Raises Invalid_Argument when
   --  Capacity < 0, when From or To is outside 1 .. Vertex_Count(N), or
   --  when Edge_Count would exceed Max_Edges.

   function Vertex_Count (N : Network) return Natural
     with Global => null;
   --  Number of vertices V; valid vertex ids are 1 .. V (empty ⇒ 0).

   function Edge_Count (N : Network) return Natural
     with Global => null;
   --  Number of user-directed capacity edges currently stored in N
   --  (not counting residual reverse arcs).

   ---------------------------------------------------------------------------
   -- Source / Sink helpers (flow network = (G, c, s, t))
   ---------------------------------------------------------------------------

   procedure Set_Source (N : in out Network; Source : Vertex_Id)
     with Global => null;
   --  Designate Source as the network source s. Raises Invalid_Argument
   --  when Vertex_Count = 0 or Source is outside 1 .. Vertex_Count(N).

   procedure Set_Sink (N : in out Network; Sink : Vertex_Id)
     with Global => null;
   --  Designate Sink as the network sink t. Raises Invalid_Argument when
   --  Vertex_Count = 0 or Sink is outside 1 .. Vertex_Count(N).

   function Has_Source (N : Network) return Boolean
     with Global => null;
   function Has_Sink (N : Network) return Boolean
     with Global => null;
   --  True iff Set_Source / Set_Sink has been called since the last Clear.

   function Source (N : Network) return Vertex_Id
     with Global => null;
   function Sink (N : Network) return Vertex_Id
     with Global => null;
   --  Stored terminals. Raise Invalid_Argument when the corresponding
   --  Has_Source / Has_Sink is False.

   ---------------------------------------------------------------------------
   -- Survey sketch (max-flow / min-cut)
   ---------------------------------------------------------------------------
   --  A feasible flow obeys capacity constraints and conservation at every
   --  vertex except Source and Sink. The value |f| is the net outflow of
   --  Source (= net inflow of Sink). An augmenting path is a Source↝Sink
   --  walk of positive residual capacity; |f| is maximum iff none remain.
   --  Max-flow min-cut: when no residual Source↝Sink path exists, let S be
   --  the residual-reachable set from Source and T = V \ S; then
   --  |f| = Σ_{u∈S,v∈T} c(u,v) (capacity of the cut (S,T)).
   --  Edmonds_Karp: one BFS shortest path per augmentation, O(VE²).
   --  Dinic: O(V) level phases each with a blocking flow, O(V²E).
   --  Contrast (README only): classic Ford–Fulkerson (unspecified / DFS
   --  paths) and Push–relabel (local height / excess).

   function Max_Flow
     (N      : in out Network;
      Source : Vertex_Id;
      Sink   : Vertex_Id;
      Algo   : Method := Edmonds_Karp) return Flow_Value
     with Global => null;
   --  Compute maximum Source→Sink flow with Algo. Also stores Source/Sink
   --  on N (as if Set_Source / Set_Sink). Leaves residual state ready for
   --  Min_Cut_Partition / Edge_Flow. Source = Sink yields 0. Raises
   --  Invalid_Argument when V = 0 or Source / Sink is outside 1 .. V.

   function Max_Flow
     (N    : in out Network;
      Algo : Method := Edmonds_Karp) return Flow_Value
     with Global => null;
   --  Same as Max_Flow (N, Source(N), Sink(N), Algo). Raises
   --  Invalid_Argument when Has_Source or Has_Sink is False (or V = 0).

   procedure Min_Cut_Partition
     (N      : Network;
      Source : Vertex_Id;
      In_S   : out Reachability_Array)
     with Global => null;
   --  After Max_Flow: set In_S(V) True iff V is reachable from Source in
   --  the residual graph (source side of a min s–t cut). Requires
   --  In_S'First = 1 and In_S'Last >= Vertex_Count; raises Invalid_Argument
   --  otherwise, or when Source is outside 1 .. Vertex_Count, or when
   --  Vertex_Count = 0.

   function Edge_From (N : Network; Index : Positive) return Vertex_Id
     with Global => null;
   function Edge_To (N : Network; Index : Positive) return Vertex_Id
     with Global => null;
   function Edge_Capacity (N : Network; Index : Positive) return Capacity_Type
     with Global => null;
   function Edge_Flow (N : Network; Index : Positive) return Flow_Value
     with Global => null;
   --  Inspect the Index-th user edge (1 .. Edge_Count) in insertion order.
   --  Edge_Flow is meaningful after Max_Flow (0 before any flow call,
   --  after Clear / Add_Edge resets). Raises Invalid_Argument when Index
   --  is outside 1 .. Edge_Count(N).

   function Cut_Capacity
     (N : Network; In_S : Reachability_Array) return Flow_Value
     with Global => null;
   --  Sum of original capacities of user edges with From ∈ S and To ∉ S
   --  (S = {V | In_S(V)}). After a max-flow call with matching Source,
   --  equals the max-flow value (max-flow min-cut). Requires
   --  In_S'First = 1 and In_S'Last >= Vertex_Count; raises Invalid_Argument
   --  otherwise or when Vertex_Count = 0.

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

   type Network is limited record
      V         : Natural := 0;
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
      --  Stored terminals: 0 = unset; else a Vertex_Id value.
      Src_Set   : Boolean := False;
      Snk_Set   : Boolean := False;
      Src       : Vertex_Id := Vertex_Id'First;
      Snk       : Vertex_Id := Vertex_Id'First;
   end record;

end Flow_Networks;
