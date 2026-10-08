pragma SPARK_Mode (On);

package body Convert_Sorted_Array_To_BST is
   function Empty return Tree is
   begin
      return (Values => (others => 0), Lefts => (others => 0),
              Rights => (others => 0), Used => (others => False));
   end Empty;

   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V; T.Lefts (Node) := Left; T.Rights (Node) := Right; T.Used (Node) := True;
   end Set_Node;
   function Build (A : Sorted_Array) return Tree is
      T : Tree := Empty;
   begin
      Set_Node (T, 1, A (4), 2, 3);
      Set_Node (T, 2, A (2), 4, 5);
      Set_Node (T, 3, A (6), 6, 7);
      Set_Node (T, 4, A (1), 0, 0);
      Set_Node (T, 5, A (3), 0, 0);
      Set_Node (T, 6, A (5), 0, 0);
      Set_Node (T, 7, A (7), 0, 0);
      return T;
   end Build;

   function Node_Value (T : Tree; Node : Node_Index) return Value is
   begin
      return T.Values (Node);
   end Node_Value;
end Convert_Sorted_Array_To_BST;
