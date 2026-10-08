pragma Ada_2022;
pragma SPARK_Mode (On);
package Maximum_Units_On_A_Truck is
   subtype Count is Natural range 0 .. 32;
   subtype Total_Units is Natural range 0 .. 1024;
   function Max_Units (Boxes, Units_Per_Box, Truck_Capacity : Count) return Total_Units
     with Global => null;
end Maximum_Units_On_A_Truck;
