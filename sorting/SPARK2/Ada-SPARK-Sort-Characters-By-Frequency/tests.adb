pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Sort_Characters_By_Frequency; use Sort_Characters_By_Frequency;
procedure Tests is
   Input : constant Char_Array := (1 => 'a', 2 => 'b', 3 => 'c', 4 => 'a',
                                   5 => 'b', 6 => 'a', 7 => 'd', 8 => 'a');
   Result : constant Char_Array := Sort_By_Frequency (Input);
begin
   Assert (Result (1) = 'a');
   Assert (Result (2) = 'a');
   Assert (Result (3) = 'a');
   Assert (Result (4) = 'a');
   Put_Line ("PASS Sort_Characters_By_Frequency");
end Tests;
