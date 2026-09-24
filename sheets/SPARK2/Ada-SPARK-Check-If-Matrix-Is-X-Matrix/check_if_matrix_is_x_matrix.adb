pragma SPARK_Mode (On);

package body Check_If_Matrix_Is_X_Matrix is
   function Is_X_Matrix (M : Matrix) return Boolean is
   begin
      return M (1, 1) = 1 and M (1, 4) = 1
        and M (2, 2) = 1 and M (2, 3) = 1
        and M (3, 2) = 1 and M (3, 3) = 1
        and M (4, 1) = 1 and M (4, 4) = 1
        and M (1, 2) = 0 and M (1, 3) = 0
        and M (2, 1) = 0 and M (2, 4) = 0
        and M (3, 1) = 0 and M (3, 4) = 0
        and M (4, 2) = 0 and M (4, 3) = 0;
   end Is_X_Matrix;
end Check_If_Matrix_Is_X_Matrix;
