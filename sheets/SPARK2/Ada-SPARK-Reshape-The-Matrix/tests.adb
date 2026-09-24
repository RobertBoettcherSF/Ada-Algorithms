pragma Ada_2022;
with Reshape_The_Matrix; use Reshape_The_Matrix;
procedure Tests is
   Input : Source := ((1, 2, 3, 4), (5, 6, 7, 8));
   Output : Matrix;
begin
   Reshape (Input, Output);
   pragma Assert (Output = ((1, 2), (3, 4), (5, 6), (7, 8)));
end Tests;
