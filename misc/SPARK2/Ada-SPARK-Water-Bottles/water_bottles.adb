pragma SPARK_Mode (On);

package body Water_Bottles is
   function Total_Bottles
     (Full_Bottles : Bottle_Count; Exchange : Exchange_Rate)
      return Natural is
   begin
      if Full_Bottles = 0 then
         return 0;
      else
         return Full_Bottles + (Full_Bottles - 1) / (Exchange - 1);
      end if;
   end Total_Bottles;
end Water_Bottles;
