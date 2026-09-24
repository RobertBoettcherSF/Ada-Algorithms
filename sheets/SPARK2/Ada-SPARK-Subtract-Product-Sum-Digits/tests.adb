with Ada.Assertions; use Ada.Assertions;
with Subtract_Product_Sum_Digits; use Subtract_Product_Sum_Digits;

procedure Tests is
begin
   Assert (Difference (234) = 15);
   Assert (Difference (4421) = 21);
   Assert (Difference (0) = 0);
   Assert (Difference (1_000_000_000) = -1);
end Tests;
