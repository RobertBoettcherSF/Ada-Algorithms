pragma Ada_2022;
with Gaussian_Elimination;
with Own_Checks;
procedure Tests is
   use Gaussian_Elimination;
   A : constant Input_Matrix := [[2, 1, 5], [1, -1, 1]];
   R : constant Reduced_Matrix := Eliminate (A);
begin
   pragma Assert (R (1, 1) = 2 and R (1, 2) = 1 and R (1, 3) = 5);
   pragma Assert (R (2, 1) = 0 and R (2, 2) = -3 and R (2, 3) = -3);
   --  a21 = 0 with a pivot /= 1 still takes the fraction-free step of the README
   --  (row 2 := row 2 * pivot - row 1 * a21), worked by hand:
   --  [[2, 1, 1], [0, 3, 4]]: row 2 = [0, 3, 4] * 2 - row 1 * 0 = [0, 6, 8].
   declare
      R2 : constant Reduced_Matrix := Eliminate ([[2, 1, 1], [0, 3, 4]]);
   begin
      pragma Assert (R2 (1, 1) = 2 and R2 (1, 2) = 1 and R2 (1, 3) = 1);
      pragma Assert (R2 (2, 1) = 0 and R2 (2, 2) = 6 and R2 (2, 3) = 8);
   end;
   --  a11 = 0, a21 = 3: rows swapped, pivot 3, a21 of the new row 2 is 0:
   --  [[0, 1, 2], [3, 4, 5]] -> row 1 = [3, 4, 5], row 2 = [0, 1, 2] * 3 = [0, 3, 6].
   declare
      R3 : constant Reduced_Matrix := Eliminate ([[0, 1, 2], [3, 4, 5]]);
   begin
      pragma Assert (R3 (1, 1) = 3 and R3 (1, 2) = 4 and R3 (1, 3) = 5);
      pragma Assert (R3 (2, 1) = 0 and R3 (2, 2) = 3 and R3 (2, 3) = 6);
   end;
   Own_Checks;
end Tests;
