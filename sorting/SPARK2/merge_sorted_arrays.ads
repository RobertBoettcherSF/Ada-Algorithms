pragma Ada_2022;

package Merge_Sorted_Arrays with SPARK_Mode => On is
   Left_Length : constant := 3;
   Right_Length : constant := 3;
   subtype Input_Index is Positive range 1 .. Left_Length;
   subtype Output_Index is Positive range 1 .. Left_Length + Right_Length;
   subtype Value is Integer range -10 .. 10;
   type Input_Array is array (Input_Index) of Value;
   type Output_Array is array (Output_Index) of Value;

   function Merge (Left, Right : Input_Array) return Output_Array
     with Global => null;
end Merge_Sorted_Arrays;
