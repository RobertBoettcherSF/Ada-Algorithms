with Ada.Assertions; use Ada.Assertions;
with Two_City_Scheduling; use Two_City_Scheduling;
procedure Tests is
begin
   Assert (Cheapest_Assignment (10, 20, 30, 40) = 50);
   Assert (Cheapest_Assignment (30, 10, 20, 40) = 30);
   Assert (Cheapest_Assignment (0, 1_000, 1_000, 0) = 0);
end Tests;
