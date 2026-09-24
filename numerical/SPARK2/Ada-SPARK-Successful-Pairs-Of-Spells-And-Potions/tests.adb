with Ada.Text_IO; use Ada.Text_IO;
with Successful_Pairs_Of_Spells_And_Potions; use Successful_Pairs_Of_Spells_And_Potions;
procedure Tests is
   Spells : constant Strengths := (2, 4);
   Potions : constant Strengths := (2, 3);
begin
   if Successful_Pairs (Spells, Potions, 8) /= 2 then raise Program_Error; end if;
   Put_Line ("successful pairs: PASS");
end Tests;
