with Ada.Assertions; use Ada.Assertions;
with Minimum_Limit_Of_Balls_In_A_Bag;
use Minimum_Limit_Of_Balls_In_A_Bag;

procedure Tests is
   Bags : constant Bag_Array := [9, 7, 5, 3, 2, 1, 4, 6];
begin
   Assert (Minimum_Limit (Bags, 0) = 9);
   Assert (Minimum_Limit (Bags, 4) = 5);
end Tests;
