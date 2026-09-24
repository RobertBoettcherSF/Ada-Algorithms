with Ada.Assertions; use Ada.Assertions;
with Dijkstra_Lite; use Dijkstra_Lite;
procedure Tests is
   G : Graph := [others => [others => 0]];
begin
   G (1, 2) := 4; G (2, 3) := 5; G (1, 3) := 12;
   Assert (Shortest_Path (G, 1, 3) = 9);
end Tests;
