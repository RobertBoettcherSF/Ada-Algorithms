with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO;
with Two_Sum_BST_Stub; use Two_Sum_BST_Stub;
procedure Tests is A : constant Input_Array := [2, 7, 11, 15, 1, 4, 9, 20]; begin
   Assert (Has_Two_Sum (A, 9)); Assert (not Has_Two_Sum (A, 100)); Put_Line ("PASS Two_Sum_BST_Stub");
end Tests;
