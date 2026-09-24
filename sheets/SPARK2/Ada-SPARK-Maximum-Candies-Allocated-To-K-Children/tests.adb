with Ada.Assertions; use Ada.Assertions;
with Maximum_Candies_Allocated_To_K_Children;
use Maximum_Candies_Allocated_To_K_Children;

procedure Tests is
   Piles : constant Pile_Array := [5, 8, 6, 4, 3, 2, 1, 7];
begin
   Assert (Maximum_Candies (Piles, 8) = 3);
   Assert (Maximum_Candies (Piles, 4) = 5);
end Tests;
