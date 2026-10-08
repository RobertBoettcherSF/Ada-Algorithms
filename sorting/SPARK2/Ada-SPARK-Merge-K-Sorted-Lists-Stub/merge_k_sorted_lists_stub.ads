pragma Ada_2022;

package Merge_K_Sorted_Lists_Stub with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 12;
   subtype Value is Integer range 0 .. 100;
   type Input_Array is array (Index) of Value;

   function Merge_K (Input : Input_Array) return Input_Array with Global => null;
end Merge_K_Sorted_Lists_Stub;
