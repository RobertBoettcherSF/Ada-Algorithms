pragma Ada_2022;
pragma SPARK_Mode (On);
package Non_Overlapping_Intervals is
   subtype Count is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Bounds is array (Index) of Integer;

   function Kept_Intervals (Starts : Bounds; Finishes : Bounds; N : Count) return Count
     with Pre => N > 0,
          Post => Kept_Intervals'Result = N;
end Non_Overlapping_Intervals;
