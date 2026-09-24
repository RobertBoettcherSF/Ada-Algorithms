pragma SPARK_Mode (On);

package BST_Insert_Search is
   subtype Index is Natural range 0 .. 31;
   subtype Node_Index is Index range 1 .. 31;
   subtype Value is Integer range -1000 .. 1000;
   type Tree is private;
   function Empty return Tree;
   procedure Insert (T : in out Tree; V : Value);
   function Contains (T : Tree; V : Value) return Boolean;
private
   type Child_Array is array (Index) of Index;
   type Value_Array is array (Index) of Value;
   type Used_Array is array (Index) of Boolean;
   type Tree is record Values : Value_Array; Lefts, Rights : Child_Array; Used : Used_Array; end record;
end BST_Insert_Search;
