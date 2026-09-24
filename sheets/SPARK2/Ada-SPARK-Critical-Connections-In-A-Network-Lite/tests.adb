pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Critical_Connections_In_A_Network_Lite; use Critical_Connections_In_A_Network_Lite;
procedure Tests is
   E : Edge_Array := (others => (U => 1, V => 1));
   Answer : Bridge_Count;
begin
   E (1) := (1, 2); E (2) := (2, 3); E (3) := (3, 1);
   E (4) := (3, 4); E (5) := (4, 5); E (6) := (5, 6);
   Count_Bridges (E, Answer);
   Assert (Answer = 3);
   Put_Line ("PASS Critical_Connections_In_A_Network_Lite");
end Tests;
