pragma SPARK_Mode (On);

package Maximum_Binary_Tree is
   subtype Index is Natural range 0 .. 16;
   subtype Node_Index is Index range 1 .. 16;
   subtype Value is Integer range -1000 .. 1000;
   subtype Count is Natural range 0 .. 16;
   type Tree is private;

   function Empty return Tree;
   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index);
   type Input_Array is array (Positive range 1 .. 7) of Value;
   function Build (A : Input_Array) return Tree;
   function Node_Value (T : Tree; Node : Node_Index) return Value;
private
   type Child_Array is array (Index) of Index;
   type Value_Array is array (Index) of Value;
   type Used_Array is array (Index) of Boolean;
   type Tree is record
      Values : Value_Array;
      Lefts : Child_Array;
      Rights : Child_Array;
      Used : Used_Array;
   end record;
end Maximum_Binary_Tree;
