pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Binary_Tree_Level_Order; use Binary_Tree_Level_Order;

procedure Tests is
   T : Tree := Empty;
begin
   Set_Node (T, 1, 1, 2, 3); Set_Node (T, 2, 2, 4, 0); Set_Node (T, 3, 3, 0, 0); Set_Node (T, 4, 4, 0, 0);
   if Level_Order_Sum (T, 1) /= 10 or else Level_Order_Sum (T, 0) /= 0 then raise Program_Error; end if;
   Put_Line ("Binary tree level order: PASS");
end Tests;
