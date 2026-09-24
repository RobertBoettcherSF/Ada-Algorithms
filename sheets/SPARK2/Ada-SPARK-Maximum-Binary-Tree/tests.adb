with Ada.Text_IO; use Ada.Text_IO;
with Maximum_Binary_Tree;
procedure Tests is
   A : Maximum_Binary_Tree.Input_Array := (3, 2, 1, 6, 0, 5, 4);
   T : Maximum_Binary_Tree.Tree := Maximum_Binary_Tree.Build (A);
begin
   if Maximum_Binary_Tree.Node_Value (T, 1) /= 6 then raise Program_Error; end if;
   Put_Line ("maximum binary tree: PASS");
end Tests;
