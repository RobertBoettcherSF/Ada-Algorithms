pragma Ada_2022;
package body Count_Square_Submatrices_With_All_Ones with SPARK_Mode => On is
   function All_2 (A : Matrix; R, C : Index) return Boolean
     with Pre => R <= Index'Last - 1 and C <= Index'Last - 1 is
   begin
      return A (R, C) = 1 and A (R + 1, C) = 1 and A (R, C + 1) = 1 and A (R + 1, C + 1) = 1;
   end All_2;
   function All_3 (A : Matrix; R, C : Index) return Boolean
     with Pre => R <= Index'Last - 2 and C <= Index'Last - 2 is
   begin
      return All_2 (A, R, C) and All_2 (A, R + 1, C) and All_2 (A, R, C + 1) and A (R + 2, C + 2) = 1;
   end All_3;
   function All_4 (A : Matrix) return Boolean is
   begin
      return All_3 (A, 1, 1) and A (1, 4) = 1 and A (2, 4) = 1 and A (3, 4) = 1 and A (4, 1) = 1 and A (4, 2) = 1 and A (4, 3) = 1 and A (4, 4) = 1;
   end All_4;
   function Count_Squares (A : Matrix) return Long_Long_Integer is
   begin
      return Boolean'Pos (A (1, 1) = 1) + Boolean'Pos (A (1, 2) = 1) + Boolean'Pos (A (1, 3) = 1) + Boolean'Pos (A (1, 4) = 1) + Boolean'Pos (A (2, 1) = 1) + Boolean'Pos (A (2, 2) = 1) + Boolean'Pos (A (2, 3) = 1) + Boolean'Pos (A (2, 4) = 1) + Boolean'Pos (A (3, 1) = 1) + Boolean'Pos (A (3, 2) = 1) + Boolean'Pos (A (3, 3) = 1) + Boolean'Pos (A (3, 4) = 1) + Boolean'Pos (A (4, 1) = 1) + Boolean'Pos (A (4, 2) = 1) + Boolean'Pos (A (4, 3) = 1) + Boolean'Pos (A (4, 4) = 1) + Boolean'Pos (All_2 (A, 1, 1)) + Boolean'Pos (All_2 (A, 1, 2)) + Boolean'Pos (All_2 (A, 1, 3)) + Boolean'Pos (All_2 (A, 2, 1)) + Boolean'Pos (All_2 (A, 2, 2)) + Boolean'Pos (All_2 (A, 2, 3)) + Boolean'Pos (All_2 (A, 3, 1)) + Boolean'Pos (All_2 (A, 3, 2)) + Boolean'Pos (All_2 (A, 3, 3)) + Boolean'Pos (All_3 (A, 1, 1)) + Boolean'Pos (All_3 (A, 1, 2)) + Boolean'Pos (All_3 (A, 2, 1)) + Boolean'Pos (All_3 (A, 2, 2)) + Boolean'Pos (All_4 (A));
   end Count_Squares;
end Count_Square_Submatrices_With_All_Ones;
