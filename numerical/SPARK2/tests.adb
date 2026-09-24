pragma Ada_2022;
with Babylonian_Sqrt;
procedure Tests is
begin
   pragma Assert (Babylonian_Sqrt.Sqrt (0) = 0);
   pragma Assert (Babylonian_Sqrt.Sqrt (144) = 12);
   pragma Assert (Babylonian_Sqrt.Sqrt (10_000) = 100);
end Tests;
