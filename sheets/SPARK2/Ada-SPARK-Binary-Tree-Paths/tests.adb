with Ada.Text_IO; use Ada.Text_IO;
with Binary_Tree_Paths;
procedure Tests is
   T : Binary_Tree_Paths.Tree := Binary_Tree_Paths.Empty;
begin
   Binary_Tree_Paths.Set_Node (T, 1, 1, 2, 3);
   Binary_Tree_Paths.Set_Node (T, 2, 2, 0, 0);
   Binary_Tree_Paths.Set_Node (T, 3, 3, 0, 0);
   if Binary_Tree_Paths.Path_Count (T) /= 2 then raise Program_Error; end if;
   Put_Line ("binary tree paths: PASS");
end Tests;
