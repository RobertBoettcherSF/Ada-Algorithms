pragma Ada_2022;
with Interfaces;
with Encode_And_Decode_Strings_Lite;
with Own_Checks;
procedure Tests is
   use type Interfaces.Unsigned_8;
begin
   pragma Assert (Encode_And_Decode_Strings_Lite.Decode
     (Encode_And_Decode_Strings_Lite.Encode (16#41#)) = 16#41#);
   pragma Assert (Encode_And_Decode_Strings_Lite.Encode (0) = 16#A5#);
   Own_Checks;
end Tests;
