pragma Ada_2022;
pragma SPARK_Mode (On);

package Balanced_Binary_Tree is
   subtype Index is Natural range 0 .. 31;
   subtype Node_Index is Index range 1 .. 31;
   subtype Value is Integer range -1000 .. 1000;
   subtype Sum is Integer range -31000 .. 31000;

   --  A Tree can only hold a forest: every node has at most one link into it (no node is the child of
   --  two nodes, or the left and right child of one node). Set_Node refuses a link that would break
   --  this, so a shared child cannot be built (type invariant in the private part). A cycle can still
   --  be linked; Is_Balanced rejects it by depth.
   type Tree is private;

   function Empty return Tree;

   --  Node may get these children: Left and Right differ (unless 0) and no other node links to them.
   --  Node's own old links do not count, so a node can be set again.
   function Can_Link (T : Tree; Node : Node_Index; Left, Right : Index) return Boolean;

   procedure Set_Node
     (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index)
     with Pre => Can_Link (T, Node, Left, Right);
   function Node_Value (T : Tree; Node : Node_Index) return Value;
   function Left_Child (T : Tree; Node : Node_Index) return Index;
   function Right_Child (T : Tree; Node : Node_Index) return Index;
   --  Specification (ghost): the tree hanging from N, with N at depth D (the root is at depth 1). A tree of
   --  at most 31 nodes is at most 31 deep, so a node deeper than 31 means a cycle: not a tree, not balanced.
   function Spec_Height (T : Tree; N : Index; D : Positive) return Natural
     with Ghost, Pre => D <= 32, Post => Spec_Height'Result <= 32 - D + 1,
          Subprogram_Variant => (Decreases => 32 - D);
   function Spec_Balanced (T : Tree; N : Index; D : Positive) return Boolean
     with Ghost, Pre => D <= 32, Subprogram_Variant => (Decreases => 32 - D);

   --  True when the tree at Root is a tree (no cycle) and at every node the two subtree heights differ
   --  by at most 1. Child index 0 = no child; Root = 0 or an unset Root slot = the empty tree.
   function Is_Balanced (T : Tree; Root : Index) return Boolean
     with Post => Is_Balanced'Result = (Root = 0 or else not Used (T, Root) or else Spec_Balanced (T, Root, 1));
   function Used (T : Tree; Node : Node_Index) return Boolean;
private
   type Child_Array is array (Index) of Index;
   type Value_Array is array (Index) of Value;
   type Used_Array is array (Index) of Boolean;
   --  No node has two links into it: for every node P, its left and right children differ (unless 0),
   --  and no other node Q has P's left or right child as a child.
   function No_Shared_Child (L, R : Child_Array) return Boolean is
     (for all P in Node_Index =>
        (L (P) = 0 or else L (P) /= R (P))
        and then
        (for all Q in Node_Index =>
           (if Q /= P then
              (L (P) = 0 or else (L (P) /= L (Q) and then L (P) /= R (Q)))
              and then (R (P) = 0 or else (R (P) /= L (Q) and then R (P) /= R (Q))))));

   type Tree is record
      Values : Value_Array := [others => 0];
      Lefts  : Child_Array := [others => 0];
      Rights : Child_Array := [others => 0];
      Used   : Used_Array  := [others => False];
   end record
     with Type_Invariant => No_Shared_Child (Tree.Lefts, Tree.Rights);

   function Can_Link (T : Tree; Node : Node_Index; Left, Right : Index) return Boolean is
     ((Left = 0 or else Left /= Right)
      and then
      (for all Q in Node_Index =>
         (if Q /= Node then
            (Left = 0 or else (T.Lefts (Q) /= Left and then T.Rights (Q) /= Left))
            and then (Right = 0 or else (T.Lefts (Q) /= Right and then T.Rights (Q) /= Right)))));

   function Used (T : Tree; Node : Node_Index) return Boolean is (T.Used (Node));
   function Spec_Height (T : Tree; N : Index; D : Positive) return Natural is
     (if N = 0 or else D = 32 then 0
      else 1 + Natural'Max (Spec_Height (T, T.Lefts (N), D + 1), Spec_Height (T, T.Rights (N), D + 1)));
   function Spec_Balanced (T : Tree; N : Index; D : Positive) return Boolean is
     (N = 0
      or else (D <= 31
               and then Spec_Balanced (T, T.Lefts (N), D + 1) and then Spec_Balanced (T, T.Rights (N), D + 1)
               and then abs (Spec_Height (T, T.Lefts (N), D + 1) - Spec_Height (T, T.Rights (N), D + 1)) <= 1));
end Balanced_Binary_Tree;
