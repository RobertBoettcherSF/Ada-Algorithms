pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Delete_Node_In_A_BST_Lite; use Delete_Node_In_A_BST_Lite;

procedure Tests is
   T : Tree := Empty;
   Root : Index := 1;

begin
   Set_Node (T, 1, 8, 2, 3); Set_Node (T, 2, 4, 0, 4); Set_Node (T, 3, 12, 0, 0); Set_Node (T, 4, 7, 0, 0);
   Delete_Node (T, Root, 4);
   if Root /= 1 then
      raise Program_Error;
   end if;
   Delete_Node (T, Root, 8);
   if Root /= 0 then
      raise Program_Error;
   end if;
   Put_Line ("Delete_Node_In_A_BST_Lite: PASS");
end Tests;
