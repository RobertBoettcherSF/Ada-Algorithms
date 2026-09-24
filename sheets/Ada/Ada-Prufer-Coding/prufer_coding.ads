--  Prufer_Coding — Ada 2023 educational package for Prüfer sequences
--  (Prüfer codes) of labeled undirected trees. A Prüfer sequence of a
--  labeled tree on N vertices is a unique sequence of length N − 2 over
--  the labels 1 .. N. Encode iteratively removes the leaf of smallest
--  label and records its neighbour; Decode rebuilds the unique tree
--  from any sequence of length N − 2. The bijection proves Cayley's
--  formula: there are N^(N−2) labeled trees on N vertices.
--  Vertices indexed from 1. Fixed educational arrays sized to
--  Max_Vertices (no dynamic heap). ASCII package identifier
--  Prufer_Coding (umlaut only in prose / README).
--  Reference: https://en.wikipedia.org/wiki/Pr%C3%BCfer_sequence
--  Sibling sheets (README only — do not `with`): Minimum Spanning Tree,
--  Tarjan offline LCA — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Prufer_Coding
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Tree (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 1_024;

   --  Maximum undirected edges storable while building (trees use N − 1).
   Max_Edges : constant Positive := Max_Vertices - 1;

   ---------------------------------------------------------------------------
   -- Vertex / edge / code types
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   type Edge_Record is record
      U, V : Vertex_Id := 1;
   end record;

   type Edge_List is array (Positive range <>) of Edge_Record;

   --  Prüfer sequence entries are vertex labels in 1 .. N.
   type Code_Array is array (Positive range <>) of Vertex_Id;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, capacity overflow,
   --  self-loops, non-tree graphs on Encode, code values outside 1 .. N
   --  on Decode, or output buffers with First /= 1 / insufficient Last.

   ---------------------------------------------------------------------------
   -- Labeled undirected tree (built with Clear / Add_Edge)
   ---------------------------------------------------------------------------

   type Tree is limited private;

   procedure Clear (T : in out Tree; Vertex_Count : Natural)
     with Global => null;
   --  Reset T to an empty edge set on vertices 1 .. Vertex_Count.
   --  Vertex_Count = 0 yields an empty structure. Raises Invalid_Argument
   --  when Vertex_Count > Max_Vertices.

   procedure Add_Edge (T : in out Tree; U, V : Vertex_Id)
     with Global => null;
   --  Append an undirected edge {U, V}. Raises Invalid_Argument when U
   --  or V is outside 1 .. Vertex_Count(T), when U = V (self-loop), or
   --  when Edge_Count would exceed Max_Edges.

   function Vertex_Count (T : Tree) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Edge_Count (T : Tree) return Natural
     with Global => null;
   --  Number of undirected edges currently stored.

   procedure Get_Edges
     (T          : Tree;
      Edges      : out Edge_List;
      Edge_Count : out Natural)
     with Global => null;
   --  Copy the current undirected edges into Edges(1 .. Edge_Count).
   --  Raises Invalid_Argument when Edges'First /= 1 or Edges'Last is
   --  less than Edge_Count(T) when that count is positive.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Encode)
   ---------------------------------------------------------------------------
   --  Given a labeled tree T on vertices {1, …, N}:
   --    Repeat N − 2 times:
   --      Let ℓ be the leaf (degree 1) of smallest label;
   --      Append the unique neighbour of ℓ to the Prüfer sequence;
   --      Remove ℓ (and its incident edge) from T.
   --  The result has length N − 2. Vacuous: N ≤ 1 yields the empty
   --  sequence; N = 2 (single edge) also yields the empty sequence.

   procedure Encode
     (T      : Tree;
      Code   : out Code_Array;
      Length : out Natural)
     with Global => null;
   --  Compute the Prüfer sequence of T into Code(1 .. Length).
   --  Length = max(0, N − 2). Requires Code'First = 1 and
   --  Code'Last ≥ Length when Length > 0. For N ≥ 2 the graph must be
   --  a tree (exactly N − 1 edges, connected, no cycles). Raises
   --  Invalid_Argument when the graph is not a tree, when Code'First
   --  /= 1, or when Code is too short.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Decode)
   ---------------------------------------------------------------------------
   --  Let A = [a₁, …, a_{N−2}] with each aᵢ ∈ {1, …, N}, N = |A| + 2.
   --    degree[v] ← 1 + (occurrences of v in A).
   --    For i = 1 .. N − 2:
   --      Let j be the least label with degree[j] = 1;
   --      Add edge {j, aᵢ}; decrement degree[j] and degree[aᵢ].
   --    Add the edge between the two remaining degree-1 vertices.
   --  Every sequence of length N − 2 over 1 .. N maps to a unique tree.

   procedure Decode
     (Code : Code_Array;
      T    : out Tree)
     with Global => null;
   --  Rebuild the unique labeled tree on N = Code'Length + 2 vertices
   --  whose Prüfer sequence is Code. Requires Code'First = 1 (empty
   --  Code with Length 0 yields the unique 2-vertex tree {1—2}).
   --  Raises Invalid_Argument when Code'First /= 1, when N would exceed
   --  Max_Vertices, or when any Code(I) is outside 1 .. N.

   procedure Decode_Edges
     (Code       : Code_Array;
      Edges      : out Edge_List;
      Edge_Count : out Natural;
      N          : out Natural)
     with Global => null;
   --  Same reconstruction as Decode, writing the N − 1 undirected edges
   --  into Edges(1 .. Edge_Count) with Edge_Count = N − 1 and
   --  N = Code'Length + 2. Raises Invalid_Argument under the same
   --  conditions as Decode, or when Edges'First /= 1 / Edges too short.

   ---------------------------------------------------------------------------
   -- Cayley helper (small N; educational)
   ---------------------------------------------------------------------------

   function Cayley_Count (N : Natural) return Natural
     with Global => null;
   --  Return N^(N−2) for 0 ≤ N ≤ 8 (fits in Natural on typical hosts).
   --  Convention: 0^0-style edge cases — Cayley_Count(0) = 0,
   --  Cayley_Count(1) = 1, Cayley_Count(2) = 1. Raises Invalid_Argument
   --  when N > 8 (educational overflow guard).

private

   --  Undirected edges stored once each; adjacency for Encode is built
   --  on demand in the body over fixed scratch arrays.

   type Edge_Store is array (1 .. Max_Edges) of Edge_Record;

   type Tree is limited record
      N     : Natural := 0;
      M     : Natural := 0;
      Edges : Edge_Store;
   end record;

end Prufer_Coding;
