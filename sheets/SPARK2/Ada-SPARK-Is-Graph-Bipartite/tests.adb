pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Is_Graph_Bipartite; use Is_Graph_Bipartite;
procedure Tests is
   G : Graph := (others => (others => False));
begin
   G (1, 2) := True; G (2, 1) := True;
   G (2, 3) := True; G (3, 2) := True;
   Assert (Is_Bipartite (G));
   G (1, 3) := True; G (3, 1) := True;
   Assert (not Is_Bipartite (G));
end Tests;
