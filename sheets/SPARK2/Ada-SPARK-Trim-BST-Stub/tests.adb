with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Trim_BST_Stub; use Trim_BST_Stub;
procedure Tests is
   T : Tree := Empty;
begin
   Insert (T, 5); Insert (T, 2); Insert (T, 9); Insert (T, 7);
   Trim (T, 3, 8);
   Assert (not Contains (T, 2)); Assert (Contains (T, 5));
   Assert (not Contains (T, 9)); Assert (Contains (T, 7));
   Put_Line ("PASS Trim_BST_Stub");
end Tests;
