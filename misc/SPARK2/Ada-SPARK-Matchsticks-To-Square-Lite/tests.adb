with Ada.Assertions; use Ada.Assertions;
with Matchsticks_To_Square_Lite; use Matchsticks_To_Square_Lite;
procedure Tests is
   Good : constant Stick_List := (1 => 1, 2 => 1, 3 => 2, 4 => 2, 5 => 3, 6 => 3, others => 1);
   Bad  : constant Stick_List := (1 => 5, 2 => 1, 3 => 1, 4 => 1, others => 1);
begin
   Assert (Can_Form_Square (Good, 6));
   Assert (not Can_Form_Square (Bad, 4));
end Tests;
