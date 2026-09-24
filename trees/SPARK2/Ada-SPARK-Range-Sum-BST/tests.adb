pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO; with Range_Sum_BST; use Range_Sum_BST;
procedure Tests is T : Tree := Empty; begin Set_Node (T, 1, 8, 2, 3); Set_Node (T, 2, 3, 0, 0); Set_Node (T, 3, 10, 0, 0); if Range_Sum (T, 1, 4, 9) /= 8 then raise Program_Error; end if; Put_Line ("BST range sum: PASS"); end Tests;
