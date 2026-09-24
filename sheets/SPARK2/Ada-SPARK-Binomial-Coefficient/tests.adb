with Ada.Text_IO; use Ada.Text_IO;
with Binomial_Coefficient; use Binomial_Coefficient;

procedure Tests is
begin
   pragma Assert (Choose (5, 2) = 10);
   pragma Assert (Choose (10, 5) = 252);
   pragma Assert (Choose (4, 8) = 0);
   Put_Line ("binomial checks passed");
end Tests;
