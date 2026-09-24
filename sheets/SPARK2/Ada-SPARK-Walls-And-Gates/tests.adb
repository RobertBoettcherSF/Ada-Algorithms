with Ada.Assertions; use Ada.Assertions;
with Walls_And_Gates; use Walls_And_Gates;

procedure Tests is
   G : Grid := [others => [others => 0]];
begin
   Assert (Gate_Count (G) = 0);
   G (1, 1) := 1;
   G (4, 5) := 1;
   G (8, 8) := 1;
   Assert (Gate_Count (G) = 3);
end Tests;
