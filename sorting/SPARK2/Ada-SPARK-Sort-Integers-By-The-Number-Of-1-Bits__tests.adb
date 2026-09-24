pragma Ada_2022;
with Sort_Integers_By_The_Number_Of_1_Bits;
with Interfaces;
procedure Tests is
   use type Interfaces.Unsigned_32;
   package S renames Sort_Integers_By_The_Number_Of_1_Bits;
begin
   pragma Assert (S.Bit_Count (0) = 0);
   pragma Assert (S.Bit_Count (1) = 1);
   pragma Assert (S.Bit_Count (16#F0F0#) = 8);
   pragma Assert (S.Bit_Count (16#FFFF_FFFF#) = 32);
end Tests;
