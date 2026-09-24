with Ada.Assertions; use Ada.Assertions;
with Rotate_Image; use Rotate_Image;
procedure Tests is
   Input : Image := ((1, 2, 3), (4, 5, 6), (7, 8, 9));
begin
   Rotate (Input);
   Assert (Input = ((7, 4, 1), (8, 5, 2), (9, 6, 3)));
end Tests;
