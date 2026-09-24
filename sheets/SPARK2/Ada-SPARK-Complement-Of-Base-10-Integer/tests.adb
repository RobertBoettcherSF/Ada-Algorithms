pragma Ada_2022;
with Complement_Of_Base_10_Integer;
with Interfaces;
procedure Tests is
   use type Interfaces.Unsigned_32;
   package C renames Complement_Of_Base_10_Integer;
begin
   pragma Assert (C.Complement (0) = 1);
   pragma Assert (C.Complement (5) = 2);
   pragma Assert (C.Complement (10) = 5);
   pragma Assert (C.Complement (16#FFFF_FFFF#) = 0);
end Tests;
