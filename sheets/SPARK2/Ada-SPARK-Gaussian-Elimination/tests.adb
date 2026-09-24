pragma Ada_2022;
with Gaussian_Elimination;
procedure Tests is
   use Gaussian_Elimination;
   A : constant Input_Matrix := [(2, 1, 5), (1, -1, 1)];
   R : constant Reduced_Matrix := Eliminate (A);
begin
   pragma Assert (R (1, 1) = 2 and R (1, 2) = 1 and R (1, 3) = 5);
   pragma Assert (R (2, 1) = 0 and R (2, 2) = -3 and R (2, 3) = -3);
end Tests;
