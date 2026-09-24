with Ada.Assertions; use Ada.Assertions;
with Shortest_Bridge; use Shortest_Bridge;

procedure Tests is
   G : Grid := [others => [others => 0]];
begin
   Assert (Island_Count (G) = 0);
   G (1, 1) := 1;
   G (4, 5) := 1;
   G (8, 8) := 1;
   Assert (Island_Count (G) = 3);
end Tests;
