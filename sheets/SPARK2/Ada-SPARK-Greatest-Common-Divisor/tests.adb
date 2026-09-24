with Ada.Text_IO; use Ada.Text_IO;
with Greatest_Common_Divisor; use Greatest_Common_Divisor;

procedure Tests is
begin
   pragma Assert (GCD (48, 18) = 6);
   pragma Assert (GCD (17, 13) = 1);
   Put_Line ("GCD checks passed");
end Tests;
