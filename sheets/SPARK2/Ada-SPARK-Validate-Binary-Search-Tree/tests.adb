pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Validate_Binary_Search_Tree; use Validate_Binary_Search_Tree;
procedure Tests is
   T : Tree := Empty; U : Tree := Empty;
begin
   Set_Node (T, 1, 5, 2, 3); Set_Node (T, 2, 3, 0, 0); Set_Node (T, 3, 7, 0, 0);
   Set_Node (U, 1, 5, 2, 3); Set_Node (U, 2, 8, 0, 0); Set_Node (U, 3, 7, 0, 0);
   if not Is_Valid_BST (T, 1) or else Is_Valid_BST (U, 1) then raise Program_Error; end if;
   Put_Line ("Validate BST: PASS");
end Tests;
