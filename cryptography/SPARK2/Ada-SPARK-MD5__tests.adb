pragma Ada_2022;
with MD5;
procedure Tests is
   use MD5;
begin
   pragma Assert (Digest_Length = 16);
   pragma Assert (Padded_Length (0) = 64);
   pragma Assert (Padded_Length (55) = 64);
   pragma Assert (Padded_Length (56) = 128);
   pragma Assert (Padded_Length (64) = 128);
end Tests;
