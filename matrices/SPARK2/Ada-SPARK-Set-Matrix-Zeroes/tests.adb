with Ada.Assertions; use Ada.Assertions;
with Set_Matrix_Zeroes; use Set_Matrix_Zeroes;
procedure Tests is
   Input : Matrix := ((1, 2, 3), (4, 0, 6), (7, 8, 9));
   Expected : constant Matrix := ((1, 0, 3), (0, 0, 0), (7, 0, 9));
begin
   Zero (Input);
   Assert (Input = Expected);
end Tests;
