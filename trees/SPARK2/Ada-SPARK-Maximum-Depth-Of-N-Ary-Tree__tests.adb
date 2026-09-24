pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Maximum_Depth_Of_N_Ary_Tree; use Maximum_Depth_Of_N_Ary_Tree;

procedure Tests is
   T : Tree := Empty;

begin
   Set_Node (T, 1, 1); Set_Node (T, 2, 2); Set_Node (T, 3, 3); Set_Node (T, 4, 4);
   Set_Child (T, 1, 1, 2); Set_Child (T, 1, 2, 3); Set_Child (T, 2, 1, 4);
   if Maximum_Depth (T, 1) /= 3 or else Maximum_Depth (T, 0) /= 0 then
      raise Program_Error;
   end if;
   Put_Line ("Maximum_Depth_Of_N_Ary_Tree: PASS");
end Tests;
