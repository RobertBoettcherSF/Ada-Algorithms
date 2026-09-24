with Ada.Text_IO; use Ada.Text_IO;
with Count_Complete_Tree_Nodes;
procedure Tests is
   T : Count_Complete_Tree_Nodes.Tree := Count_Complete_Tree_Nodes.Empty;
begin
   Count_Complete_Tree_Nodes.Set_Node (T, 1, 1, 2, 3);
   Count_Complete_Tree_Nodes.Set_Node (T, 2, 2, 4, 5);
   Count_Complete_Tree_Nodes.Set_Node (T, 3, 3, 6, 0);
   Count_Complete_Tree_Nodes.Set_Node (T, 4, 4, 0, 0);
   Count_Complete_Tree_Nodes.Set_Node (T, 5, 5, 0, 0);
   Count_Complete_Tree_Nodes.Set_Node (T, 6, 6, 0, 0);
   if Count_Complete_Tree_Nodes.Node_Count (T) /= 6 then raise Program_Error; end if;
   Put_Line ("count complete tree nodes: PASS");
end Tests;
