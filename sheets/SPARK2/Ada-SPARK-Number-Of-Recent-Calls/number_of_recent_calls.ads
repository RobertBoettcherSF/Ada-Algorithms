pragma SPARK_Mode (On);

package Number_Of_Recent_Calls is
   subtype Time is Integer range 0 .. 100_000;
   subtype Call_Count is Natural range 0 .. 32;
   type Call_Times is array (Positive range 1 .. 32) of Time;

   function Number_In_Window
     (Calls   : Call_Times;
      Length  : Call_Count;
      At_Time : Time) return Call_Count
     with Pre => Length <= Calls'Length
       and then (for all I in Calls'First .. Calls'Last =>
                   (if I <= Length then Calls (I) <= At_Time)),
          Global => null;
end Number_Of_Recent_Calls;
