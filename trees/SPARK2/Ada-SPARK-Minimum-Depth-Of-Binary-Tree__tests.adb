pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Minimum_Depth_Of_Binary_Tree; use Minimum_Depth_Of_Binary_Tree;
procedure Tests is
   T : Tree := Empty;
begin
   Set_Node (T, 1, 1, 2, 3); Set_Node (T, 2, 2, 4, 0); Set_Node (T, 3, 3, 0, 0);
   Set_Node (T, 4, 4, 0, 0);
   if Min_Depth (T, 1) /= 2 or else Min_Depth (T, 0) /= 0 then raise Program_Error; end if;
   Put_Line ("Minimum depth: PASS");
end Tests;
