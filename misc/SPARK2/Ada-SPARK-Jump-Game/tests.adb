pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Jump_Game; use Jump_Game;
procedure Tests is
   A : Steps := [others => 0];
begin
   A (1) := 1;
   Assert (Can_Jump (A, 1));
   Put_Line ("PASS Ada-SPARK-Jump-Game");
end Tests;
