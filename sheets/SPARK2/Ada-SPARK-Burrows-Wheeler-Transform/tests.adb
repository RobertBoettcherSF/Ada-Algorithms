pragma Ada_2022;
with Burrows_Wheeler_Transform;
procedure Tests is
   use Burrows_Wheeler_Transform;
   Input : constant Text := ['b', 'a', 'n', 'a', 'n', 'a', '$', ' '];
begin
   pragma Assert (Rotation_Character (Input, 1, 0) = 'b');
   pragma Assert (Rotation_Character (Input, 7, 1) = ' ');
   pragma Assert (Rotation_Less (Input, 2, 1));
   pragma Assert (not Rotation_Less (Input, 1, 2));
end Tests;
