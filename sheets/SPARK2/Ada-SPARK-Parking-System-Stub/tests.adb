pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Parking_System_Stub; use Parking_System_Stub;

procedure Tests is
   Available : constant Parking_Capacity :=
     (Compact_Slots => 1, Large_Slots => 0, Truck_Slots => 2);
begin
   if not Can_Park (Available, Compact) then raise Program_Error; end if;
   if Can_Park (Available, Large) then raise Program_Error; end if;
   if not Can_Park (Available, Truck) then raise Program_Error; end if;
   Put_Line ("Parking System: PASS");
end Tests;
