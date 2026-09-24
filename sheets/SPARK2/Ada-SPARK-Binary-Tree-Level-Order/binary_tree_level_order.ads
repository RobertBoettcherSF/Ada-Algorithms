pragma SPARK_Mode (On);

package Binary_Tree_Level_Order is
   subtype Index is Natural range 0 .. 15;
   subtype Node_Index is Index range 1 .. 15;
   subtype Value is Integer range -100 .. 100;
   type Tree is private;
   function Empty return Tree;
   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index);
   function Level_Order_Sum (T : Tree; Root : Index) return Long_Long_Integer;
private
   type Child_Array is array (Index) of Index;
   type Value_Array is array (Index) of Value;
   type Used_Array is array (Index) of Boolean;
   type Tree is record
      Values : Value_Array := (others => 0);
      Lefts : Child_Array := (others => 0);
      Rights : Child_Array := (others => 0);
      Used : Used_Array := (others => False);
   end record;
end Binary_Tree_Level_Order;
