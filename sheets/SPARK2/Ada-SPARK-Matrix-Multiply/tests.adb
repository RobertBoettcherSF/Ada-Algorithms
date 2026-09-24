pragma Ada_2022;
with Matrix_Multiply;
procedure Tests is
   use Matrix_Multiply;
   A : constant Input_Matrix :=
     [[1, 2, 0, 0], [0, 1, 3, 0], [0, 0, 1, 4], [0, 0, 0, 1]];
   B : constant Input_Matrix :=
     [[2, 0, 0, 0], [0, 2, 0, 0], [0, 0, 2, 0], [0, 0, 0, 2]];
   C : constant Matrix := Multiply (A, B);
begin
   pragma Assert (C (1, 1) = 2 and C (1, 2) = 4);
   pragma Assert (C (2, 3) = 6 and C (3, 4) = 8);
end Tests;
