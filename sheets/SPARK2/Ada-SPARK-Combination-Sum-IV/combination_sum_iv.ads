pragma Ada_2022;

package Combination_Sum_IV with SPARK_Mode => On is
   subtype Target is Natural range 0 .. 12;
   function Count_Ordered_Ways (N : Target) return Natural with Global => null;
end Combination_Sum_IV;
