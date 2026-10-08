pragma SPARK_Mode (On);

package Binary_Tree_Postorder is
   subtype Index is Natural range 0 .. 15;
   subtype Node_Index is Index range 1 .. 15;
   subtype Value is Integer range -100 .. 100;
   type Tree is private;

   function Empty return Tree;
   procedure Set_Node
     (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index);
   function Value_At (T : Tree; Node : Node_Index) return Value;
   function Left_Child (T : Tree; Node : Node_Index) return Index;
   function Right_Child (T : Tree; Node : Node_Index) return Index;
   subtype Sum is Integer range -1500 .. 1500;
   function Postorder_Sum (T : Tree; Root : Index) return Sum;
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
end Binary_Tree_Postorder;
