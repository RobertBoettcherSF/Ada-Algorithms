pragma Ada_2022;

package Subarray_Sum_Equals_K with SPARK_Mode => On is
   Length : constant := 6;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -5 .. 5;
   subtype Target_Value is Integer range -30 .. 30;
   type Input_Array is array (Index) of Value;

   function Count (Input : Input_Array; Target : Target_Value) return Integer
     with Global => null;
end Subarray_Sum_Equals_K;
