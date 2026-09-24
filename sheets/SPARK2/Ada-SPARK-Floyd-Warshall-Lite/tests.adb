with Ada.Assertions; use Ada.Assertions;
with Floyd_Warshall_Lite; use Floyd_Warshall_Lite;
procedure Tests is
   G : Graph := [others => [others => 0]];
begin
   G (1, 2) := 2; G (2, 3) := 6; G (1, 3) := 11;
   Assert (Shortest_Path (G, 1, 3) = 8);
end Tests;
