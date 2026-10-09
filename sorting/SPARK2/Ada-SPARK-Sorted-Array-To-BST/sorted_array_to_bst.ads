pragma Ada_2022;
pragma SPARK_Mode (On);

package Sorted_Array_To_BST is
   subtype Index is Natural range 0 .. 31;
   subtype Node_Index is Index range 1 .. 31;
   subtype Value is Integer range -1000 .. 1000;
   subtype Count is Natural range 0 .. 31;
   subtype Height_Type is Natural range 0 .. 5;
   type Value_Array is array (Index) of Value;

   --  Nodes are stored by heap position: the root is node 1 and the
   --  children of node N are nodes 2 * N and 2 * N + 1.
   type Tree is private;

   function Empty return Tree;

   --  Input (1 .. Length) becomes the in-order sequence of a height-balanced
   --  tree: each subrange First .. Last puts Input (First + (Last - First) / 2)
   --  at its root. Input (0) and Input (Length + 1 ..) are not used. Input is
   --  not required to be sorted; Is_BST reports whether the result is a
   --  binary search tree.
   procedure Build (T : out Tree; Input : Value_Array; Length : Count);

   --  Value of node 1; 0 for an empty tree.
   function Root_Value (T : Tree) return Value;

   --  True when every node's value is greater than every value in its left
   --  subtree and less than every value in its right subtree (so equal
   --  values make it False). An empty tree is a BST.
   function Is_BST (T : Tree) return Boolean;

   --  Number of nodes on the longest path from the root; 0 when empty.
   function Height (T : Tree) return Height_Type;

   --  Binary-search descent from the root, comparing V with each node.
   function Contains (T : Tree; V : Value) return Boolean;
private
   type Stored_Array is array (Index) of Value;
   type Used_Array is array (Index) of Boolean;
   type Tree is record
      Values : Stored_Array;
      Used   : Used_Array;
   end record;
end Sorted_Array_To_BST;
