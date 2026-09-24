pragma Ada_2022;
with Interfaces;
with Bitwise_XOR_Of_All_Pairings;
procedure Tests is
   use type Interfaces.Unsigned_8;
   use Bitwise_XOR_Of_All_Pairings;
begin
   pragma Assert (Pairings_Xor ([1, 2, 3], [4, 5, 6]) = 7);
   pragma Assert (Pairings_Xor ([16#AA#, 16#00#, 16#55#], [1, 2, 3]) = 16#FF#);
end Tests;
