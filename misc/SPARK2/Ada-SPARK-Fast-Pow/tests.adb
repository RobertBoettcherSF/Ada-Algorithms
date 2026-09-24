with Ada.Text_IO; use Ada.Text_IO;
with Fast_Pow; use Fast_Pow;

procedure Tests is
begin
   pragma Assert (Power (2, 10) = 1_024);
   pragma Assert (Power (5, 12) = 244_140_625);
   pragma Assert (Power (0, 4) = 0);
   Put_Line ("fast pow checks passed");
end Tests;
