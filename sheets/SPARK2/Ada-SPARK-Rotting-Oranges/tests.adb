with Ada.Assertions; use Ada.Assertions;
with Rotting_Oranges; use Rotting_Oranges;

procedure Tests is
   G : Grid := [others => [others => 0]];
begin
   Assert (Fresh_Count (G) = 0);
   G (1, 1) := 1;
   G (4, 5) := 1;
   G (8, 8) := 1;
   Assert (Fresh_Count (G) = 3);
end Tests;
