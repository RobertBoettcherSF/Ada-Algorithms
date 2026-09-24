pragma Ada_2022;
with Matrix_Diagonal_Sum; use Matrix_Diagonal_Sum;
procedure Tests is
   Input : Matrix := ((1, 2, 3, 4), (5, 6, 7, 8), (9, 10, 11, 12), (13, 14, 15, 16));
begin
   pragma Assert (Diagonal_Sum (Input) = 68);
end Tests;
