pragma Ada_2022;
with Image_Smoother; use Image_Smoother;
procedure Tests is
   Input : Image := ((1, 1, 1, 1), (1, 9, 9, 1), (1, 9, 9, 1), (1, 1, 1, 1));
   Output : Image;
begin
   Smooth (Input, Output);
   pragma Assert (Output (1, 1) = 3);
   pragma Assert (Output (2, 2) = 4);
end Tests;
