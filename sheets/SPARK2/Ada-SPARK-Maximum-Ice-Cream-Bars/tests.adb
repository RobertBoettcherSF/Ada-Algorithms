with Ada.Assertions; use Ada.Assertions;
with Maximum_Ice_Cream_Bars; use Maximum_Ice_Cream_Bars;
procedure Tests is
begin
   Assert (Bars_Bought (3, 10) = 3);
   Assert (Bars_Bought (6, 10) = 1);
   Assert (Bars_Bought (1, 32_000) = 32);
   Assert (Bars_Bought (10, 0) = 0);
end Tests;
