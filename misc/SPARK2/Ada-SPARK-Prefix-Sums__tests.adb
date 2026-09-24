pragma Ada_2022;
with Prefix_Sums;
procedure Tests is
   use Prefix_Sums;
   Input : constant Input_Array := [1, 2, 3, 4, 5];
   Expected : constant Sum_Array := [1, 3, 6, 10, 15];
begin
   pragma Assert (Compute (Input) = Expected);
end Tests;
