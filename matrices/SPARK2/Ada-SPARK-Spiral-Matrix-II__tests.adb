with Spiral_Matrix_II;
procedure Tests is
   Grid : constant Spiral_Matrix_II.Matrix := Spiral_Matrix_II.Generate (3);
begin
   pragma Assert (Grid (1, 1) = 1 and then Grid (1, 3) = 3);
   pragma Assert (Grid (2, 2) = 9);
   pragma Assert (Grid (3, 1) = 7);
end Tests;
