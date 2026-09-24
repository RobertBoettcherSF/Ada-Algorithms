pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Flatten_Binary_Tree_To_Linked_List_Lite; use Flatten_Binary_Tree_To_Linked_List_Lite;
procedure Tests is
   Input : constant Tree := (1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5,
                             6 => 6, 7 => 7, 8 => 8, 9 => 9, 10 => 10,
                             11 => 11, 12 => 12, 13 => 13, 14 => 14, 15 => 15);
   Result : constant Tree := Flatten (Input);
begin
   Assert (Result (1) = 1 and then Result (2) = 2 and then Result (3) = 4);
   Assert (Result (4) = 8 and then Result (5) = 9 and then Result (9) = 3);
   Put_Line ("PASS Flatten_Binary_Tree_To_Linked_List_Lite");
end Tests;
