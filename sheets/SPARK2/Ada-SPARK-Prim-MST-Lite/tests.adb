with Ada.Assertions; use Ada.Assertions;
with Prim_Mst_Lite; use Prim_Mst_Lite;
procedure Tests is
   G : Graph := (others => (others => 0));
begin
   G (1, 2) := 2; G (2, 1) := 2;
   G (1, 3) := 3; G (3, 1) := 3;
   Assert (Mst_Weight (G, 3) = 3);
end Tests;
