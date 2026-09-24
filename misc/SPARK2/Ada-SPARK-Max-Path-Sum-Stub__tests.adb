pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO; with Max_Path_Sum_Stub; use Max_Path_Sum_Stub;
procedure Tests is T : Tree := Empty; begin Set_Node (T, 1, 5, 2, 3); Set_Node (T, 2, 4, 0, 0); Set_Node (T, 3, 8, 4, 0); Set_Node (T, 4, 2, 0, 0); if Max_Path_Sum (T, 1) /= 15 then raise Program_Error; end if; Put_Line ("maximum path sum: PASS"); end Tests;
