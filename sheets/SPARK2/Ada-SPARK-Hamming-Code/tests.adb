pragma Ada_2022;
with Interfaces;
with Hamming_Code;
procedure Tests is
   use Hamming_Code;
   use type Interfaces.Unsigned_8;
begin
   pragma Assert (Encode (0) = 0);
   pragma Assert (Encode (1) = 7);
   pragma Assert (Encode (10) = 82);
   pragma Assert (Decode (Encode (13)) = 13);
end Tests;
