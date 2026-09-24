with Ada.Text_IO; use Ada.Text_IO;
with Factorial; use Factorial;

procedure Tests is
begin
   pragma Assert (Compute (0) = 1);
   pragma Assert (Compute (5) = 120);
   pragma Assert (Compute (12) = 479_001_600);
   Put_Line ("factorial checks passed");
end Tests;
