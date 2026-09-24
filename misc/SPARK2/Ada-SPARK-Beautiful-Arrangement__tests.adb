with Ada.Assertions; use Ada.Assertions;
with Beautiful_Arrangement; use Beautiful_Arrangement;
procedure Tests is
   Good : constant Arrangement := (1 => 1, 2 => 2, 3 => 3, 4 => 4, others => 0);
   Bad  : constant Arrangement := (1 => 2, 2 => 3, 3 => 1, 4 => 4, others => 0);
begin
   Assert (Is_Beautiful (Good, 4));
   Assert (not Is_Beautiful (Bad, 4));
end Tests;
