with Count_Square_Submatrices_With_All_Ones;
procedure Tests is
   use Count_Square_Submatrices_With_All_Ones;
begin
   pragma Assert (Count_Squares (((1, 1, 1, 1), (1, 1, 1, 1), (1, 1, 1, 1), (1, 1, 1, 1))) = 30);
   pragma Assert (Count_Squares (((1, 0, 1, 0), (0, 1, 0, 1), (1, 0, 1, 0), (0, 1, 0, 1))) = 8);
end Tests;
