pragma Ada_2022;
pragma SPARK_Mode (On);
package Minimum_Number_Of_Arrows is
   subtype Count is Natural range 0 .. 32;
   subtype Positive_Count is Count range 1 .. 32;
   function Arrows_Needed (Balloons : Count; Balloons_Per_Arrow : Positive_Count) return Count
     with Global => null;
end Minimum_Number_Of_Arrows;
