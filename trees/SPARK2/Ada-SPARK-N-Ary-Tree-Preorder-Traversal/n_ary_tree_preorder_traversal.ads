pragma SPARK_Mode (On);

package N_Ary_Tree_Preorder_Traversal is
   subtype Index is Natural range 0 .. 16;
   subtype Node_Index is Index range 1 .. 16;
   subtype Child_Slot is Positive range 1 .. 4;
   subtype Value is Integer range -100 .. 100;
   type Tree is private;
   type Visit_Array is array (Node_Index) of Value;
   type Visit_Result is record
      Values : Visit_Array := (others => 0);
      Length : Natural range 0 .. 16 := 0;
   end record;
   function Empty return Tree;
   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value);
   procedure Set_Child (T : in out Tree; Parent : Node_Index; Slot : Child_Slot; Child : Index);
   function Preorder (T : Tree; Root : Index) return Visit_Result;
private
   type Child_Matrix is array (Index, Child_Slot) of Index;
   type Value_Array is array (Index) of Value;
   type Used_Array is array (Index) of Boolean;
   type Tree is record
      Values : Value_Array := (others => 0);
      Children : Child_Matrix := (others => (others => 0));
      Used : Used_Array := (others => False);
   end record;
end N_Ary_Tree_Preorder_Traversal;
