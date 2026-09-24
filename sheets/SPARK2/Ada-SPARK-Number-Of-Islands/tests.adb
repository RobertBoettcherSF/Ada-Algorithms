with Ada.Assertions; use Ada.Assertions;
with Number_Of_Islands; use Number_Of_Islands;
procedure Tests is
   G : Grid := [others => [others => 0]];
begin
   Assert (Count_Islands (G) = 0);
   G (1, 1) := 1;
   G (4, 5) := 1;
   G (8, 8) := 1;
   Assert (Count_Islands (G) = 3);
end Tests;
