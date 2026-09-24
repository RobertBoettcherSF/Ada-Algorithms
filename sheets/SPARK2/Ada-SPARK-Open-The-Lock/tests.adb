with Ada.Assertions; use Ada.Assertions;
with Open_The_Lock; use Open_The_Lock;

procedure Tests is
   G : Grid := [others => [others => 0]];
begin
   Assert (Turn_Sum (G) = 0);
   G (1, 1) := 1;
   G (4, 5) := 1;
   G (8, 8) := 1;
   Assert (Turn_Sum (G) = 3);
end Tests;
