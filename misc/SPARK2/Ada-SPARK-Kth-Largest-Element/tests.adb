pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Kth_Largest_Element; use Kth_Largest_Element;
procedure Tests is
   Input : constant Input_Array := (1 => 3, 2 => 1, 3 => 8, 4 => 2,
                                    5 => 9, 6 => 4, 7 => 7, 8 => 6);
begin
   Assert (Kth_Largest (Input, 1) = 9);
   Assert (Kth_Largest (Input, 4) = 6);
   Assert (Kth_Largest (Input, 8) = 1);
   Put_Line ("PASS Kth_Largest_Element");
end Tests;
