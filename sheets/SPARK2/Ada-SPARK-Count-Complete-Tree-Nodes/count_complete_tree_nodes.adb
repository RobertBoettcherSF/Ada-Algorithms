pragma SPARK_Mode (On);

package body Count_Complete_Tree_Nodes is
   function Empty return Tree is
   begin
      return (Values => (others => 0), Lefts => (others => 0),
              Rights => (others => 0), Used => (others => False));
   end Empty;

   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V; T.Lefts (Node) := Left; T.Rights (Node) := Right; T.Used (Node) := True;
   end Set_Node;
   function Node_Count (T : Tree) return Natural is
   begin
      if T.Used (16) then return 16;
      elsif T.Used (16) then return 16;
      elsif T.Used (15) then return 15;
      elsif T.Used (14) then return 14;
      elsif T.Used (13) then return 13;
      elsif T.Used (12) then return 12;
      elsif T.Used (11) then return 11;
      elsif T.Used (10) then return 10;
      elsif T.Used (9) then return 9;
      elsif T.Used (8) then return 8;
      elsif T.Used (7) then return 7;
      elsif T.Used (6) then return 6;
      elsif T.Used (5) then return 5;
      elsif T.Used (4) then return 4;
      elsif T.Used (3) then return 3;
      elsif T.Used (2) then return 2;
      elsif T.Used (1) then return 1;
      else return 0;
      end if;
   end Node_Count;
end Count_Complete_Tree_Nodes;
