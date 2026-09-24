pragma Ada_2022;
with Base64_Encode;
procedure Tests is
   use Base64_Encode;
begin
   pragma Assert (Encoded_Length (0) = 0);
   pragma Assert (Encoded_Length (1) = 4);
   pragma Assert (Encoded_Length (3) = 4);
   pragma Assert (Encoded_Length (4) = 8);
   pragma Assert (Encoded_Length (48) = 64);
end Tests;
