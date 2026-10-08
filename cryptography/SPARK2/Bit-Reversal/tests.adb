pragma Ada_2022;
with Bit_Reversal;
with Interfaces;
procedure Tests is
   use type Interfaces.Unsigned_32;
begin
   pragma Assert (Bit_Reversal.Reverse_Bits (0) = 0);
   pragma Assert (Bit_Reversal.Reverse_Bits (1) = 16#8000_0000#);
   pragma Assert (Bit_Reversal.Reverse_Bits (16#8000_0000#) = 1);
   pragma Assert (Bit_Reversal.Reverse_Bits (16#0123_4567#) = 16#E6A2_C480#);
end Tests;
