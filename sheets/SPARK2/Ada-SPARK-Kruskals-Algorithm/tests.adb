pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Kruskals_Algorithm; use Kruskals_Algorithm;
procedure Tests is
   E : Edge_Array := (others => (U => 1, V => 1, Weight => 0));
   C : Edge_Array; N : Edge_Count; T : Natural;
begin
   E (1) := (1, 2, 1); E (2) := (2, 3, 2); E (3) := (1, 3, 9);
   E (4) := (3, 4, 3);
   Compute (E, C, N, T);
   Assert (N = 3 and then T = 6);
   Put_Line ("PASS Kruskals_Algorithm");
end Tests;
