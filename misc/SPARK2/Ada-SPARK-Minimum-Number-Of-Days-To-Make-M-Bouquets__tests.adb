with Ada.Assertions; use Ada.Assertions;
with Minimum_Number_Of_Days_To_Make_M_Bouquets;
use Minimum_Number_Of_Days_To_Make_M_Bouquets;

procedure Tests is
   Bloom_Days : constant Bloom_Array := [5, 4, 3, 2, 1, 7, 6, 8];
begin
   Assert (Minimum_Day (Bloom_Days, 1) = 1);
   Assert (Minimum_Day (Bloom_Days, 2) = 2);
   Assert (Minimum_Day (Bloom_Days, 4) = 4);
end Tests;
