with Boats_To_Save_People;
procedure Tests is
begin
   pragma Assert (Boats_To_Save_People.Boats_Needed (0, 2) = 0);
   pragma Assert (Boats_To_Save_People.Boats_Needed (5, 2) = 3);
   pragma Assert (Boats_To_Save_People.Boats_Needed (8, 4) = 2);
end Tests;
