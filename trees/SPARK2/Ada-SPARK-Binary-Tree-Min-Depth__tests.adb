pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Binary_Tree_Min_Depth; use Binary_Tree_Min_Depth;

procedure Tests is
   T : Tree := Empty;
   U : Tree := Empty;
begin
   Set_Node (T, 1, 1, 2, 3);
   Set_Node (T, 2, 2, 4, 0);
   Set_Node (T, 3, 3, 0, 0);
   Set_Node (T, 4, 4, 0, 0);
   if Min_Depth (T, 1) /= 2 or else Min_Depth (T, 0) /= 0 then
      raise Program_Error;
   end if;
   Put_Line ("Binary Tree Min Depth: PASS");
end Tests;
