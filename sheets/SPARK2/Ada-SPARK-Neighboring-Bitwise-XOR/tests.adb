pragma Ada_2022;
with Neighboring_Bitwise_XOR;
procedure Tests is
   use Neighboring_Bitwise_XOR;
begin
   pragma Assert (Is_Valid ([1, 2, 3, 0]));
   pragma Assert (not Is_Valid ([1, 2, 3, 1]));
end Tests;
