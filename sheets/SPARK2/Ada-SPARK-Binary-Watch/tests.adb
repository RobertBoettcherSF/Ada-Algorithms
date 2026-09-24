pragma Ada_2022;
with Binary_Watch;
procedure Tests is
begin
   pragma Assert (Binary_Watch.To_Minutes (0, 0) = 0);
   pragma Assert (Binary_Watch.To_Minutes (3, 15) = 195);
   pragma Assert (Binary_Watch.Is_Valid (11, 59));
end Tests;
