pragma Ada_2022;
with Interfaces;
with Find_The_Difference;
procedure Tests is
   use type Interfaces.Unsigned_8;
begin
   pragma Assert (Find_The_Difference.Difference (16#2A#, 16#2B#) = 1);
   pragma Assert (Find_The_Difference.Difference (16#00#, 16#FF#) = 16#FF#);
end Tests;
