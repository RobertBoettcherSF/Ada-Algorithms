pragma SPARK_Mode (On);

package Insert_Into_A_Binary_Search_Tree is
   subtype Index is Natural range 0 .. 16;
   subtype Node_Index is Index range 1 .. 16;
   subtype Value is Integer range -100 .. 100;
   type Tree is private;
   function Empty return Tree;
   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index);
   procedure Insert (T : in out Tree; Root : in out Index; Node : Node_Index; V : Value);

   --  Read-only view of a node (for tests and contracts).
   function Is_Used (T : Tree; Node : Node_Index) return Boolean;
   function Value_Of (T : Tree; Node : Node_Index) return Value;
   function Left_Of (T : Tree; Node : Node_Index) return Index;
   function Right_Of (T : Tree; Node : Node_Index) return Index;
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

   function Is_Used (T : Tree; Node : Node_Index) return Boolean is (T.Used (Node));
   function Value_Of (T : Tree; Node : Node_Index) return Value is (T.Values (Node));
   function Left_Of (T : Tree; Node : Node_Index) return Index is (T.Lefts (Node));
   function Right_Of (T : Tree; Node : Node_Index) return Index is (T.Rights (Node));
end Insert_Into_A_Binary_Search_Tree;
