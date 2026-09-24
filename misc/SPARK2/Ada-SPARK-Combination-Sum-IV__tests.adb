with Ada.Assertions; use Ada.Assertions;
with Combination_Sum_IV; use Combination_Sum_IV;
procedure Tests is
begin
   Assert (Count_Ordered_Ways (0) = 1);
   Assert (Count_Ordered_Ways (4) = 7);
   Assert (Count_Ordered_Ways (6) = 24);
end Tests;
