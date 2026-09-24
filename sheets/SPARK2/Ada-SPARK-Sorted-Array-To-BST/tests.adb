pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO; with Sorted_Array_To_BST; use Sorted_Array_To_BST;
procedure Tests is T : Tree := Empty; A : Value_Array := (1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6, 7 => 7, others => 0); begin Build (T, A, 7); if Root_Value (T) /= 4 or else not Is_BST (T) then raise Program_Error; end if; Put_Line ("sorted array to BST: PASS"); end Tests;
