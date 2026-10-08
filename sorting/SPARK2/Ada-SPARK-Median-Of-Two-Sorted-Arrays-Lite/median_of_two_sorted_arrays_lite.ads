pragma Ada_2022;

package Median_Of_Two_Sorted_Arrays_Lite with SPARK_Mode => On is
   Length : constant := 4;
   subtype Index is Positive range 1 .. Length;
   subtype Combined_Index is Positive range 1 .. 2 * Length;
   subtype Value is Integer range 0 .. 100;
   type Input_Array is array (Index) of Value;

   function Median (Left : Input_Array; Right : Input_Array) return Value
     with Global => null;
end Median_Of_Two_Sorted_Arrays_Lite;
