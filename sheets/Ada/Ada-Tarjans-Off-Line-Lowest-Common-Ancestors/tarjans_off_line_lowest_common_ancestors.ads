--  Tarjans_Off_Line_Lowest_Common_Ancestors — Ada 2023 educational
--  package for Tarjan's off-line lowest common ancestors (LCA)
--  algorithm on a rooted tree. All query pairs are supplied in advance;
--  one DFS over the tree plus Union–Find (disjoint-set) with path
--  compression and union-by-rank answers every query. Vertices indexed
--  from 1. Fixed educational arrays sized to Max_Vertices /
--  Max_Queries (no dynamic heap). Optional Naive_LCA for cross-checks
--  on small trees (walk-to-root / depth-lift). Union–Find is a
--  package-body private implementation detail.
--  Reference:
--  https://en.wikipedia.org/wiki/Tarjan%27s_off-line_lowest_common_ancestors_algorithm
--  Sibling sheets (README only — do not `with`): Kruskal (Union–Find),
--  Tarjan SCC — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Tarjans_Off_Line_Lowest_Common_Ancestors
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of vertices in a Tree (indices 1 .. Max_Vertices).
   Max_Vertices : constant Positive := 2_048;

   --  Maximum number of offline LCA queries (each Add_Query consumes one
   --  slot until Clear).
   Max_Queries : constant Positive := 10_000;

   ---------------------------------------------------------------------------
   -- Vertex identifiers
   ---------------------------------------------------------------------------

   type Vertex_Id is range 1 .. Max_Vertices;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for vertex ids outside 1 .. Vertex_Count, Vertex_Count or
   --  query capacity overflow, incomplete / cyclic tree structure,
   --  Answer / Compute misuse (no Compute yet, bad query index), or
   --  Clear with Root outside 1 .. Vertex_Count when N > 0.

   ---------------------------------------------------------------------------
   -- Rooted tree + offline query batch
   ---------------------------------------------------------------------------

   type Tree is limited private;

   procedure Clear
     (T            : in out Tree;
      Vertex_Count : Natural;
      Root         : Vertex_Id := 1)
     with Global => null;
   --  Reset T to an empty rooted tree on vertices 1 .. Vertex_Count with
   --  the given Root (no parent–child edges, no queries). Vertex_Count
   --  = 0 yields an empty tree (Root ignored). Raises Invalid_Argument
   --  when Vertex_Count > Max_Vertices, or when Vertex_Count > 0 and
   --  Root is outside 1 .. Vertex_Count.

   procedure Set_Parent
     (T : in out Tree; Child, Parent : Vertex_Id)
     with Global => null;
   --  Set Parent_Of(Child) := Parent and append Child to Parent's
   --  children list. Child must not be the tree root and must not
   --  already have a parent. Raises Invalid_Argument when either id is
   --  outside 1 .. Vertex_Count(T), when Child = Root(T), or when Child
   --  already has a parent.

   procedure Add_Child
     (T : in out Tree; Parent, Child : Vertex_Id)
     with Global => null;
   --  Alias of Set_Parent (Child, Parent) — same contract and effect.

   function Vertex_Count (T : Tree) return Natural
     with Global => null;
   --  Number of vertices N; valid vertex ids are 1 .. N (empty ⇒ 0).

   function Root (T : Tree) return Vertex_Id
     with Global => null;
   --  Designated root. Raises Invalid_Argument when Vertex_Count = 0.

   function Parent_Of (T : Tree; V : Vertex_Id) return Natural
     with Global => null;
   --  Parent of V, or 0 when V is the root. Raises Invalid_Argument when
   --  V is outside 1 .. Vertex_Count(T).

   function Query_Count (T : Tree) return Natural
     with Global => null;
   --  Number of offline queries currently stored.

   function Computed (T : Tree) return Boolean
     with Global => null;
   --  True after a successful Compute until the next mutating Clear /
   --  Set_Parent / Add_Child / Add_Query.

   procedure Add_Query (T : in out Tree; U, V : Vertex_Id)
     with Global => null;
   --  Append an offline LCA query for the unordered pair {U, V}
   --  (order of U / V is preserved in storage; Answer returns the same
   --  LCA either way). U = V is allowed (LCA is U). Raises
   --  Invalid_Argument when U or V is outside 1 .. Vertex_Count(T), or
   --  when Query_Count would exceed Max_Queries. Invalidates prior
   --  Compute results.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Tarjan offline LCA)
   ---------------------------------------------------------------------------
   --  Colour every vertex white. DFS from the root:
   --    Make-Set(u); Ancestor(Find(u)) := u.
   --    For each child v of u: recurse on v; Union(u, v);
   --      Ancestor(Find(u)) := u.
   --    Colour u black.
   --    For each query {u, w} with w already black:
   --      Answer := Ancestor(Find(w)).
   --  Amortized O((N + Q) α(N)) with path compression + union-by-rank,
   --  given adjacency-list children and per-vertex query lists.
   --  Contrast (README only): online binary lifting / RMQ on Euler tour
   --  answer queries after preprocessing without requiring the full
   --  query batch up front.

   procedure Compute (T : in out Tree)
     with Global => null;
   --  Run Tarjan's offline LCA on all stored queries. Requires a valid
   --  rooted tree: every non-root vertex has exactly one parent and is
   --  reachable from Root (no cycles, no disconnected vertices). On
   --  success Answers(1 .. Query_Count) are filled and Computed is True.
   --  Empty tree (N = 0) with zero queries succeeds vacuously. Raises
   --  Invalid_Argument when the parent / child structure is incomplete
   --  or cyclic / disconnected.

   function Answer (T : Tree; Query_Index : Positive) return Vertex_Id
     with Global => null;
   --  LCA of the Query_Index-th query (1 .. Query_Count). Requires a
   --  prior successful Compute. Raises Invalid_Argument when not
   --  Computed or when Query_Index is outside 1 .. Query_Count(T).

   ---------------------------------------------------------------------------
   -- Optional naive LCA (in-package; for cross-checks)
   ---------------------------------------------------------------------------
   --  Compute depths by walking to the root, lift the deeper endpoint to
   --  the same depth, then walk both parents in lockstep until they
   --  meet. O(N) per query. Self-contained — no `with` of sibling
   --  packages. Does not require Compute; uses the current parent links.

   function Naive_LCA (T : Tree; U, V : Vertex_Id) return Vertex_Id
     with Global => null;
   --  LCA of U and V by the naive walk. Raises Invalid_Argument when U
   --  or V is outside 1 .. Vertex_Count(T), when N = 0, or when the
   --  parent structure is incomplete / cyclic for the walk (depth walk
   --  exceeds N steps).

private

   --  Union–Find and DFS colouring live in the package body.
   --  Children and per-vertex query incidence are adjacency / linked
   --  lists over fixed educational arrays.

   type Parent_Array is array (1 .. Max_Vertices) of Natural;

   type Query_Record is record
      U, V : Vertex_Id := 1;
   end record;

   type Query_Array  is array (1 .. Max_Queries) of Query_Record;
   type Answer_Array is array (1 .. Max_Queries) of Vertex_Id;

   --  Child edges: Head(P) → first child edge index; Next_Child links
   --  siblings. Child_Of(E) = child vertex at edge E.
   type Child_Of_Array   is array (1 .. Max_Vertices) of Vertex_Id;
   type Next_Child_Array is array (1 .. Max_Vertices) of Natural;
   type Child_Head_Array is array (1 .. Max_Vertices) of Natural;

   --  Query incidence: for each vertex, linked list of query indices
   --  that mention it (so either endpoint can discover the other).
   --  Two slots per query (one at U, one at V) ⇒ 2 * Max_Queries.
   type QInc_Query_Array is array (1 .. 2 * Max_Queries) of Positive;
   type QInc_Next_Array  is array (1 .. 2 * Max_Queries) of Natural;
   type QInc_Head_Array  is array (1 .. Max_Vertices) of Natural;

   type Tree is limited record
      N          : Natural := 0;
      R          : Vertex_Id := 1;
      Parent     : Parent_Array := [others => 0];
      Edge_Count : Natural := 0;  -- parent–child edges (= N-1 when valid)
      Child_Head : Child_Head_Array := [others => 0];
      Child_Of   : Child_Of_Array := [others => 1];
      Next_Child : Next_Child_Array := [others => 0];
      Q          : Natural := 0;
      Queries    : Query_Array;
      Answers    : Answer_Array := [others => 1];
      Done       : Boolean := False;
      QInc_Head  : QInc_Head_Array := [others => 0];
      QInc_Query : QInc_Query_Array := [others => 1];
      QInc_Next  : QInc_Next_Array := [others => 0];
      QInc_Count : Natural := 0;
   end record;

end Tarjans_Off_Line_Lowest_Common_Ancestors;
