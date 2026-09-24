with Ada.Assertions; use Ada.Assertions;
with Max_Area_Of_Island; use Max_Area_Of_Island;
procedure Tests is
   G : Grid := [others => [others => 0]];
begin
   G (1, 1) := 1;
   G (1, 2) := 1;
   G (2, 1) := 1;
   Assert (Max_Area (G) = 3);
end Tests;
