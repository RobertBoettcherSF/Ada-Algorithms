pragma Ada_2022;
pragma SPARK_Mode (On);
package Insert_Interval is
   subtype Count is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Bounds is array (Index) of Integer;

   function Inserted_Intervals (Starts : Bounds; Finishes : Bounds; N : Count) return Count
     with Pre => N < 32,
          Post => Inserted_Intervals'Result = N + 1;
end Insert_Interval;
