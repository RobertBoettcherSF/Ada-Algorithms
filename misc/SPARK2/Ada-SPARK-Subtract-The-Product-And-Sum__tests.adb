with Ada.Assertions; use Ada.Assertions;
with Subtract_Product_Sum; use Subtract_Product_Sum;

procedure Tests is
begin
   Assert (Difference (0) = 0);
   Assert (Difference (12) = -1);
   Assert (Difference (99) = 63);
end Tests;
