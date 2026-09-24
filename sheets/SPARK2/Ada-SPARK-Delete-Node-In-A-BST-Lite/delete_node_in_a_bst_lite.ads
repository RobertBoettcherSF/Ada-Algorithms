pragma SPARK_Mode (On);

package Delete_Node_In_A_BST_Lite is
   subtype Index is Natural range 0 .. 16;
   subtype Node_Index is Index range 1 .. 16;
   subtype Value is Integer range -100 .. 100;
   type Tree is private;
   function Empty return Tree;
   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index);
   procedure Delete_Node (T : in out Tree; Root : in out Index; Key : Value);
private
   type Index_Array is array (Index) of Index;
   type Value_Array is array (Index) of Value;
   type Used_Array is array (Index) of Boolean;
   type Tree is record
      Values : Value_Array := (others => 0);
      Lefts : Index_Array := (others => 0);
      Rights : Index_Array := (others => 0);
      Used : Used_Array := (others => False);
   end record;
end Delete_Node_In_A_BST_Lite;
