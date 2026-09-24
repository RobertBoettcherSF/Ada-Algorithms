with Ada.Assertions; use Ada.Assertions;
with Pacific_Atlantic_Water_Flow; use Pacific_Atlantic_Water_Flow;
procedure Tests is
   G : Grid := [others => [others => 4]];
   R : Reachability;
begin
   G (2, 3) := 0;
   R := Reachable (G);
   Assert (R (2, 3));
   Assert (not R (1, 1));
end Tests;
