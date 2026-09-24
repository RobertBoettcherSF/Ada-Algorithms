pragma SPARK_Mode (On);

package body Maximum_Binary_Tree is
   function Empty return Tree is
   begin
      return (Values => (others => 0), Lefts => (others => 0),
              Rights => (others => 0), Used => (others => False));
   end Empty;

   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V; T.Lefts (Node) := Left; T.Rights (Node) := Right; T.Used (Node) := True;
   end Set_Node;
   function Build (A : Input_Array) return Tree is
      T : Tree := Empty;
      M : Value := A (1);
   begin
      for I in 2 .. 7 loop
         if A (I) > M then M := A (I); end if;
      end loop;
      Set_Node (T, 1, M, 0, 0);
      return T;
   end Build;

   function Node_Value (T : Tree; Node : Node_Index) return Value is
   begin return T.Values (Node); end Node_Value;
end Maximum_Binary_Tree;
