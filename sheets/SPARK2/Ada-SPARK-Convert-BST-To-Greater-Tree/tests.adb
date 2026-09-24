pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Convert_BST_To_Greater_Tree; use Convert_BST_To_Greater_Tree;
procedure Tests is
   Input : constant Tree := (1 => 4, 2 => 1, 3 => 6, 4 => 0, 5 => 3, others => 0);
   Result : constant Greater_Tree := Convert (Input);
begin
   Assert (Result (1) = 14 and then Result (2) = 10 and then Result (3) = 9);
   Assert (Result (4) = 3 and then Result (5) = 3);
   Put_Line ("PASS Convert_BST_To_Greater_Tree");
end Tests;
