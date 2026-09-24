pragma Ada_2022;
with Histogram_Bin;
procedure Tests is
   use Histogram_Bin;
begin
   pragma Assert (Bin_Of (0) = 1);
   pragma Assert (Bin_Of (3) = 1);
   pragma Assert (Bin_Of (4) = 2);
   pragma Assert (Bin_Of (15) = 4);
end Tests;
