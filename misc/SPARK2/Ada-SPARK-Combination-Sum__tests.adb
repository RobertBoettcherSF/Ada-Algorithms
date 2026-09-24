with Ada.Assertions; use Ada.Assertions;
with Combination_Sum; use Combination_Sum;
procedure Tests is
begin
   Assert (Count_Combinations (0) = 1);
   Assert (Count_Combinations (5) = 7);
   Assert (Count_Combinations (12) = 77);
end Tests;
