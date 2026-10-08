pragma Ada_2022;
pragma SPARK_Mode (On);
package Merge_Intervals is
   subtype Count is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Bounds is array (Index) of Integer;

   function Merged_Intervals (Starts : Bounds; Finishes : Bounds; N : Count) return Count
     with Pre => N > 0,
          Post => Merged_Intervals'Result = N;
end Merge_Intervals;
