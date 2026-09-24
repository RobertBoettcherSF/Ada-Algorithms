pragma Ada_2022;
with Minimum_Bit_Flips_To_Convert;
procedure Tests is
   use Minimum_Bit_Flips_To_Convert;
begin
   pragma Assert (Count (0, 0) = 0);
   pragma Assert (Count (16#0F#, 16#F0#) = 8);
   pragma Assert (Count (16#2A#, 16#2B#) = 1);
end Tests;
