pragma Ada_2022;
with Parity_Bits;
procedure Tests is
begin
   pragma Assert (Parity_Bits.Even (0));
   pragma Assert (Parity_Bits.Even (16#FFFF_FFFF#));
   pragma Assert (Parity_Bits.Odd (1));
   pragma Assert (Parity_Bits.Odd (16#FFFF_FFFE#));
end Tests;
