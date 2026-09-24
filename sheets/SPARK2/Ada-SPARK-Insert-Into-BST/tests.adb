with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO;
with Insert_Into_BST; use Insert_Into_BST;
procedure Tests is T : Tree := Empty; begin
   Insert (T, 8); Insert (T, 3); Insert (T, 10); Insert (T, 1);
   Assert (Size (T) = 4); Assert (Contains (T, 10)); Assert (not Contains (T, 7));
   Put_Line ("PASS Insert_Into_BST");
end Tests;
