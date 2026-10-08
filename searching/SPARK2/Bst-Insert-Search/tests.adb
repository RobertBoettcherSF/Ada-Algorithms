pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with BST_Insert_Search; use BST_Insert_Search;
procedure Tests is T : Tree := Empty; begin Insert (T, 8); Insert (T, 3); Insert (T, 10); Insert (T, 6); if not Contains (T, 6) or else Contains (T, 4) then raise Program_Error; end if; Put_Line ("BST insert/search: PASS"); end Tests;
