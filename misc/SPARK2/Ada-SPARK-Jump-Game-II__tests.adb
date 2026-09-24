pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Jump_Game_II; use Jump_Game_II;
procedure Tests is
   A : Steps := [others => 0];
begin
   A (1) := 1;
   Assert (Minimum_Jumps (A, 1) = 0);
   Put_Line ("PASS Ada-SPARK-Jump-Game-II");
end Tests;
