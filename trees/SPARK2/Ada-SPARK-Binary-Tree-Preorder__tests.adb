pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Binary_Tree_Preorder; use Binary_Tree_Preorder;

procedure Tests is
   T : Tree := Empty;
begin
   Set_Node (T, 1, 4, 2, 3); Set_Node (T, 2, 2, 0, 0); Set_Node (T, 3, 6, 0, 0);
   if Preorder_Sum (T, 1) /= 12 then raise Program_Error; end if;
   Put_Line ("Binary tree preorder: PASS");
end Tests;
