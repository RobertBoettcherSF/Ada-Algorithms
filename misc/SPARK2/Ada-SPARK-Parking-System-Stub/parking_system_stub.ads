pragma SPARK_Mode (On);

package Parking_System_Stub is
   Capacity : constant := 4;
   subtype Slots is Natural range 0 .. Capacity;
   type Vehicle_Type is (Compact, Large, Truck);
   type Parking_Capacity is record
      Compact_Slots : Slots;
      Large_Slots : Slots;
      Truck_Slots : Slots;
   end record;

   function Can_Park
     (Available : Parking_Capacity; Vehicle : Vehicle_Type) return Boolean;
end Parking_System_Stub;
