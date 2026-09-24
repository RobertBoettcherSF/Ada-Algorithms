with Ada.Assertions; use Ada.Assertions;
with Find_The_City; use Find_The_City;
procedure Tests is
   E : Network := [others => [others => 0]];
begin
   E (1, 2) := 3; E (2, 1) := 3;
   E (2, 3) := 4; E (3, 2) := 4;
   Assert (Find (E, 3, 4) = 3);
end Tests;
