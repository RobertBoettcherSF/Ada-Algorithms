pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Trim_Binary_Search_Tree; use Trim_Binary_Search_Tree;
procedure Tests is
   Input : constant Tree := (1 => -4, 2 => 2, 3 => 9, 4 => 15, others => 5);
   Result : constant Tree := Trim (Input, 0, 10);
begin
   Assert (Result (1) = 0 and then Result (2) = 2 and then Result (3) = 9 and then Result (4) = 10);
   Put_Line ("PASS Trim_Binary_Search_Tree");
end Tests;
