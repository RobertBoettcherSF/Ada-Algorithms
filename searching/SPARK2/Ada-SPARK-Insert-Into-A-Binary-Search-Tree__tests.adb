pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Insert_Into_A_Binary_Search_Tree; use Insert_Into_A_Binary_Search_Tree;

procedure Tests is
   T : Tree := Empty;
   Root : Index := 1;

begin
   Insert (T, Root, 1, 8); Insert (T, Root, 2, 4); Insert (T, Root, 3, 12);
   if Root /= 1 then
      raise Program_Error;
   end if;
   Put_Line ("Insert_Into_A_Binary_Search_Tree: PASS");
end Tests;
