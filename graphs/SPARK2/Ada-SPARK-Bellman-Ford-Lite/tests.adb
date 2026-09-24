with Ada.Assertions; use Ada.Assertions;
with Bellman_Ford_Lite; use Bellman_Ford_Lite;
procedure Tests is
   G : Graph := [others => [others => 0]];
begin
   G (1, 2) := 3; G (2, 3) := 4; G (1, 3) := 10;
   Assert (Shortest_Path (G, 1, 3) = 7);
end Tests;
