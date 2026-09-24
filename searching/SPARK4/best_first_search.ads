--  Best_First_Search — Ada/SPARK Level 4 educational package for greedy
--  best-first search (pure heuristic search) on a bounded directed
--  unweighted / unit-cost digraph. Expands the open vertex with smallest
--  heuristic estimate H(v) toward a Goal. Open-set selection is a dense
--  O(V) scan — no priority-queue / heap machinery (the non-SPARK sibling
--  uses a binary heap). Closed / visited set marked on enqueue so cyclic
--  digraphs terminate. Yields a Start→Goal path when one is found. Not
--  optimal in general: contrast with BFS (fewest arcs), Dijkstra (f = g),
--  and A* (f = g + h).
--
--  SPARK port of Ada-Best-First-Search: hard Max_Vertices / Max_Edges
--  classroom bounds, static CSR adjacency (Head/To/Next; no weights), no
--  exceptions, Pre/Found replace Invalid_Argument. Non-SPARK sibling uses
--  Max_Vertices = 1000, Max_Edges = 100_000, a binary-heap open set, and
--  raises exceptions. Closest SPARK sibling shape: Ada-SPARK-A-Star /
--  Ada-SPARK-Dijkstras-Algorithm (same CSR / dense open-set style — do
--  not `with` them).
--
--  Reference: https://en.wikipedia.org/wiki/Best-first_search
--  Do not `with` sibling A* / Dijkstra / BFS packages.

package Best_First_Search
  with SPARK_Mode => On
is
   pragma Unevaluated_Use_Of_Old (Allow);

   ---------------------------------------------------------------------------
   -- Capacity bounds (classroom; keeps CSR / scan VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on |V|. Smaller than the non-SPARK sibling (1000) so
   --  Level 4 can discharge index / arithmetic VCs on the static CSR.
   Max_Vertices : constant Positive := 32;

   --  Hard bound on |E|. Smaller than the non-SPARK sibling (100_000).
   Max_Edges : constant Positive := 256;

   --  Cap on a single heuristic entry (type ⇒ H(V) ≥ 0 automatically).
   Max_Heuristic : constant Positive := 1_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   subtype Vertex_Count_T is Natural range 0 .. Max_Vertices;
   subtype Vertex_Id is Positive range 1 .. Max_Vertices;
   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Edge_Index is Positive range 1 .. Max_Edges;

   --  Non-negative heuristic estimate (type replaces sibling's Natural).
   type Heuristic_Value is range 0 .. Max_Heuristic;

   type Heuristic_Array is array (Vertex_Id range <>) of Heuristic_Value;
   --  Prev(V) = predecessor of V on a Start→V path, or 0 if none.
   type Prev_Array is array (Vertex_Id range <>) of Natural;
   type Path_Array is array (Positive range <>) of Vertex_Id;

   ---------------------------------------------------------------------------
   -- Directed unweighted graph (static CSR adjacency lists)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   --  Well-formed CSR: heads/nexts point into 1 .. E or 0; To(I) ≤ N for
   --  live edges; Next(I) < I (prepend discipline ⇒ acyclic edge chains).
   function Well_Formed (G : Graph) return Boolean
     with Global => null;

   function Vertex_Count (G : Graph) return Vertex_Count_T
     with Global => null;

   function Edge_Count (G : Graph) return Edge_Count_T
     with Global => null;

   ---------------------------------------------------------------------------
   -- Shape / heuristic guards (expression functions — usable in Pre)
   ---------------------------------------------------------------------------

   function Arrays_OK
     (N    : Vertex_Count_T;
      Prev : Prev_Array;
      Path : Path_Array) return Boolean is
     (N > 0
      and then Prev'First = 1
      and then Prev'Last >= Vertex_Id (N)
      and then Path'First = 1
      and then Path'Last >= N)
   with Global => null;

   function Heuristic_OK
     (N : Vertex_Count_T; Heuristic : Heuristic_Array) return Boolean is
     (N > 0
      and then Heuristic'First = 1
      and then Heuristic'Last >= Vertex_Id (N))
   with Global => null;
   --  Coverage of 1 .. N. H(V) ≥ 0 is implied by Heuristic_Value
   --  (range 0 .. Max_Heuristic); documented here for the Level-4 Pre.

   ---------------------------------------------------------------------------
   -- Graph mutators
   ---------------------------------------------------------------------------

   procedure Clear (G : out Graph; Vertex_Count : Vertex_Count_T)
     with
       Global => null,
       Post   =>
         Well_Formed (G)
         and then Best_First_Search.Vertex_Count (G) = Vertex_Count
         and then Edge_Count (G) = 0;
   --  Reset G to an empty digraph on vertices 1 .. Vertex_Count (no edges).
   --  Vertex_Count = 0 yields an empty graph. Range is the type bound.

   procedure Add_Edge
     (G        : in out Graph;
      From, To : Vertex_Id)
     with
       Global => null,
       Pre    =>
         Well_Formed (G)
         and then Vertex_Count (G) > 0
         and then Natural (From) <= Vertex_Count (G)
         and then Natural (To) <= Vertex_Count (G)
         and then Edge_Count (G) < Max_Edges,
       Post   =>
         Well_Formed (G)
         and then Vertex_Count (G) = Vertex_Count (G)'Old
         and then Edge_Count (G) = Edge_Count (G)'Old + 1;
   --  Append directed edge From → To (unit cost; weight ignored / absent).
   --  Parallel edges and self-loops are permitted. For an undirected edge
   --  {u,v}, call Add_Edge twice (u→v and v→u).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (dense greedy BeFS, open set = array scan)
   ---------------------------------------------------------------------------
   --  Judea Pearl / Wikipedia "Greedy BeFS": f(n) = h(n) only.
   --  Visited marked on enqueue (each vertex entered at most once):
   --    mark Start visited; open = {Start}; Prev(Start) ← 0
   --    while open nonempty (≤ Max_Vertices expansions):
   --      u ← argmin_{v in open} H(v)   -- dense O(V) scan; tie: smaller id
   --      remove u from open; count an expansion
   --      if u = Goal then reconstruct Prev and succeed
   --      for each edge u → w not yet visited:
   --        Prev(w) ← u; mark w visited; add w to open
   --        (if w = Goal, next scan selects it when H(Goal) is minimal)
   --  Not optimal in general. Time Θ(V² + E) with array scan.
   --  Non-SPARK sibling: binary-heap open set, O((V+E) log V).

   pragma Warnings (Off, "referenced before it has a value");
   procedure Search
     (G              : Graph;
      Start          : Vertex_Id;
      Goal           : Vertex_Id;
      Heuristic      : Heuristic_Array;
      Prev           : out Prev_Array;
      Path           : out Path_Array;
      Length         : out Natural;
      Found          : out Boolean;
      Nodes_Expanded : out Natural)
     with
       Global                 => null,
       Relaxed_Initialization => (Prev, Path),
       Pre                    =>
         Well_Formed (G)
         and then Vertex_Count (G) > 0
         and then Natural (Start) <= Vertex_Count (G)
         and then Natural (Goal) <= Vertex_Count (G)
         and then Prev'First = 1
         and then Prev'Last >= Vertex_Id (Vertex_Count (G))
         and then Path'First = 1
         and then Path'Last >= Vertex_Count (G)
         and then Heuristic'First = 1
         and then Heuristic'Last >= Vertex_Id (Vertex_Count (G)),
       Post                   =>
         Prev'Initialized
         and then Path'Initialized
         and then Nodes_Expanded <= Max_Vertices
         and then
           (if Found then
              Length in 1 .. Vertex_Count (G)
              and then Path (1) = Start
              and then Path (Length) = Goal
            else
              Length = 0);
   --  Greedy best-first from Start to Goal guided by Heuristic. On success
   --  Found is True, Prev encodes a path tree, and Path(1 .. Length) is the
   --  Start→Goal vertex sequence. On failure Found is False and Length = 0.
   --  Start = Goal yields Length = 1 and Nodes_Expanded = 0.
   --  SPARK proves RTE freedom, index bounds, and the Found ⇒ path-shape
   --  postcondition. Optimality is NOT claimed (greedy BeFS is not optimal
   --  in general); small-graph tests illustrate guiding H and non-optimality.

   pragma Warnings (On, "referenced before it has a value");

   pragma Warnings (Off, "referenced before it has a value");
   procedure Reconstruct_Path
     (Prev   : Prev_Array;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      N      : Vertex_Count_T;
      Path   : out Path_Array;
      Length : out Natural;
      Ok     : out Boolean)
     with
       Global                 => null,
       Relaxed_Initialization => Path,
       Pre                    =>
         N > 0
         and then Natural (Start) <= N
         and then Natural (Goal) <= N
         and then Prev'First = 1
         and then Prev'Last >= Vertex_Id (N)
         and then Path'First = 1
         and then Path'Last >= N,
       Post                   =>
         Path'Initialized
         and then
           (if Ok then
              Length in 1 .. N
              and then Path (1) = Start
              and then Path (Length) = Goal
            else
              Length = 0);
   --  Walk Prev from Goal back to Start and reverse into Path.
   --  Ok is True with Path(1) = Start … Path(Length) = Goal when a
   --  path exists in the tree (including Start = Goal with Length = 1
   --  when Prev(Start) = 0). Ok is False and Length = 0 otherwise.

   pragma Warnings (On, "referenced before it has a value");

private

   type Head_Array is array (Vertex_Id) of Natural;
   type To_Array is array (Edge_Index) of Vertex_Id;
   type Next_Array is array (Edge_Index) of Natural;

   type Graph is limited record
      N    : Vertex_Count_T := 0;
      E    : Edge_Count_T := 0;
      Head : Head_Array := [others => 0];
      To   : To_Array := [others => Vertex_Id'First];
      Next : Next_Array := [others => 0];
   end record;

   function Vertex_Count (G : Graph) return Vertex_Count_T is (G.N);
   function Edge_Count (G : Graph) return Edge_Count_T is (G.E);

   function Well_Formed (G : Graph) return Boolean is
     ((for all V in Vertex_Id =>
         G.Head (V) <= G.E
         and then (if V > G.N then G.Head (V) = 0))
      and then
        (for all I in Edge_Index =>
           (if I <= G.E then
              G.Next (I) < I
              and then Natural (G.To (I)) <= G.N
            else True)));

end Best_First_Search;
