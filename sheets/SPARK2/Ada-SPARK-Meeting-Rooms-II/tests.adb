with Meeting_Rooms_II;
procedure Tests is
begin
   pragma Assert (Meeting_Rooms_II.Required_Rooms (2, 4) = 4);
   pragma Assert (Meeting_Rooms_II.Required_Rooms (5, 1) = 5);
   pragma Assert (Meeting_Rooms_II.Required_Rooms (0, 0) = 0);
end Tests;
