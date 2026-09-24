pragma SPARK_Mode (On);

package body Average_Of_Levels_In_Binary_Tree is
   function Empty return Tree is
   begin
      return (Values => (others => 0), Lefts => (others => 0),
              Rights => (others => 0), Used => (others => False));
   end Empty;

   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V; T.Lefts (Node) := Left; T.Rights (Node) := Right; T.Used (Node) := True;
   end Set_Node;
   function Average (T : Tree; L : Level) return Value is
   begin
      if L = 0 then
         if T.Used (1) then return T.Values (1); else return 0; end if;
      elsif L = 1 then
         if T.Used (2) and then T.Used (3) then
            return Value ((Integer (T.Values (2)) + Integer (T.Values (3))) / 2);
         elsif T.Used (2) then
            return T.Values (2);
         elsif T.Used (3) then
            return T.Values (3);
         else
            return 0;
         end if;
      else
         return 0;
      end if;
   end Average;
end Average_Of_Levels_In_Binary_Tree;
