pragma Ada_2022;
with Standard_Score;
procedure Tests is
   use Standard_Score;
   Data : constant Sample_Array := [2, 4, 6, 8, 10];
begin
   pragma Assert (Mean (Data) = 6);
   pragma Assert (Score (Data, 1) = -40);
   pragma Assert (Score (Data, 5) = 40);
end Tests;
