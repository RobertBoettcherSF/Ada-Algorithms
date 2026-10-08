with Ada.Text_IO; use Ada.Text_IO;
with Average_Of_Levels_In_Binary_Tree;
procedure Tests is
   T : Average_Of_Levels_In_Binary_Tree.Tree := Average_Of_Levels_In_Binary_Tree.Empty;
begin
   Average_Of_Levels_In_Binary_Tree.Set_Node (T, 1, 3, 2, 3);
   Average_Of_Levels_In_Binary_Tree.Set_Node (T, 2, 9, 0, 0);
   Average_Of_Levels_In_Binary_Tree.Set_Node (T, 3, 20, 0, 0);
   if Average_Of_Levels_In_Binary_Tree.Average (T, 1) /= 14 then raise Program_Error; end if;
   Put_Line ("average of levels: PASS");
end Tests;
