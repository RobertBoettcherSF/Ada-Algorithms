pragma Ada_2022;
with Delta_Encoding;
with Own_Checks;
procedure Tests is
   use Delta_Encoding;
   A : constant Sample_Array := [0, 4, 9, 3];
   B : constant Sample_Array := [-10, -10, -10];
   A5 : constant Sample_Array (5 .. 8) := [0, 4, 9, 3];
   B_Top : constant Sample_Array (Positive'Last - 2 .. Positive'Last) :=
     [-10, 7, 20];
   One_At_40 : constant Sample_Array (40 .. 40) := [-128];
begin
   pragma Assert (Net_Delta (A) = 3);
   pragma Assert (Net_Delta (B) = 0);
   --  First-relative: the same samples at any origin give the same value
   --  (origins 1, 5, 200 and storage ending at Positive'Last).
   pragma Assert (Net_Delta (A5) = 3);
   pragma Assert (Net_Delta (B_Top) = 30);
   pragma Assert (Net_Delta (One_At_40) = 0);
   Own_Checks;
end Tests;
