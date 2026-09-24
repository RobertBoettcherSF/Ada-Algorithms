pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Find_Median_From_Data_Stream; use Find_Median_From_Data_Stream;
procedure Tests is
   Input : constant Input_Array := (1 => 9, 2 => 1, 3 => 7, 4 => 3,
                                    5 => 5, 6 => 0, 7 => 0, 8 => 0);
begin
   Assert (Median (Input, 1) = 9);
   Assert (Median (Input, 5) = 5);
   Assert (Median (Input, 4) = 5);
   Put_Line ("PASS Find_Median_From_Data_Stream");
end Tests;
