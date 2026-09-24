pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Search_In_A_Binary_Search_Tree; use Search_In_A_Binary_Search_Tree;

procedure Tests is
   T : Tree := Empty;
   Root : Index := 1;

begin
   Set_Node (T, 1, 8, 2, 3); Set_Node (T, 2, 4, 0, 4); Set_Node (T, 3, 12, 0, 0); Set_Node (T, 4, 7, 0, 0);
   if Search (T, 1, 7) /= 4 or else Search (T, 1, 99) /= 0 then
      raise Program_Error;
   end if;
   Put_Line ("Search_In_A_Binary_Search_Tree: PASS");
end Tests;
