pragma Ada_2022;

package Combination_Sum_III with SPARK_Mode => On is
   subtype Count is Natural range 0 .. 9;
   subtype Target is Natural range 0 .. 45;
   function Feasible (K : Count; N : Target) return Boolean with Global => null;
   function Count_Choices (K : Count; N : Target) return Natural with Global => null;
end Combination_Sum_III;
