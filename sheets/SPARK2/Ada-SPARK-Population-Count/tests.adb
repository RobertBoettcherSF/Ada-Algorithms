pragma Ada_2022;
with Population_Count;
procedure Tests is
begin
   pragma Assert (Population_Count.Count (0) = 0);
   pragma Assert (Population_Count.Count (1) = 1);
   pragma Assert (Population_Count.Count (16#FFFF_FFFF#) = 32);
   pragma Assert (Population_Count.Count (16#F0F0_0001#) = 9);
end Tests;
