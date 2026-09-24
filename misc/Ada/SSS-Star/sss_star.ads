--  SSS_Star — Ada 2023 educational package for Wikipedia "SSS*".
--  Stockman (1979) best-first state-space search over solution trees of a
--  finite two-player zero-sum game tree. Returns the same root minimax
--  value as pure minimax / alpha–beta on the same explicit tree.
--  Primary source: https://en.wikipedia.org/wiki/SSS*
--  Siblings (README links only — no package deps):
--  Ada-Minimax, Ada-Alpha-Beta-Pruning.

pragma Ada_2022;

package SSS_Star
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
   -- Sentinel merits (OPEN-list upper bounds)
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
   --  Classic Stockman SSS*: best-first search of partial solution trees
   --  with an OPEN priority queue of (node, LIVE|SOLVED, merit) descriptors.
   --  Returns the minimax value of Root_Of (G).
   --  Raises Invalid_Argument when the tree is empty, root unset, or
   --  structurally invalid (e.g. internal node without children).

   function Minimax (G : Game_Tree) return Integer;
   --  Pure recursive minimax oracle on the same tree (same root value as
   --  Evaluate). Raises Invalid_Argument under the same conditions.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Stockman SSS* / Wikipedia Γ operator)
   ---------------------------------------------------------------------------
   --  OPEN holds descriptors (J, s, h), sorted by descending merit h;
   --  equal h prefers the left-most node in the tree.
   --    LIVE   — J unexpanded; h is an upper bound on its true value
   --    SOLVED — h is the true (minimax) value of J
   --
   --  Seed OPEN with (root, LIVE, +∞). Repeatedly pop the head p=(J,s,h):
   --    if J = root and s = SOLVED then return h
   --    else apply Γ(p):
   --      LIVE + leaf     → push (J, SOLVED, min(h, value(J)))
   --      LIVE + MIN      → push (first child, LIVE, h)
   --      LIVE + MAX      → push every child as (child, LIVE, h)
   --      SOLVED + under MAX parent → purge OPEN entries in siblings'
   --                                  subtrees; push (parent, SOLVED, h)
   --      SOLVED + under MIN parent → next sibling LIVE with h, or
   --                                  push (parent, SOLVED, h) if last
   --
   --  A solution tree retains one child at every MAX node and all children
   --  at every MIN node — a complete strategy for MAX. SSS* never expands a
   --  node that alpha–beta would prune, and may prune additional branches.
   --  Plaat et al. showed equivalence to a sequence of null-window
   --  alpha–beta calls with a transposition table (MT-SSS* / MTD family).
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
      Tie        : Natural     := 0;  -- left-to-right preorder (for OPEN)
   end record;

   type Node_Store is array (Valid_Node) of Node_Rec;

   type Game_Tree is record
      Nodes : Node_Store;
      Count : Natural     := 0;
      Root  : Node_Index  := 0;
   end record;

end SSS_Star;
