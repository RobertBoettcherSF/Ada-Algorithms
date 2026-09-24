pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Redundant_Connection_II_Lite; use Redundant_Connection_II_Lite;
procedure Tests is
   E : Edge_Array := (others => (U => 1, V => 1));
   Answer : Edge_Result;
begin
   E (1) := (1, 2); E (2) := (1, 3); E (3) := (2, 3);
   E (4) := (3, 4); E (5) := (4, 5); E (6) := (5, 6);
   Find_Redundant (E, 6, 6, Answer);
   Assert (Answer = 3);
   Put_Line ("PASS Redundant_Connection_II_Lite");
end Tests;
