pragma SPARK_Mode (On);

package body Cheapest_Flights with SPARK_Mode => On is
   function Cheapest_Direct
     (Flights : Network; From, To : Airport) return Fare is
   begin
      if From = To then
         return 0;
      else
         return Flights (From, To);
      end if;
   end Cheapest_Direct;
end Cheapest_Flights;
