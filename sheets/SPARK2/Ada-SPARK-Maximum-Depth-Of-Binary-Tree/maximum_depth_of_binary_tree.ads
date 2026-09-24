pragma SPARK_Mode (On);

package Maximum_Depth_Of_Binary_Tree is
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
   subtype Depth is Natural range 0 .. 16;
   function Max_Depth (T : Tree; Root : Index) return Depth;
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
end Maximum_Depth_Of_Binary_Tree;
