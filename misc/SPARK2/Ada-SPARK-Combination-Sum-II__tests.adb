with Ada.Assertions; use Ada.Assertions;
with Combination_Sum_II; use Combination_Sum_II;
procedure Tests is
begin
   Assert (Count_Distinct_Combinations (0) = 1);
   Assert (Count_Distinct_Combinations (6) = 4);
   Assert (Count_Distinct_Combinations (12) = 15);
end Tests;
