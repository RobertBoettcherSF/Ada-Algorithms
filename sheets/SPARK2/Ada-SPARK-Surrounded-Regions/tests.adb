with Ada.Assertions; use Ada.Assertions;
with Surrounded_Regions; use Surrounded_Regions;
procedure Tests is
   G : Grid := [others => [others => 0]];
begin
   Capture_Interior (G);
   Assert (G (1, 1) = 0);
   Assert (G (2, 2) = 1);
   Assert (G (7, 7) = 1);
   Assert (G (8, 8) = 0);
end Tests;
