pragma Ada_2022;
pragma SPARK_Mode (On);

package Path_Sum is
   subtype Index is Natural range 0 .. 15;
   subtype Node_Index is Index range 1 .. 15;
   subtype Value is Integer range -100 .. 100;
   subtype Depth is Natural range 0 .. 16;

   type Tree is private;

   function Empty return Tree;

   --  Some node other than Node links to Child.
   function Has_Other_Parent (T : Tree; Child, Node : Node_Index) return Boolean;

   --  Walking up the parent links from Node reaches A (A = Node counts).
   function Is_Ancestor_Or_Self (T : Tree; A, Node : Node_Index) return Boolean;

   --  The links always form a forest: a new child must not already have
   --  another parent and must not be Node or one of its ancestors, and the
   --  two children differ. So a cycle or a shared child cannot be built.
   procedure Set_Node
     (T : in out Tree;
      Node : Node_Index;
      V : Value;
      Left, Right : Index)
   with Pre =>
     (Left = 0
      or else (not Has_Other_Parent (T, Left, Node)
               and then not Is_Ancestor_Or_Self (T, Left, Node)))
     and then
     (Right = 0
      or else (not Has_Other_Parent (T, Right, Node)
               and then not Is_Ancestor_Or_Self (T, Right, Node)))
     and then (Left = 0 or else Left /= Right);
   function Left_Child (T : Tree; Node : Node_Index) return Index;
   function Right_Child (T : Tree; Node : Node_Index) return Index;

   subtype Target is Integer range -1000 .. 1000;
   function Has_Path_Sum (T : Tree; Root : Index; Wanted : Target) return Boolean;
private
   type Child_Array is array (Index) of Index;
   type Value_Array is array (Index) of Value;
   type Used_Array is array (Index) of Boolean;
   type Tree is record
      Values : Value_Array := [others => 0];
      Lefts  : Child_Array := [others => 0];
      Rights : Child_Array := [others => 0];
      Used   : Used_Array := [others => False];
   end record;
end Path_Sum;
