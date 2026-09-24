pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Connected_Components; use Connected_Components;
procedure Tests is
   E : Edge_Array := (others => (A => 1, B => 1));
begin
   E (1) := (1, 2); E (2) := (2, 3); E (3) := (4, 5);
   Assert (Connected_Components.Count (5, E, 3) = 2);
   Put_Line ("PASS Number Of Connected Components");
end Tests;
