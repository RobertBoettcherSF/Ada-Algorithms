pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Swim_In_Rising_Water; use Swim_In_Rising_Water;
procedure Tests is
   G : Elevation_Array := (0, 2, 1, 3, 9, 8, 2, 4, 5, 6, 7, 8, 6, 5, 4, 3);
   Answer : Elevation;
begin
   Compute (G, Answer);
   Assert (Answer = 9);
   Put_Line ("PASS Swim_In_Rising_Water");
end Tests;
