pragma Ada_2022;
with Diagonal_Traverse; use Diagonal_Traverse;
procedure Tests is
   Input : Matrix := ((1, 2, 3, 4), (5, 6, 7, 8), (9, 10, 11, 12), (13, 14, 15, 16));
   Output : Sequence;
begin
   Traverse (Input, Output);
   pragma Assert (Output = (1, 2, 5, 9, 6, 3, 4, 7, 10, 13, 14, 11, 8, 12, 15, 16));
end Tests;
