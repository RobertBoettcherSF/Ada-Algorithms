with Meeting_Rooms;
procedure Tests is
begin
   pragma Assert (Meeting_Rooms.Non_Overlapping (1, 3, 4, 8));
   pragma Assert (Meeting_Rooms.Non_Overlapping (4, 8, 1, 3));
   pragma Assert (not Meeting_Rooms.Non_Overlapping (2, 5, 4, 9));
end Tests;
