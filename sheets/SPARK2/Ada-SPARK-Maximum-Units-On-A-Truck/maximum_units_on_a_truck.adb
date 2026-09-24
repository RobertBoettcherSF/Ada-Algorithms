pragma Ada_2022;
pragma SPARK_Mode (On);
package body Maximum_Units_On_A_Truck is
   function Max_Units (Boxes, Units_Per_Box, Truck_Capacity : Count) return Total_Units is
      Loaded : Count;
   begin
      if Boxes < Truck_Capacity then Loaded := Boxes; else Loaded := Truck_Capacity; end if;
      return Loaded * Units_Per_Box;
   end Max_Units;
end Maximum_Units_On_A_Truck;
