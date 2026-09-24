pragma Ada_2022;
with Total_Hamming_Distance;
procedure Tests is
begin
   pragma Assert (Total_Hamming_Distance.Distance (0, 0) = 0);
   pragma Assert (Total_Hamming_Distance.Distance (16#FFFF_FFFF#, 0) = 32);
   pragma Assert (Total_Hamming_Distance.Distance (16#AAAA_AAAA#, 16#5555_5555#) = 32);
end Tests;
