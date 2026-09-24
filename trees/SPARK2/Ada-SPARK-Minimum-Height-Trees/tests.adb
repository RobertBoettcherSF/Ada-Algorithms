with Ada.Assertions; use Ada.Assertions;
with Minimum_Height_Trees; use Minimum_Height_Trees;
procedure Tests is
   G : Graph := [others => [others => False]];
begin
   G (1, 3) := True; G (2, 3) := True; G (3, 1) := True; G (3, 2) := True;
   Assert (Center (G) = 3);
end Tests;
