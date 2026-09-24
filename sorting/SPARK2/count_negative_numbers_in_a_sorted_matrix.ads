pragma SPARK_Mode (On);

package Count_Negative_Numbers_In_A_Sorted_Matrix is
   subtype Value is Integer range -8 .. 8;
   type Matrix is array (1 .. 4, 1 .. 4) of Value;
   subtype Count is Natural range 0 .. 16;

   function Count_Negatives (M : Matrix) return Count;
end Count_Negative_Numbers_In_A_Sorted_Matrix;
