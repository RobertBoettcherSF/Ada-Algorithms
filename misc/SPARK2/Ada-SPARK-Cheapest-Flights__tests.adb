with Ada.Assertions; use Ada.Assertions;
with Cheapest_Flights; use Cheapest_Flights;
procedure Tests is
   F : Network := [others => [others => 0]];
begin
   F (1, 2) := 7; F (2, 3) := 4;
   Assert (Cheapest_Direct (F, 1, 2) = 7);
   Assert (Cheapest_Direct (F, 1, 1) = 0);
end Tests;
