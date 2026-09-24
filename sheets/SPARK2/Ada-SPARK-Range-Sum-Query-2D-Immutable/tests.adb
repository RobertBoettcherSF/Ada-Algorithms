with Ada.Assertions; use Ada.Assertions;
with Range_Sum_Query_2D_Immutable; use Range_Sum_Query_2D_Immutable;

procedure Tests is
   G : Grid := [others => [others => 0]];
begin
   Assert (Sum_All (G) = 0);
   G (2, 3) := 1;
   G (8, 8) := 1;
   Assert (Sum_All (G) = 2);
end Tests;
