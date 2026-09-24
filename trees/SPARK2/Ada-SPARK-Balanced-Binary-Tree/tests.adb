pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO; with Balanced_Binary_Tree; use Balanced_Binary_Tree;
procedure Tests is T : Tree := Empty; U : Tree := Empty; begin Set_Node (T, 1, 1, 2, 3); Set_Node (T, 2, 2, 4, 0); Set_Node (T, 3, 3, 0, 0); Set_Node (T, 4, 4, 0, 0); if not Is_Balanced (T, 1) then raise Program_Error; end if; Set_Node (U, 1, 1, 2, 4); Set_Node (U, 2, 2, 3, 0); Set_Node (U, 3, 3, 5, 0); Set_Node (U, 4, 4, 0, 0); Set_Node (U, 5, 5, 0, 0); if Is_Balanced (U, 1) then raise Program_Error; end if; Put_Line ("balanced tree: PASS"); end Tests;
