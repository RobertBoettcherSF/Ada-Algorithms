pragma SPARK_Mode (On);

package Alert_Using_Same_Key_Card_Stub is
   subtype Timestamp is Integer range 0 .. 100_000;
   subtype Swipe_Count is Natural range 0 .. 32;
   type Swipe_Times is array (Positive range 1 .. 32) of Timestamp;

   function Has_Three_Within_Hour
     (Swipes : Swipe_Times; Length : Swipe_Count) return Boolean
     with Pre => Length <= Swipes'Length
       and then (for all I in Swipes'First .. Swipes'Last =>
                   (if I <= Length then
                       (if I < Length then Swipes (I) <= Swipes (I + 1)))),
          Global => null;
end Alert_Using_Same_Key_Card_Stub;
