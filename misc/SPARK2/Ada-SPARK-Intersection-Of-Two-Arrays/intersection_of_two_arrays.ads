pragma SPARK_Mode (On);

package Intersection_Of_Two_Arrays is
   subtype Index is Positive range 1 .. 32;
   subtype Count_Type is Natural range 0 .. 32;
   subtype Value is Integer range -1_000 .. 1_000;
   type Values is array (Index) of Value;

   function Count (Left : Values; Right : Values) return Count_Type
     with Global => null;
end Intersection_Of_Two_Arrays;
