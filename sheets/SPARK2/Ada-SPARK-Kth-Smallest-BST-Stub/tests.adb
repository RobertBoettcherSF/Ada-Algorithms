pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO; with Kth_Smallest_BST_Stub; use Kth_Smallest_BST_Stub;
procedure Tests is T : Tree := Empty; V : Value; F : Boolean; begin Set_Node (T, 1, 5, 2, 3); Set_Node (T, 2, 3, 4, 0); Set_Node (T, 3, 7, 0, 0); Set_Node (T, 4, 1, 0, 0); Kth_Smallest (T, 1, 2, V, F); if not F or else V /= 3 then raise Program_Error; end if; Put_Line ("k-th smallest BST: PASS"); end Tests;
