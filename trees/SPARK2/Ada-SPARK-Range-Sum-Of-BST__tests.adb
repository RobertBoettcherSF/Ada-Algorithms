pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Range_Sum_Of_BST; use Range_Sum_Of_BST;

procedure Tests is
   T : Tree := Empty;
   Root : Index := 1;

begin
   Set_Node (T, 1, 8, 2, 3); Set_Node (T, 2, 4, 0, 4); Set_Node (T, 3, 12, 0, 0); Set_Node (T, 4, 7, 0, 0);
   if Range_Sum (T, 1, 4, 12) /= 31 or else Range_Sum (T, 0, 0, 100) /= 0 then
      raise Program_Error;
   end if;
   Put_Line ("Range_Sum_Of_BST: PASS");
end Tests;
