with Ada.Assertions; use Ada.Assertions;
with Redundant_Connection_II; use Redundant_Connection_II;
procedure Tests is
   E : Edge_List := [others => (From => 1, To => 1)];
begin
   E (1) := (From => 1, To => 2);
   E (2) := (From => 2, To => 3);
   E (3) := (From => 1, To => 2);
   Assert (Has_Redundant_Edge (E, 3));
   E (3) := (From => 3, To => 4);
   Assert (not Has_Redundant_Edge (E, 3));
end Tests;
