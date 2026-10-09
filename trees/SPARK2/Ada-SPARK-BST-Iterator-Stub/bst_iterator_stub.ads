pragma SPARK_Mode (On);
pragma Ada_2022;
package BST_Iterator_Stub is
   Capacity : constant := 1_000;
   subtype Count is Natural range 0 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   type Tree is private;
   type Iterator is private;

   function Empty return Tree with Global => null, Post => Size (Empty'Result) = 0;
   --  Binary search tree insertion: smaller values go left, equal and
   --  larger values go right.
   procedure Insert (T : in out Tree; V : Value)
     with Global => null, Pre => Size (T) < Capacity, Post => Size (T) = Size (T'Old) + 1;
   function Size (T : Tree) return Count with Global => null;

   --  In-order iterator: the values of T in ascending order.
   function Create (T : Tree) return Iterator
     with Global => null, Post => Has_Next (Create'Result) = (Size (T) > 0);
   function Has_Next (It : Iterator) return Boolean with Global => null;
   procedure Next (It : in out Iterator; Result : out Value) with Global => null, Pre => Has_Next (It);
private
   --  Nodes are numbered in insertion order, so a child always has a larger
   --  number than its parent: walks down increase the node number and walks
   --  up decrease it, which bounds every loop.
   subtype Node_Ref is Natural range 0 .. Capacity;   --  0 = none
   subtype Node is Node_Ref range 1 .. Capacity;
   type Node_Rec is record
      Val                 : Value := 0;
      Left, Right, Parent : Node_Ref := 0;
   end record;
   type Node_Array is array (Node) of Node_Rec;
   type Tree is record
      Nodes : Node_Array;
      Size  : Count := 0;
   end record
     with Type_Invariant => Valid (Tree);
   --  Every child has a larger number than its parent and points back to
   --  it; node 1 is the root.
   function Valid (T : Tree) return Boolean is
     (for all I in 1 .. T.Size =>
        (T.Nodes (I).Left = 0 or else
           (T.Nodes (I).Left in I + 1 .. T.Size and then T.Nodes (T.Nodes (I).Left).Parent = I))
        and then (T.Nodes (I).Right = 0 or else
           (T.Nodes (I).Right in I + 1 .. T.Size and then T.Nodes (T.Nodes (I).Right).Parent = I))
        and then (if I = 1 then T.Nodes (I).Parent = 0 else T.Nodes (I).Parent in 1 .. I - 1));
   type Iterator is record
      T       : Tree;
      Current : Node_Ref := 0;   --  next node to return, 0 when done
   end record
     with Type_Invariant => Current <= T.Size;
end BST_Iterator_Stub;
