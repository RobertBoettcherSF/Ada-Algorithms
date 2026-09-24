pragma Ada_2022;
with Transpose_Matrix; use Transpose_Matrix;
procedure Tests is
   M : Matrix := ((1, 2, 3, 4), (5, 6, 7, 8), (9, 10, 11, 12), (13, 14, 15, 16));
begin
   Transpose (M);
   pragma Assert (M = ((1, 5, 9, 13), (2, 6, 10, 14), (3, 7, 11, 15), (4, 8, 12, 16)));
end Tests;
