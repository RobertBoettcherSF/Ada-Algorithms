with Ada.Text_IO; use Ada.Text_IO;
with Modular_Exponentiation; use Modular_Exponentiation;

procedure Tests is
begin
   pragma Assert (Power (2, 10, 100) = 24);
   pragma Assert (Power (7, 0, 13) = 1);
   pragma Assert (Power (3, 5, 7) = 5);
   Put_Line ("modular exponentiation checks passed");
end Tests;
