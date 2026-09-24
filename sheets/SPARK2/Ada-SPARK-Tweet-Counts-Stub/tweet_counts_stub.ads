pragma SPARK_Mode (On);

package Tweet_Counts_Stub is
   subtype Timestamp is Integer range 0 .. 100_000;
   subtype Tweet_Count is Natural range 0 .. 32;
   type Tweet_Times is array (Positive range 1 .. 32) of Timestamp;

   function Count_In_Range
     (Tweets : Tweet_Times;
      Length : Tweet_Count;
      First  : Timestamp;
      Last   : Timestamp) return Tweet_Count
     with Pre => First <= Last and then Length <= Tweets'Length,
          Global => null;
end Tweet_Counts_Stub;
