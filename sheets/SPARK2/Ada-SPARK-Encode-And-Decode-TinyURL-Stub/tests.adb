with Ada.Assertions; use Ada.Assertions;
with Encode_And_Decode_TinyURL_Stub; use Encode_And_Decode_TinyURL_Stub;

procedure Tests is
begin
   Assert (Encode (0) = 1);
   Assert (Encode (255) = 256);
   Assert (Decode (Encode (37)) = 37);
end Tests;
