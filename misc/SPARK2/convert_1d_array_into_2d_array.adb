pragma SPARK_Mode (On);

package body Convert_1D_Array_Into_2D_Array is
   function Convert (A : One_Dimensional_Array) return Two_Dimensional_Array is
   begin
      return ((A (1), A (2)), (A (3), A (4)));
   end Convert;
end Convert_1D_Array_Into_2D_Array;
