with Ada.Assertions; use Ada.Assertions;
with Spiral_Matrix; use Spiral_Matrix;
procedure Tests is
   Input : constant Matrix := ((1, 2, 3), (8, 9, 4), (7, 6, 5));
   Answer : constant Sequence := Traverse (Input);
begin
   Assert (Answer = (1, 2, 3, 4, 5, 6, 7, 8, 9));
end Tests;
