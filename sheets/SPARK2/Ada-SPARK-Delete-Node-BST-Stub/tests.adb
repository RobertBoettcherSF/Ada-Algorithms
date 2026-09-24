with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO;
with Delete_Node_BST_Stub; use Delete_Node_BST_Stub;
procedure Tests is T : Tree := Empty; begin
   Insert (T, 8); Insert (T, 3); Insert (T, 10); Delete (T, 3);
   Assert (Contains (T, 8)); Assert (not Contains (T, 3)); Assert (Contains (T, 10));
   Put_Line ("PASS Delete_Node_BST_Stub");
end Tests;
