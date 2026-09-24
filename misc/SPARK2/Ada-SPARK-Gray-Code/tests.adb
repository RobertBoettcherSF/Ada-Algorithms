pragma Ada_2022;
with Interfaces;
with Gray_Code;
procedure Tests is
   use type Interfaces.Unsigned_32;
begin
   pragma Assert (Gray_Code.Encode (0) = 0);
   pragma Assert (Gray_Code.Encode (1) = 1);
   pragma Assert (Gray_Code.Encode (2) = 3);
   pragma Assert (Gray_Code.Decode (Gray_Code.Encode (16#1234_5678#)) = 16#1234_5678#);
end Tests;
