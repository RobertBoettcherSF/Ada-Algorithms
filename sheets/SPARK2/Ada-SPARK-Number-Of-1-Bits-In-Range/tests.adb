pragma Ada_2022;
with Number_Of_1_Bits_In_Range;
with Interfaces;
procedure Tests is
   use type Interfaces.Unsigned_32;
   package B renames Number_Of_1_Bits_In_Range;
begin
   pragma Assert (B.Count_One_Bits (0) = 0);
   pragma Assert (B.Count_One_Bits (16#8000_0000#) = 1);
   pragma Assert (B.Count_One_Bits (16#FFFF_FFFF#) = 32);
end Tests;
