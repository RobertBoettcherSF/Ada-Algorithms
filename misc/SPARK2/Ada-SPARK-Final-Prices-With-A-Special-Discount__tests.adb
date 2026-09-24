with Ada.Assertions; use Ada.Assertions;
with Final_Prices_With_A_Special_Discount; use Final_Prices_With_A_Special_Discount;
procedure Tests is
begin Assert (Final_Price (200, 25) = 150); Assert (Special (100) = 80); end Tests;
