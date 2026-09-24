with Ada.Assertions; use Ada.Assertions;
with Kruskal_MST_Lite; use Kruskal_MST_Lite;
procedure Tests is
   E : Edge_List := [others => (From => 1, To => 1, Cost => 0)];
begin
   E (1) := (From => 1, To => 2, Cost => 3);
   E (2) := (From => 2, To => 3, Cost => 4);
   Assert (Forest_Cost (E, 2) = 7);
end Tests;
