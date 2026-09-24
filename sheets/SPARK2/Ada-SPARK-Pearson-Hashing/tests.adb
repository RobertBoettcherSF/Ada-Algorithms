pragma Ada_2022;
with Pearson_Hashing;
use Pearson_Hashing;
procedure Tests is
   H1 : constant Hash_Value := Hash ("hello");
   H2 : constant Hash_Value := Hash ("world");
begin
   pragma Assert (H1 < Table_Size);
   pragma Assert (H2 < Table_Size);
   pragma Assert (H1 /= H2);
end Tests;
