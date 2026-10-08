pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Bellman_Ford_Algorithm; use Bellman_Ford_Algorithm;
procedure Tests is
   E : Edge_Array := (others => (U => 1, V => 1, Weight => 0));
   D : Distance_Array;
begin
   E (1) := (1, 2, 5); E (2) := (2, 3, 7); E (3) := (1, 3, 20);
   Compute (E, 1, D);
   Assert (D (1) = 0 and then D (2) = 5 and then D (3) = 12);
   Put_Line ("PASS Bellman_Ford_Algorithm");
end Tests;
