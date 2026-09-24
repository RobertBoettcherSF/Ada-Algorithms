pragma Ada_2022;
with Difference_Array;
procedure Tests is
   use Difference_Array;
   Input : constant Input_Array := [2, 5, 4, 9, 3];
   Expected : constant Difference_Values := [2, 3, -1, 5, -6];
begin
   pragma Assert (Compute (Input) = Expected);
end Tests;
