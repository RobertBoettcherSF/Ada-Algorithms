pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Sum_Of_Left_Leaves; use Sum_Of_Left_Leaves;
procedure Tests is
   T : Tree := Empty;
begin
   Set_Node (T, 1, 10, 2, 3); Set_Node (T, 2, 4, 4, 0); Set_Node (T, 3, 8, 0, 0);
   Set_Node (T, 4, 6, 0, 0);
   if Sum_Left_Leaves (T, 1) /= 6 then raise Program_Error; end if;
   Put_Line ("Sum of left leaves: PASS");
end Tests;
