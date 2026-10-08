pragma SPARK_Mode (On);
package Design_Parking_System_II is
   subtype Capacity is Natural range 0 .. 4;
   type Car_Kind is (Small, Medium, Large);
   type Parking is private;
   function Create (Small_Spaces, Medium_Spaces, Large_Spaces : Capacity) return Parking
     with Global => null;
   procedure Add_Car (P : in out Parking; K : Car_Kind) with Global => null;
   function Remaining (P : Parking; K : Car_Kind) return Capacity with Global => null;
private
   type Parking is record
      Small_Free : Capacity := 0;
      Medium_Free : Capacity := 0;
      Large_Free : Capacity := 0;
   end record;
end Design_Parking_System_II;
