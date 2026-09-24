pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Clone_Graph; use Clone_Graph;
procedure Tests is
   G : Graph := (others => (others => False));
   C : Graph;
begin
   G (1, 2) := True;
   G (2, 3) := True;
   G (3, 1) := True;
   C := Clone (G);
   Assert (C = G);
end Tests;
