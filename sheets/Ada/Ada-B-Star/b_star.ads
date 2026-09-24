--  B_Star — Ada 2023 educational package for Wikipedia "B*".
--  Berliner (1979) best-first proof procedure: nodes carry optimistic /
--  pessimistic intervals; search refines leaf evaluations and backs up
--  bounds until the root interval collapses to a singleton (the minimax
--  value), equivalently until one root child separates from the rest.
--  Primary source: https://en.wikipedia.org/wiki/B*
--  Siblings (README links only — no package deps):
--  Ada-SSS-Star, Ada-Minimax, Ada-Alpha-Beta-Pruning.

pragma Ada_2022;

package B_Star
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity
   ---------------------------------------------------------------------------

   --  Maximum number of nodes in one Game_Tree (educational bound).
   Max_Nodes : constant := 2_000;

   --  Maximum children per internal node.
   Max_Children : constant := 16;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Node_Kind is (Max_Node, Min_Node, Leaf);

   type Node_Index is range 0 .. Max_Nodes;
   --  0 = no node / unset root.
   subtype Valid_Node is Node_Index range 1 .. Max_Nodes;

   subtype Child_Count is Natural range 0 .. Max_Children;
   subtype Child_Slot  is Positive range 1 .. Max_Children;

   type Node_List is array (Positive range <>) of Valid_Node;

   type Game_Tree is private;

   Invalid_Argument : exception;
   --  Raised for empty/malformed trees, capacity overflow, wrong Kind on
   --  Add_Internal, invalid child indices, unset root, or cycles.

   ---------------------------------------------------------------------------
   -- Sentinel bounds (interval endpoints)
   ---------------------------------------------------------------------------

   Pos_Inf : constant Integer := 1_000_000_000;
   Neg_Inf : constant Integer := -1_000_000_000;

   ---------------------------------------------------------------------------
   -- Build API — explicit indexed game tree
   ---------------------------------------------------------------------------

   procedure Clear (G : in out Game_Tree);
   --  Empty the tree; root unset.

   function Add_Leaf
     (G     : in out Game_Tree;
      Value : Integer) return Valid_Node;
   --  Append a terminal with static evaluation Value.
   --  Raises Invalid_Argument when the tree is full.

   function Add_Internal
     (G        : in out Game_Tree;
      Kind     : Node_Kind;
      Children : Node_List) return Valid_Node;
   --  Append a MAX or MIN node with the given children (1 .. Max_Children).
   --  Kind must be Max_Node or Min_Node; Children must be non-empty, already
   --  present in G, and not yet assigned another parent.
   --  Raises Invalid_Argument on violation or capacity overflow.

   procedure Set_Root (G : in out Game_Tree; Root : Valid_Node);
   --  Designate the search root (must already belong to G).

   function Node_Count (G : Game_Tree) return Natural
     with Global => null;

   function Root_Of (G : Game_Tree) return Node_Index
     with Global => null;
   --  0 when unset.

   function Kind_Of (G : Game_Tree; N : Valid_Node) return Node_Kind
     with Global => null;

   function Leaf_Value (G : Game_Tree; N : Valid_Node) return Integer
     with Global => null;
   --  Meaningful only when Kind_Of (G, N) = Leaf.

   function Child_Count_Of (G : Game_Tree; N : Valid_Node) return Child_Count
     with Global => null;

   function Child_Of
     (G : Game_Tree; N : Valid_Node; Slot : Child_Slot) return Node_Index
     with Global => null;
   --  0 when Slot > Child_Count_Of (G, N).

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Evaluate (G : Game_Tree) return Integer;
   --  Educational Berliner B*: best-first bound refinement. Each node holds
   --  an interval [pessimistic, optimistic]. Pending leaves start as
   --  [Neg_Inf, Pos_Inf]; expanding a leaf sets [v, v]. Bounds back up with
   --  max (MAX nodes) / min (MIN nodes). At the root the search applies
   --  prove-best / disprove-rest; below the root it descends by the most
   --  optimistic child for the side to move. Terminates when the root
   --  interval is a singleton — equal to Minimax (G).
   --  Raises Invalid_Argument when the tree is empty, root unset, or
   --  structurally invalid.

   function Minimax (G : Game_Tree) return Integer;
   --  Pure recursive minimax oracle on the same tree (same root value as
   --  Evaluate). Raises Invalid_Argument under the same conditions.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Berliner B* / Wikipedia)
   ---------------------------------------------------------------------------
   --  Intervals. Every node stores [Lo, Hi] supposed to contain the true
   --  game-theoretic value. Unevaluated leaves are [−∞, +∞]; an expanded
   --  leaf with static score v becomes [v, v].
   --
   --  Backup (two-player zero-sum):
   --    MAX parent:  Lo = max_i Lo(c_i),   Hi = max_i Hi(c_i)
   --    MIN parent:  Lo = min_i Lo(c_i),   Hi = min_i Hi(c_i)
   --  (Different children may supply Lo vs Hi.)
   --
   --  Separation (best-move proof). At a MAX root, child B separates when
   --  Lo(B) ≥ Hi(C) for every other root child C — a proof that B is at
   --  least as good as any alternative. This package continues until the
   --  root interval itself collapses (Lo = Hi), which yields the exact
   --  minimax value on finite trees with correct leaf scores.
   --
   --  Expansion (best-first). At the root apply one of two strategies:
   --    prove-best   — select the child with the best optimistic bound
   --                   (MAX: highest Hi; MIN: lowest Lo), hoping to raise
   --                   its pessimistic bound enough to separate.
   --    disprove-rest — select the runner-up optimistic child, hoping to
   --                   worsen its optimistic bound below the leader's Lo.
   --  Disprove-rest is pointless until the prove-best child's pessimistic
   --  bound is already the best among siblings (Wikipedia). Below the root,
   --  descend by repeatedly choosing the most optimistic open child for the
   --  side to move until a pending leaf is reached; assign [v, v] and back up.
   --
   --  Relationship to historical B*. Hans Berliner's 1979 procedure is a
   --  best-first proof search over interval-labelled trees, classically used
   --  to select a move under resource limits. This educational package keeps
   --  the interval backup, prove-best / disprove-rest policy, and separation
   --  idea, specialised to finite explicit game trees with exact leaf values
   --  so Evaluate always matches Minimax. Real engines add heuristic leaf
   --  intervals, transposition graphs, and artificial cutoffs (time/memory).
   --
   --  Do not `with` sibling Ada-* packages.

private

   type Child_Array is array (Child_Slot) of Node_Index;

   type Node_Rec is record
      Kind       : Node_Kind   := Leaf;
      Value      : Integer     := 0;
      N_Children : Child_Count := 0;
      Children   : Child_Array := [others => 0];
      Parent     : Node_Index  := 0;
      Slot       : Child_Count := 0;  -- index among parent's children
   end record;

   type Node_Store is array (Valid_Node) of Node_Rec;

   type Game_Tree is record
      Nodes : Node_Store;
      Count : Natural     := 0;
      Root  : Node_Index  := 0;
   end record;

end B_Star;
