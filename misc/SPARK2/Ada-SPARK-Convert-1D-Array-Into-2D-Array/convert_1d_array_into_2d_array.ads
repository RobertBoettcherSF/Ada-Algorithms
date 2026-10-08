pragma SPARK_Mode (On);

package Convert_1D_Array_Into_2D_Array is
   subtype Value is Integer range -32 .. 32;
   type One_Dimensional_Array is array (1 .. 4) of Value;
   type Two_Dimensional_Array is array (1 .. 2, 1 .. 2) of Value;

   function Convert (A : One_Dimensional_Array) return Two_Dimensional_Array;
end Convert_1D_Array_Into_2D_Array;
