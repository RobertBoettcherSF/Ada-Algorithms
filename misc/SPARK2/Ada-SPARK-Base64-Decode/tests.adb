pragma Ada_2022;
with Base64_Decode;
procedure Tests is
   use Base64_Decode;
begin
   pragma Assert (Decoded_Length (0) = 0);
   pragma Assert (Decoded_Length (4) = 3);
   pragma Assert (Decoded_Length (16) = 12);
   pragma Assert (Decoded_Length (64) = 48);
end Tests;
