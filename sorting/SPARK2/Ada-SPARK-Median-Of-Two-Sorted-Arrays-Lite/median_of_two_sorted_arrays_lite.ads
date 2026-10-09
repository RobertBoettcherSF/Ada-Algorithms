pragma Ada_2022;

package Median_Of_Two_Sorted_Arrays_Lite with SPARK_Mode => On is
   Length : constant := 16;
   subtype Index is Positive range 1 .. Length;
   subtype Combined_Index is Positive range 1 .. 2 * Length;
   subtype Value is Integer range 0 .. 100;
   type Input_Array is array (Index) of Value;

   type Median_Result is record
      Median : Value;     --  mean of the two middle values, rounded down
      Probes : Natural;   --  comparisons of two values
   end record;

   function Median (Left : Input_Array; Right : Input_Array) return Median_Result
     with Global => null;
end Median_Of_Two_Sorted_Arrays_Lite;
