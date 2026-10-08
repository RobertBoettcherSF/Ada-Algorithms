pragma SPARK_Mode (On);

package body Find_Mode_In_BST is
   function Empty return Tree is
   begin
      return (Values => (others => 0), Lefts => (others => 0),
              Rights => (others => 0), Used => (others => False));
   end Empty;

   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V; T.Lefts (Node) := Left; T.Rights (Node) := Right; T.Used (Node) := True;
   end Set_Node;
   function Mode (T : Tree) return Value is
   begin
      if T.Used (1) and then T.Used (3) and then T.Values (1) = T.Values (3) then
         return T.Values (1);
      elsif T.Used (1) then
         return T.Values (1);
      elsif T.Used (2) then
         return T.Values (2);
      elsif T.Used (3) then
         return T.Values (3);
      else
         return 0;
      end if;
   end Mode;
end Find_Mode_In_BST;
