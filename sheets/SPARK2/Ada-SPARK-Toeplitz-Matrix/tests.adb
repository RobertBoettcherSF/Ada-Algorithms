pragma Ada_2022;
with Toeplitz_Matrix; use Toeplitz_Matrix;
procedure Tests is
   Good : Matrix := ((1, 2, 3, 4), (5, 1, 2, 3), (6, 5, 1, 2), (7, 6, 5, 1));
   Bad : Matrix := ((1, 2, 3, 4), (5, 1, 9, 3), (6, 5, 1, 2), (7, 6, 5, 1));
begin
   pragma Assert (Is_Toeplitz (Good));
   pragma Assert (not Is_Toeplitz (Bad));
end Tests;
