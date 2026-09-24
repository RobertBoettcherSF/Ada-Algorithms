with Ada.Assertions; use Ada.Assertions;
with Topological_Sort_Lite; use Topological_Sort_Lite;
procedure Tests is
   G : Graph := [others => [others => False]];
   O : Order_Array := [1, 2, 3, others => 1];
begin
   G (1, 2) := True; G (2, 3) := True;
   Assert (Is_Valid_Order (G, O, 3));
   Assert (not Is_Valid_Order (G, [3, 2, 1, others => 1], 3));
end Tests;
