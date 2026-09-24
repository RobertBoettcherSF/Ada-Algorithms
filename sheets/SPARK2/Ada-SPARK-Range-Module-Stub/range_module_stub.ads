pragma SPARK_Mode (On);

package Range_Module_Stub is
   subtype Coordinate is Integer range 0 .. 100_000;
   subtype Range_Count is Natural range 0 .. 32;
   type Interval is record
      First : Coordinate;
      Last  : Coordinate;
   end record;
   type Interval_Array is array (Positive range 1 .. 32) of Interval;

   function Covers
     (Ranges : Interval_Array; Length : Range_Count;
      Query_First : Coordinate; Query_Last : Coordinate) return Boolean
     with Pre => Query_First <= Query_Last and then Length <= Ranges'Length
       and then (for all I in Ranges'First .. Ranges'Last =>
                   (if I <= Length then Ranges (I).First <= Ranges (I).Last)),
          Global => null;
end Range_Module_Stub;
