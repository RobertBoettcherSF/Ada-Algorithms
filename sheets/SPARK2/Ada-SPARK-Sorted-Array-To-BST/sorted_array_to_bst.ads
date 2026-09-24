pragma SPARK_Mode (On);

package Sorted_Array_To_BST is
   subtype Index is Natural range 0 .. 31;
   subtype Node_Index is Index range 1 .. 31;
   subtype Value is Integer range -1000 .. 1000;
   subtype Count is Natural range 0 .. 31;
   type Value_Array is array (Index) of Value;
   type Tree is private;
   function Empty return Tree;
   procedure Build (T : out Tree; Input : Value_Array; Length : Count);
   function Root_Value (T : Tree) return Value;
   function Is_BST (T : Tree) return Boolean;
private
   type Child_Array is array (Index) of Index;
   type Stored_Array is array (Index) of Value;
   type Used_Array is array (Index) of Boolean;
   type Tree is record Values : Stored_Array; Lefts, Rights : Child_Array; Used : Used_Array; end record;
end Sorted_Array_To_BST;
