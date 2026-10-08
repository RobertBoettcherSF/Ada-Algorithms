--  Dijkstras_Algorithm — Ada/SPARK Level 4 educational package for
--  Dijkstra's (1959) single-source / point-to-point shortest paths on a
--  bounded directed graph with non-negative edge weights. Classic dense
--  O(V²) selection: at each step settle the unsettled vertex with
--  smallest tentative distance and relax its outgoing edges. No
--  priority-queue / heap machinery. Non-negative weights ⇒ a settled
--  distance is final (no reopen). Path reconstruction via Prev.
--
--  SPARK port of Ada-Dijkstras-Algorithm: hard Max_Vertices / Max_Edges
--  classroom bounds, static CSR adjacency (Head/To/Weight/Next), no
--  exceptions, Pre/Found replace Invalid_Argument. Non-SPARK sibling uses
--  Max_Vertices = 1000, Max_Edges = 100_000, Integer weights, and raises
--  exceptions. Closest SPARK sibling shape: Ada-SPARK-A-Star (same CSR /
--  dense open-set style; A* adds a heuristic — do not `with` it).
--
--  Reference: https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm
--  Do not `with` sibling A* / UCS packages.

package Dijkstras_Algorithm
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

   --  Cap on a single edge weight so path sums stay far below
   --  Distance_Value'Last (overflow-safe adds).
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

   --  Path / cumulative distances. Infinity marks unreachable.
   type Distance_Value is range 0 .. 2**31 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   type Distance_Array is array (Vertex_Id range <>) of Distance_Value;
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
   -- Shape guards (expression functions — usable in Pre)
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

   ---------------------------------------------------------------------------
   -- Graph mutators
   ---------------------------------------------------------------------------

   procedure Clear (G : out Graph; Vertex_Count : Vertex_Count_T)
     with
       Global => null,
       Post   =>
         Well_Formed (G)
         and then Dijkstras_Algorithm.Vertex_Count (G) = Vertex_Count
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
   -- Algorithm sketch (dense Dijkstra, unsettled set = array scan)
   ---------------------------------------------------------------------------
   --  Initialise Dist(v) ← ∞, Prev(v) ← 0; Dist(Source) ← 0.
   --  Settled starts empty. While some unsettled vertex has finite Dist
   --  (≤ Max_Vertices settles, classroom bound):
   --    u ← argmin_{v not settled} Dist(v)   -- dense O(V) scan
   --    mark u settled
   --    if u = Target then stop (non-neg weights ⇒ Dist(Target) optimal)
   --    for each edge u → w with weight c:
   --      alt ← Dist(u) + c
   --      if alt < Dist(w) and w unsettled then Dist(w) ← alt; Prev(w) ← u
   --  Time Θ(V² + E) with array scan (classic educational formulation).

   pragma Warnings (Off, "referenced before it has a value");
   procedure Search
     (G      : Graph;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array;
      Path   : out Path_Array;
      Length : out Natural;
      Found  : out Boolean)
     with
       Global                 => null,
       Relaxed_Initialization => (Dist, Prev, Path),
       Pre                    =>
         Well_Formed (G)
         and then Vertex_Count (G) > 0
         and then Natural (Source) <= Vertex_Count (G)
         and then Natural (Target) <= Vertex_Count (G)
         and then Dist'First = 1
         and then Dist'Last >= Vertex_Id (Vertex_Count (G))
         and then Prev'First = 1
         and then Prev'Last >= Vertex_Id (Vertex_Count (G))
         and then Path'First = 1
         and then Path'Last >= Vertex_Count (G),
       Post                   =>
         Dist'Initialized
         and then Prev'Initialized
         and then Path'Initialized
         and then
           (if Found then
              Dist (Target) < Infinity
              and then Length in 1 .. Vertex_Count (G)
              and then Path (1) = Source
              and then Path (Length) = Target
              and then Dist (Source) = 0
            else
              Length = 0);
   --  Dense Dijkstra from Source toward Target. On success Found is True,
   --  Dist(V) is the shortest Source→V distance for settled vertices
   --  (Infinity if never reached), Prev encodes a shortest-path tree, and
   --  Path(1 .. Length) is the Source→Target vertex sequence. On failure
   --  Found is False and Length = 0. Source = Target yields Length = 1
   --  and Dist(Source) = 0.
   --  SPARK proves RTE freedom, index bounds, and the Found ⇒ path-shape
   --  postcondition. Full optimality of Dist(Target) is checked by tests
   --  on small graphs (not proved at Level 4).

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

end Dijkstras_Algorithm;
