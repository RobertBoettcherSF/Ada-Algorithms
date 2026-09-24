pragma SPARK_Mode (On);

package body Ipo_Lite is
   function Best_Affordable_Profit
     (Initial : Capital; Required : Capital_Array; Gain : Profit_Array)
      return Profit
   is
      Best : Profit := 0;
   begin
      for I in Required'Range loop
         if Required (I) <= Initial and then Gain (I) > Best then
            Best := Gain (I);
         end if;
      end loop;
      return Best;
   end Best_Affordable_Profit;
end Ipo_Lite;
