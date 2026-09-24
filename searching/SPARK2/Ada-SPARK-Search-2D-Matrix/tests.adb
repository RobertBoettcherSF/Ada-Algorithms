with Ada.Assertions; use Ada.Assertions;
with Search_2D_Matrix; use Search_2D_Matrix;
procedure Tests is
   Input : constant Matrix := ((1, 3, 5), (7, 9, 11), (13, 15, 17));
begin
   Assert (Contains (Input, 9));
   Assert (not Contains (Input, 10));
end Tests;
