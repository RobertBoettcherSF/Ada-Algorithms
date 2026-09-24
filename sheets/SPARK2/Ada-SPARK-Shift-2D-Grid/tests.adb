pragma Ada_2022;
with Shift_2D_Grid; use Shift_2D_Grid;
procedure Tests is
   Input : Matrix := ((1, 2, 3, 4), (5, 6, 7, 8), (9, 10, 11, 12), (13, 14, 15, 16));
   Output : Matrix;
begin
   Shift (Input, Output);
   pragma Assert (Output = ((16, 1, 2, 3), (4, 5, 6, 7), (8, 9, 10, 11), (12, 13, 14, 15)));
end Tests;
