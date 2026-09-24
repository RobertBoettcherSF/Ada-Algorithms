pragma SPARK_Mode (On);

package Recent_Counter is
   subtype Timestamp is Integer range 0 .. 100_000;
   subtype Request_Count is Natural range 0 .. 32;
   type Timestamp_Array is array (Positive range 1 .. 32) of Timestamp;

   function Count_Recent
     (Requests : Timestamp_Array;
      Length   : Request_Count;
      Current  : Timestamp) return Request_Count
     with Pre => Length <= Requests'Length
       and then (for all I in Requests'First .. Requests'Last =>
                   (if I <= Length then Requests (I) <= Current)),
          Global => null;
end Recent_Counter;
