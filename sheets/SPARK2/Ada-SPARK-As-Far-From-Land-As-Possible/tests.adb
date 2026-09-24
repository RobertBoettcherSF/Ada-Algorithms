with Ada.Assertions; use Ada.Assertions;
with As_Far_From_Land_As_Possible; use As_Far_From_Land_As_Possible;

procedure Tests is
   G : Grid := [others => [others => 0]];
begin
   Assert (Land_Count (G) = 0);
   G (1, 1) := 1;
   G (4, 5) := 1;
   G (8, 8) := 1;
   Assert (Land_Count (G) = 3);
end Tests;
