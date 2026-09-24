with Ada.Assertions; use Ada.Assertions;
with Largest_Rectangle_In_Histogram; use Largest_Rectangle_In_Histogram;
procedure Tests is
   H : constant Heights := [2, 1, 5, 6, 2, 3, others => 0];
begin
   Assert (Max_Area (H, 6) = 10);
   Assert (Max_Area (H, 0) = 0);
end Tests;
