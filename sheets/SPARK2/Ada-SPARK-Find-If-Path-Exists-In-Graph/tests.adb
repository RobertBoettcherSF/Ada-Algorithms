with Ada.Assertions; use Ada.Assertions;
with Find_If_Path_Exists_In_Graph; use Find_If_Path_Exists_In_Graph;
procedure Tests is
   G : Graph := [others => [others => False]];
begin
   G (1, 2) := True; G (2, 3) := True;
   Assert (Path_Exists (G, 1, 3));
   Assert (not Path_Exists (G, 3, 1));
end Tests;
