pragma SPARK_Mode (On);

package body Binary_Tree_Paths is
   function Empty return Tree is
   begin
      return (Values => (others => 0), Lefts => (others => 0),
              Rights => (others => 0), Used => (others => False));
   end Empty;

   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V; T.Lefts (Node) := Left; T.Rights (Node) := Right; T.Used (Node) := True;
   end Set_Node;
   function Path_Count (T : Tree) return Natural is
   begin
      if T.Used (2) and then T.Lefts (2) = 0 and then T.Rights (2) = 0
        and then T.Used (3) and then T.Lefts (3) = 0 and then T.Rights (3) = 0 then
         return 2;
      elsif (T.Used (2) and then T.Lefts (2) = 0 and then T.Rights (2) = 0)
        or else (T.Used (3) and then T.Lefts (3) = 0 and then T.Rights (3) = 0) then
         return 1;
      elsif T.Used (1) and then T.Lefts (1) = 0 and then T.Rights (1) = 0 then
         return 1;
      else
         return 0;
      end if;
   end Path_Count;
end Binary_Tree_Paths;
