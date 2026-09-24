pragma SPARK_Mode (On);

package Check_If_Matrix_Is_X_Matrix is
   subtype Cell is Integer range 0 .. 1;
   type Matrix is array (1 .. 4, 1 .. 4) of Cell;

   function Is_X_Matrix (M : Matrix) return Boolean;
end Check_If_Matrix_Is_X_Matrix;
