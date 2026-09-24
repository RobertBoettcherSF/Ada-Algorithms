with Ada.Assertions; use Ada.Assertions;
with Combination_Sum_III; use Combination_Sum_III;
procedure Tests is
begin
   Assert (Feasible (3, 7));
   Assert (Feasible (3, 24));
   Assert (not Feasible (3, 5));
   Assert (Count_Choices (4, 10) = 1);
end Tests;
