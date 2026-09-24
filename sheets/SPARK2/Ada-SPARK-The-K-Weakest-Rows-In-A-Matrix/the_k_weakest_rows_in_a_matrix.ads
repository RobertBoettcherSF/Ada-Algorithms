pragma SPARK_Mode (On);

package The_K_Weakest_Rows_In_A_Matrix is
   subtype Cell is Integer range 0 .. 1;
   type Matrix is array (1 .. 4, 1 .. 4) of Cell;
   subtype Row_Index is Positive range 1 .. 4;

   function Weakest_Row (M : Matrix) return Row_Index;
end The_K_Weakest_Rows_In_A_Matrix;
