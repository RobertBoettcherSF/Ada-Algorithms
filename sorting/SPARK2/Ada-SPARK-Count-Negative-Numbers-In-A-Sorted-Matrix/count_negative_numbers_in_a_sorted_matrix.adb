pragma SPARK_Mode (On);

package body Count_Negative_Numbers_In_A_Sorted_Matrix is
   function Negative (V : Value) return Count is
     (if V < 0 then 1 else 0);

   function Count_Negatives (M : Matrix) return Count is
   begin
      return Negative (M (1, 1)) + Negative (M (1, 2))
        + Negative (M (1, 3)) + Negative (M (1, 4))
        + Negative (M (2, 1)) + Negative (M (2, 2))
        + Negative (M (2, 3)) + Negative (M (2, 4))
        + Negative (M (3, 1)) + Negative (M (3, 2))
        + Negative (M (3, 3)) + Negative (M (3, 4))
        + Negative (M (4, 1)) + Negative (M (4, 2))
        + Negative (M (4, 3)) + Negative (M (4, 4));
   end Count_Negatives;
end Count_Negative_Numbers_In_A_Sorted_Matrix;
