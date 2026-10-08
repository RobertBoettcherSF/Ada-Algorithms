pragma SPARK_Mode (On);

package Range_Sum_BST is
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
   function Range_Sum (T : Tree; Root : Index; Low, High : Value) return Sum;
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

end Range_Sum_BST;
