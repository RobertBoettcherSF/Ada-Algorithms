with Ada.Text_IO; use Ada.Text_IO;
with Find_Mode_In_BST;
procedure Tests is
   T : Find_Mode_In_BST.Tree := Find_Mode_In_BST.Empty;
begin
   Find_Mode_In_BST.Set_Node (T, 1, 2, 2, 3);
   Find_Mode_In_BST.Set_Node (T, 2, 1, 0, 0);
   Find_Mode_In_BST.Set_Node (T, 3, 2, 0, 0);
   if Find_Mode_In_BST.Mode (T) /= 2 then raise Program_Error; end if;
   Put_Line ("find mode in BST: PASS");
end Tests;
