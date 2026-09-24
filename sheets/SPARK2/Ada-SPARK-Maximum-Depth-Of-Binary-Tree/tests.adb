pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Maximum_Depth_Of_Binary_Tree; use Maximum_Depth_Of_Binary_Tree;
procedure Tests is
   T : Tree := Empty;
begin
   Set_Node (T, 1, 1, 2, 3); Set_Node (T, 2, 2, 4, 5);
   Set_Node (T, 3, 3, 0, 6); Set_Node (T, 4, 4, 0, 0);
   Set_Node (T, 5, 5, 0, 0); Set_Node (T, 6, 6, 0, 0);
   if Max_Depth (T, 1) /= 3 or else Max_Depth (T, 0) /= 0 then raise Program_Error; end if;
   Put_Line ("Maximum depth: PASS");
end Tests;
