pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Network_Delay_Time; use Network_Delay_Time;
procedure Tests is
   E : Edge_Array := (others => (U => 1, V => 1, W => 0));
   D : Distance_Array;
begin
   E (1) := (1, 2, 2); E (2) := (1, 3, 5); E (3) := (2, 3, 1);
   E (4) := (3, 4, 3); E (5) := (4, 5, 1); E (6) := (5, 6, 2);
   Compute (E, 1, D);
   Assert (D (1) = 0 and then D (3) = 5 and then D (6) = 1000);
   Put_Line ("PASS Network_Delay_Time");
end Tests;
