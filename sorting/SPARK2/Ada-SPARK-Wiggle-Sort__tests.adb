pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Wiggle_Sort; use Wiggle_Sort;
procedure Tests is
   Input : constant Input_Array := (1 => 3, 2 => 5, 3 => 2, 4 => 1,
                                    5 => 6, 6 => 4, 7 => 8, 8 => 7);
   Result : constant Input_Array := Wiggle (Input);
begin
   Assert (Result (1) <= Result (2));
   Assert (Result (2) >= Result (3));
   Assert (Result (3) <= Result (4));
   Assert (Result (4) >= Result (5));
   Put_Line ("PASS Wiggle_Sort");
end Tests;
