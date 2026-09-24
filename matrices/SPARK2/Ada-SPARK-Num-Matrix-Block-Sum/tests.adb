with Num_Matrix_Block_Sum;
procedure Tests is
   use Num_Matrix_Block_Sum;
   A : constant Matrix := ((1, 2, 3, 4), (5, 6, 7, 8), (9, 1, 2, 3), (4, 5, 6, 7));
begin
   pragma Assert (Block_Sum (A, 2, 2, 1) = 36);
   pragma Assert (Block_Sum (A, 1, 1, 0) = 1);
   pragma Assert (Block_Sum (A, 4, 4, 3) = 73);
end Tests;
