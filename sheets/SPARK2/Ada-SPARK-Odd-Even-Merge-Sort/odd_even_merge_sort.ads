pragma Ada_2022;

package Odd_Even_Merge_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 31;
   type Input_Array is array (Index) of Value;

   function Sort (Input : Input_Array) return Input_Array
     with Global => null,
          Post => (for all I in Index => Sort'Result (I) in Value);
end Odd_Even_Merge_Sort;
