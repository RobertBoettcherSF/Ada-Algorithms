pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Path_Sum; use Path_Sum;

procedure Tests is
   T : Tree := Empty;
   U : Tree := Empty;
begin
   Set_Node (T, 1, 5, 2, 3);
   Set_Node (T, 2, 4, 4, 5);
   Set_Node (T, 3, 8, 0, 6);
   Set_Node (T, 4, 11, 0, 0);
   Set_Node (T, 5, 2, 0, 0);
   Set_Node (T, 6, 1, 0, 0);
   if not Has_Path_Sum (T, 1, 20) or else
     Has_Path_Sum (T, 1, 99) then
      raise Program_Error;
   end if;
   Put_Line ("Path Sum: PASS");
end Tests;
