pragma Ada_2022;

package Combination_Sum with SPARK_Mode => On is
   subtype Target is Integer range 0 .. 12;
   subtype Combination_Count is Integer range 1 .. 77;

   function Count_Combinations (Value : Target) return Combination_Count
     with Global => null;
end Combination_Sum;
