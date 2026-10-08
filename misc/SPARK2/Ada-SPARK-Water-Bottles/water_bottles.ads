pragma SPARK_Mode (On);

package Water_Bottles is
   subtype Bottle_Count is Natural range 0 .. 100;
   subtype Exchange_Rate is Positive range 2 .. 10;

   function Total_Bottles
     (Full_Bottles : Bottle_Count; Exchange : Exchange_Rate)
      return Natural
     with Global => null;
end Water_Bottles;
