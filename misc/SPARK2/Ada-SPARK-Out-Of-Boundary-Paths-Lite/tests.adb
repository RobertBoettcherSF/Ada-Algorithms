with Out_Of_Boundary_Paths_Lite;
procedure Tests is
   use Out_Of_Boundary_Paths_Lite;
begin
   pragma Assert (Immediate_Exits (2, 2) = 0);
   pragma Assert (Immediate_Exits (1, 2) = 1);
   pragma Assert (Immediate_Exits (1, 4) = 2);
end Tests;
