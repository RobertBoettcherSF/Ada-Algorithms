pragma Ada_2022;
with Delta_Encoding;
procedure Tests is
   use Delta_Encoding;
   A : constant Sample_Array := [0, 4, 9, 3];
   B : constant Sample_Array := [-10, -10, -10];
begin
   pragma Assert (Net_Delta (A) = 3);
   pragma Assert (Net_Delta (B) = 0);
end Tests;
