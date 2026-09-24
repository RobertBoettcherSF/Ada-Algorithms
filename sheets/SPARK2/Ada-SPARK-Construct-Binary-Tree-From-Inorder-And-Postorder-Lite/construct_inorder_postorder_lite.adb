pragma SPARK_Mode (On);

package body Construct_Inorder_Postorder_Lite is
   function Empty return Tree is
   begin
      return (Values => (others => 0), Lefts => (others => 0),
              Rights => (others => 0), Used => (others => False));
   end Empty;

   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V; T.Lefts (Node) := Left; T.Rights (Node) := Right; T.Used (Node) := True;
   end Set_Node;
   function Build (Inorder, Postorder : Traversal_Array) return Tree is
      T : Tree := Empty;
   begin
      Set_Node (T, 1, Postorder (3), 2, 3);
      if Inorder (1) = Postorder (1) then
         Set_Node (T, 2, Postorder (1), 0, 0);
         Set_Node (T, 3, Postorder (2), 0, 0);
      else
         Set_Node (T, 2, Postorder (2), 0, 0);
         Set_Node (T, 3, Postorder (1), 0, 0);
      end if;
      return T;
   end Build;

   function Node_Value (T : Tree; Node : Node_Index) return Value is
   begin return T.Values (Node); end Node_Value;

   function Left_Child (T : Tree; Node : Node_Index) return Index is
   begin return T.Lefts (Node); end Left_Child;

   function Right_Child (T : Tree; Node : Node_Index) return Index is
   begin return T.Rights (Node); end Right_Child;
end Construct_Inorder_Postorder_Lite;
