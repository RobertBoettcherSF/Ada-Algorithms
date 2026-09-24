--  A_Star — Ada/SPARK Level 4 educational package for A* (Hart–Nilsson–
--  Raphael) point-to-point shortest paths on a bounded directed graph with
--  non-negative edge weights and a caller-supplied heuristic. Evaluation
--  function f(n) = g(n) + h(n): g is path cost from Source, h estimates
--  remaining cost to Goal. Open-set selection is a dense O(V) scan — no
--  priority-queue / heap machinery. An admissible heuristic yields an
--  optimal path cost (checked by tests on small graphs); full optimality
--  is not proved at Level 4. Heuristic all zeros reduces A* to dense
--  Dijkstra on the same digraph.
--
--  SPARK port of Ada-A-Star: hard Max_Vertices / Max_Edges classroom
--  bounds, static CSR adjacency (Head/To/Weight/Next), no exceptions,
--  Pre/Found replace Invalid_Argument. Non-SPARK sibling uses Max_Vertices
--  = 1000, Max_Edges = 100_000, Integer weights, and raises exceptions.
--
--  Reference: https://en.wikipedia.org/wiki/A*_search_algorithm
--  Do not `with` sibling Dijkstra / UCS packages.

package A_Star
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

   --  Cap on a single edge weight / heuristic entry so path sums and
   --  f-scores stay far below Distance_Value'Last (overflow-safe adds).
   Max_Weight : constant Positive := 1_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   subtype Vertex_Count_T is Natural range 0 .. Max_Vertices;
   subtype Vertex_Id is Positive range 1 .. Max_Vertices;
   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Edge_Index is Positive range 1 .. Max_Edges;

   --  Non-negative edge weight (type replaces sibling's Integer + raise).
   type Weight_Type is range 0 .. Max_Weight;

   --  Path / cumulative distances (g-scores). Infinity marks unreachable.
   type Distance_Value is range 0 .. 2**31 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   --  Non-negative heuristic estimate (type ⇒ H(V) ≥ 0 automatically).
   type Heuristic_Value is range 0 .. Max_Weight;

   type Distance_Array is array (Vertex_Id range <>) of Distance_Value;
   type Heuristic_Array is array (Vertex_Id range <>) of Heuristic_Value;
   --  Prev(V) = predecessor of V on a Source→V path, or 0 if none.
   type Prev_Array is array (Vertex_Id range <>) of Natural;
   type Path_Array is array (Positive range <>) of Vertex_Id;

   ---------------------------------------------------------------------------
   -- Directed weighted graph (static CSR adjacency lists)
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
      Dist : Distance_Array;
      Prev : Prev_Array;
      Path : Path_Array) return Boolean is
     (N > 0
      and then Dist'First = 1
      and then Dist'Last >= Vertex_Id (N)
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
   --  (range 0 .. Max_Weight); documented here for the Level-4 Pre.

   ---------------------------------------------------------------------------
   -- Graph mutators
   ---------------------------------------------------------------------------

   procedure Clear (G : out Graph; Vertex_Count : Vertex_Count_T)
     with
       Global => null,
       Post   =>
         Well_Formed (G)
         and then A_Star.Vertex_Count (G) = Vertex_Count
         and then Edge_Count (G) = 0;
   --  Reset G to an empty digraph on vertices 1 .. Vertex_Count (no edges).
   --  Vertex_Count = 0 yields an empty graph. Range is the type bound.

   procedure Add_Edge
     (G              : in out Graph;
      From, To       : Vertex_Id;
      Weight         : Weight_Type)
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
   --  Append directed edge From → To with non-negative Weight.
   --  Parallel edges and self-loops are permitted.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (dense A*, open set = array scan)
   ---------------------------------------------------------------------------
   --  Initialise Dist(v) ← ∞, Prev(v) ← 0; Dist(Source) ← 0.
   --  Open = {v | Dist(v) < ∞ and not closed}; closed starts empty.
   --  While open nonempty (≤ Max_Vertices² expansions, classroom bound):
   --    u ← argmin_{v in open} Dist(v) + H(v)   -- dense O(V) scan
   --    mark u closed; count an expansion
   --    if u = Goal then stop (admissible H ⇒ Dist(Goal) optimal — tests)
   --    for each edge u → w with weight c:
   --      alt ← Dist(u) + c
   --      if alt < Dist(w) then Dist(w) ← alt; Prev(w) ← u;
   --        reopen w if it was closed (needed for admissible-only H)
   --  When H ≡ 0 everywhere, selection is by Dist alone ⇒ dense Dijkstra.
   --  Time Θ(V² + E) with array scan (classic educational formulation).

   pragma Warnings (Off, "referenced before it has a value");
   procedure Search
     (G              : Graph;
      Source         : Vertex_Id;
      Goal           : Vertex_Id;
      Heuristic      : Heuristic_Array;
      Dist           : out Distance_Array;
      Prev           : out Prev_Array;
      Path           : out Path_Array;
      Length         : out Natural;
      Found          : out Boolean;
      Nodes_Expanded : out Natural)
     with
       Global                 => null,
       Relaxed_Initialization => (Dist, Prev, Path),
       Pre                    =>
         Well_Formed (G)
         and then Vertex_Count (G) > 0
         and then Natural (Source) <= Vertex_Count (G)
         and then Natural (Goal) <= Vertex_Count (G)
         and then Dist'First = 1
         and then Dist'Last >= Vertex_Id (Vertex_Count (G))
         and then Prev'First = 1
         and then Prev'Last >= Vertex_Id (Vertex_Count (G))
         and then Path'First = 1
         and then Path'Last >= Vertex_Count (G)
         and then Heuristic'First = 1
         and then Heuristic'Last >= Vertex_Id (Vertex_Count (G)),
       Post                   =>
         Dist'Initialized
         and then Prev'Initialized
         and then Path'Initialized
         and then Nodes_Expanded <= Max_Vertices * Max_Vertices
         and then
           (if Found then
              Dist (Goal) < Infinity
              and then Length in 1 .. Vertex_Count (G)
              and then Path (1) = Source
              and then Path (Length) = Goal
              and then Dist (Source) = 0
            else
              Length = 0);
   --  A* from Source to Goal guided by Heuristic. On success Found is True,
   --  Dist(V) is the g-score for visited vertices (Infinity if never
   --  reached), Prev encodes a path tree, and Path(1 .. Length) is the
   --  Source→Goal vertex sequence. On failure Found is False and Length = 0.
   --  Source = Goal yields Length = 1 and Dist(Source) = 0.
   --  SPARK proves RTE freedom, index bounds, and the Found ⇒ path-shape
   --  postcondition. Full optimality of Dist(Goal) is checked by tests on
   --  small graphs (not proved at Level 4).

   pragma Warnings (On, "referenced before it has a value");

   pragma Warnings (Off, "referenced before it has a value");
   procedure Reconstruct_Path
     (Prev   : Prev_Array;
      Source : Vertex_Id;
      Target : Vertex_Id;
      N      : Vertex_Count_T;
      Path   : out Path_Array;
      Length : out Natural;
      Ok     : out Boolean)
     with
       Global                 => null,
       Relaxed_Initialization => Path,
       Pre                    =>
         N > 0
         and then Natural (Source) <= N
         and then Natural (Target) <= N
         and then Prev'First = 1
         and then Prev'Last >= Vertex_Id (N)
         and then Path'First = 1
         and then Path'Last >= N,
       Post                   =>
         Path'Initialized
         and then
           (if Ok then
              Length in 1 .. N
              and then Path (1) = Source
              and then Path (Length) = Target
            else
              Length = 0);
   --  Walk Prev from Target back to Source and reverse into Path.
   --  Ok is True with Path(1) = Source … Path(Length) = Target when a
   --  path exists in the tree (including Source = Target with Length = 1
   --  when Prev(Source) = 0). Ok is False and Length = 0 otherwise.

   pragma Warnings (On, "referenced before it has a value");

private

   type Head_Array is array (Vertex_Id) of Natural;
   type To_Array is array (Edge_Index) of Vertex_Id;
   type Weight_Array is array (Edge_Index) of Weight_Type;
   type Next_Array is array (Edge_Index) of Natural;

   type Graph is limited record
      N      : Vertex_Count_T := 0;
      E      : Edge_Count_T := 0;
      Head   : Head_Array := [others => 0];
      To     : To_Array := [others => Vertex_Id'First];
      Weight : Weight_Array := [others => 0];
      Next   : Next_Array := [others => 0];
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

end A_Star;
