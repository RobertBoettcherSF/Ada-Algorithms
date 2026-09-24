pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Binary_Tree_Postorder; use Binary_Tree_Postorder;
procedure Tests is
   T : Tree := Empty;
begin
   Set_Node (T, 1, 1, 2, 3); Set_Node (T, 2, 2, 0, 0); Set_Node (T, 3, 3, 0, 0);
   if Postorder_Sum (T, 1) /= 6 or else Postorder_Sum (T, 0) /= 0 then raise Program_Error; end if;
   Put_Line ("Binary tree postorder: PASS");
end Tests;
