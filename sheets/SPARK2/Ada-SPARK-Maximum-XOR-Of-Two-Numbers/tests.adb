pragma Ada_2022;
with Interfaces;
with Maximum_Xor_Of_Two_Numbers;
procedure Tests is
   use type Interfaces.Unsigned_32;
begin
   pragma Assert (Maximum_Xor_Of_Two_Numbers.Maximum_Xor (16#0F#, 16#F0#) = 16#FF#);
   pragma Assert (Maximum_Xor_Of_Two_Numbers.Maximum_Xor (1, 2, 4) = 6);
end Tests;
