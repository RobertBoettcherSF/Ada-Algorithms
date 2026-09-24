pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO; with Validate_BST_Stub; use Validate_BST_Stub;
procedure Tests is T : Tree := Empty; begin Set_Node (T, 1, 8, 2, 3); Set_Node (T, 2, 3, 0, 0); Set_Node (T, 3, 10, 0, 0); if not Is_Valid (T, 1) then raise Program_Error; end if; Set_Node (T, 2, 12, 0, 0); if Is_Valid (T, 1) then raise Program_Error; end if; Put_Line ("BST validation: PASS"); end Tests;
