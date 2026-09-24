with Ada.Assertions; use Ada.Assertions;
with N_Queens_Lite; use N_Queens_Lite;
procedure Tests is
   Good : constant Positions := (1 => 2, 2 => 4, 3 => 1, 4 => 3);
   Bad  : constant Positions := (1 => 1, 2 => 2, 3 => 3, 4 => 4);
begin
   Assert (Is_Solution (Good));
   Assert (not Is_Solution (Bad));
end Tests;
