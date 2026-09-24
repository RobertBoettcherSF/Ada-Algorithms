pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Flood_Fill; use Flood_Fill;
procedure Tests is
   G : Grid := (others => (others => 1));
   Walls : constant Value := 9;
begin
   G (2, 2) := 0;
   G (1, 1) := Walls;
   Fill (G, 2, 2, 2);
   Assert (G (2, 2) = 2 and then G (1, 2) = 1);
   Put_Line ("PASS Flood_Fill");
end Tests;
