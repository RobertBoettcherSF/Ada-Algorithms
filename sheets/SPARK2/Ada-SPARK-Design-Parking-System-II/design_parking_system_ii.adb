pragma SPARK_Mode (On);
package body Design_Parking_System_II is
   function Create (Small_Spaces, Medium_Spaces, Large_Spaces : Capacity) return Parking is
   begin
      return (Small_Free => Small_Spaces, Medium_Free => Medium_Spaces, Large_Free => Large_Spaces);
   end Create;
   procedure Add_Car (P : in out Parking; K : Car_Kind) is
   begin
      case K is
         when Small => if P.Small_Free > 0 then P.Small_Free := P.Small_Free - 1; end if;
         when Medium => if P.Medium_Free > 0 then P.Medium_Free := P.Medium_Free - 1; end if;
         when Large => if P.Large_Free > 0 then P.Large_Free := P.Large_Free - 1; end if;
      end case;
   end Add_Car;
   function Remaining (P : Parking; K : Car_Kind) return Capacity is
   begin
      case K is
         when Small => return P.Small_Free;
         when Medium => return P.Medium_Free;
         when Large => return P.Large_Free;
      end case;
   end Remaining;
end Design_Parking_System_II;
