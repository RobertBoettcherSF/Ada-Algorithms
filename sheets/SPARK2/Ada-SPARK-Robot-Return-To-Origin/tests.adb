with Ada.Assertions; use Ada.Assertions;
with Robot_Origin; use Robot_Origin;
procedure Tests is
   Moves : Text := [others => ' '];
begin
   Moves (1 .. 4) := "UDLR";
   Assert (Returns_To_Origin (Moves, 4));
   Moves (1 .. 2) := "LL";
   Assert (not Returns_To_Origin (Moves, 2));
end Tests;
