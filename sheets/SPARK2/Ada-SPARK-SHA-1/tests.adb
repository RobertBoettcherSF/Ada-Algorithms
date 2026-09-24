pragma Ada_2022;
with SHA_1;
procedure Tests is
   use SHA_1;
begin
   pragma Assert (Digest_Length = 20);
   pragma Assert (Padded_Length (0) = 64);
   pragma Assert (Padded_Length (55) = 64);
   pragma Assert (Padded_Length (56) = 128);
   pragma Assert (Padded_Length (64) = 128);
end Tests;
