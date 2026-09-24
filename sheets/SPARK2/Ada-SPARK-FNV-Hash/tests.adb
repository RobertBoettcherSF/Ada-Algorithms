pragma Ada_2022;
with FNV_Hash;
use FNV_Hash;
procedure Tests is
   H1 : constant Hash_Value := Hash ("hello");
   H2 : constant Hash_Value := Hash ("world");
begin
   pragma Assert (H1 /= H2);
   pragma Assert (Hash ("") = 2_166_136_261);
end Tests;
