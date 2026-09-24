pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Binary_Tree_Right_Side_View; use Binary_Tree_Right_Side_View;
procedure Tests is
   Input : constant Tree := (1 => 10, 3 => 12, 7 => 14, 15 => 16, others => 0);
   Result : constant View := Right_View (Input);
begin
   Assert (Result = (1 => 10, 2 => 12, 3 => 14, 4 => 16));
   Put_Line ("PASS Binary_Tree_Right_Side_View");
end Tests;
