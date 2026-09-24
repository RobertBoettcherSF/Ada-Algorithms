with Ada.Assertions; use Ada.Assertions;
with Minimum_Sum_Of_Four_Digit_Number;
use Minimum_Sum_Of_Four_Digit_Number;
procedure Tests is
begin
   Assert (Minimum_Sum (2, 9, 3, 2) = 52);
   Assert (Minimum_Sum (4, 0, 9, 0) = 13);
   Assert (Minimum_Sum (1, 2, 3, 4) = 37);
end Tests;
