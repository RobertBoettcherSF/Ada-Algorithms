pragma SPARK_Mode (On);

package Balanced_Binary_Tree is
   subtype Index is Natural range 0 .. 31;
   subtype Node_Index is Index range 1 .. 31;
   subtype Value is Integer range -1000 .. 1000;
   subtype Sum is Integer range -31000 .. 31000;

   type Tree is private;

   function Empty return Tree;
   procedure Set_Node
     (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index);
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
   type Tree is record
      Values : Value_Array;
      Lefts  : Child_Array;
      Rights : Child_Array;
      Used   : Used_Array;
   end record;

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
