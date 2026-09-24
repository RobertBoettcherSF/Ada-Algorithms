with Ada.Text_IO; use Ada.Text_IO;
with Extended_Euclidean; use Extended_Euclidean;

procedure Tests is
begin
   pragma Assert (GCD (240, 46) = 2);
   pragma Assert (GCD (99, 78) = 3);
   Put_Line ("extended Euclidean checks passed");
end Tests;
