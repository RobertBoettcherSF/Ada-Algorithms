pragma SPARK_Mode (On);

package body Parking_System_Stub is
   function Can_Park
     (Available : Parking_Capacity; Vehicle : Vehicle_Type) return Boolean is
   begin
      case Vehicle is
         when Compact =>
            return Available.Compact_Slots > 0;
         when Large =>
            return Available.Large_Slots > 0;
         when Truck =>
            return Available.Truck_Slots > 0;
      end case;
   end Can_Park;
end Parking_System_Stub;
