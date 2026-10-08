--  Beam_Search — Ada 2023 educational package for level-synchronous beam
--  search on directed unweighted / unit-cost graphs. Beam search is a
--  memory-bounded modification of best-first search: at each depth it
--  expands every state in the current beam, ranks all new successors by
--  heuristic score H(v) (lower better), and keeps only the β best
--  (Beam_Width). Classic Wikipedia beam uses breadth-first / level order
--  with pruning to width β; β = 1 is hill-climbing-like; large β with
--  H ≡ 0 approximates BFS reachability on unit graphs. Incomplete and
--  non-optimal when β is small (a goal path may be pruned). Vertices
--  indexed from 1. Fixed educational arrays sized to Max_Vertices /
--  Max_Edges (no dynamic heap beyond search workspace).
--  Reference: https://en.wikipedia.org/wiki/Beam_search
--  Sibling sheets (README only — do not `with`): Best-First Search, BFS,
--  A*, Dijkstra — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Beam_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Graph (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 1_000;

   --  Maximum number of directed edges (parallel edges allowed; each
   --  Add_Edge consumes one slot until Clear).
   Max_Edges : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers, heuristics, paths
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   --  H(V) = estimated remaining cost from V to Goal (lower ⇒ more
   --  promising). Caller-supplied; typically H(Goal) = 0. Need not be
   --  admissible. This package ranks beam candidates by H alone (classic
   --  heuristic beam), not by g+h.
   type Heuristic_Array is array (Vertex_Id range <>) of Natural;

   --  Path sequence: Path (1) = Start; Path (Length) = Goal when found.
   --  Length is the number of vertices (arc count = Length − 1 when
   --  Length ≥ 1).
   type Path_Array is array (Positive range <>) of Vertex_Id;

   --  Expansion order for educational inspection (optional out-parameter
   --  on Search_With_Order): vertices whose out-neighbours were scanned,
   --  level by level within each beam.
   type Order_Array is array (Positive range <>) of Vertex_Id;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  edge capacity overflow, N = 0 on Search, Beam_Width = 0, H range
   --  that does not cover 1 .. N, or Path / Order array bounds that cannot
   --  hold the result (First /= 1 or Last < Vertex_Count when N > 0).

   ---------------------------------------------------------------------------
   -- Directed unweighted graph (adjacency lists)
   ---------------------------------------------------------------------------

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural)
     with Global => null;
   --  Reset G to an empty digraph on vertices 1 .. Vertex_Count (no edges).
   --  Vertex_Count = 0 yields an empty graph. Raises Invalid_Argument when
   --  Vertex_Count > Max_Vertices.

   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id)
     with Global => null;
   --  Append a directed edge From → To. Parallel edges and self-loops are
   --  permitted. For an undirected edge {u,v}, call Add_Edge twice (u→v
   --  and v→u). Raises Invalid_Argument when From or To is outside
   --  1 .. Vertex_Count(G), or when Edge_Count would exceed Max_Edges.
   --  Edges are prepended to the adjacency list of From.

   function Vertex_Count (G : Graph) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (G : Graph) return Natural
     with Global => null;
   --  Number of directed edges currently stored in G.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (level-synchronous beam search)
   ---------------------------------------------------------------------------
   --  Wikipedia: beam search builds a search tree level by level (like
   --  BFS). At each depth it generates all successors of states in the
   --  current beam, sorts them by increasing heuristic cost, and retains
   --  only the β best (beam width). Only retained states are expanded at
   --  the next depth. Ranking here uses f(v) = H(v) (heuristic score;
   --  lower better) — classic educational beam, not g+h. Visited-on-
   --  enqueue prevents cyclic re-expansion. Goal must survive into a
   --  beam (be among the top β at its discovery depth) — a high-H Goal
   --  sibling can be pruned even when generated. Incomplete when β is
   --  small; β ≥ frontier branching with H ≡ 0 approximates BFS
   --  reachability on unit-cost digraphs. β = 1 is hill-climbing-like.
   --  Time per depth O(F log F) to rank up to F candidates (educational
   --  sort); overall O(D · β · B log (β · B)) for depth D, branching B.
   --  Memory for the live beam is O(β) plus O(V) visited/Prev.

   function Search
     (G          : Graph;
      Start      : Vertex_Id;
      Goal       : Vertex_Id;
      H          : Heuristic_Array;
      Beam_Width : Natural;
      Path       : out Path_Array;
      Length     : out Natural) return Boolean
     with Global => null;
   --  Level-synchronous beam search from Start to Goal guided by H,
   --  retaining at most Beam_Width (= β) states per depth.
   --  On success returns True and writes Path (1 .. Length) with
   --  Path (1) = Start, Path (Length) = Goal. On failure (unreachable
   --  or pruned) returns False and Length = 0. Start = Goal yields
   --  Length = 1. Requires Path'First = 1 and Path'Last >= N when N > 0;
   --  H'First <= 1 and H'Last >= N; Beam_Width >= 1; raises
   --  Invalid_Argument otherwise, when Start / Goal are outside 1 .. N,
   --  or when N = 0.

   function Search
     (G          : Graph;
      Start      : Vertex_Id;
      Goal       : Vertex_Id;
      H          : Heuristic_Array;
      Beam_Width : Natural;
      Path       : out Path_Array;
      Length     : out Natural;
      Expansions : out Natural) return Boolean
     with Global => null;
   --  Same as Search, also reporting Expansions = number of vertices
   --  expanded (out-neighbours scanned) across all beam levels.

   function Search_With_Order
     (G          : Graph;
      Start      : Vertex_Id;
      Goal       : Vertex_Id;
      H          : Heuristic_Array;
      Beam_Width : Natural;
      Path       : out Path_Array;
      Length     : out Natural;
      Order      : out Order_Array;
      Count      : out Natural;
      Expansions : out Natural) return Boolean
     with Global => null;
   --  Same as Search with Expansions, also writing the expansion order
   --  into Order (1 .. Count). Requires Order'First = 1 and
   --  Order'Last >= N when N > 0.

private

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Edge_Index is Positive range 1 .. Max_Edges;

   --  Adjacency via intrusive singly-linked edge nodes in a dense pool:
   --  Head(V) is the first edge index for V (0 = none); To(E) / Next(E)
   --  store the head and the remainder of the list.
   type Head_Array is array (Vertex_Id) of Natural;
   type To_Array is array (Edge_Index) of Vertex_Id;
   type Next_Array is array (Edge_Index) of Natural;

   type Graph is limited record
      N    : Natural := 0;
      E    : Edge_Count_T := 0;
      Head : Head_Array := [others => 0];
      To   : To_Array := [others => Vertex_Id'First];
      Next : Next_Array := [others => 0];
   end record;

end Beam_Search;
