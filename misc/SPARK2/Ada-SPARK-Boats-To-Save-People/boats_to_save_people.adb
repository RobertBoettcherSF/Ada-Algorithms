pragma Ada_2022;
package body Boats_To_Save_People with SPARK_Mode => On is
   function Boats_Needed
     (People : People_Count; Capacity : Boat_Capacity) return Boat_Count is
   begin
      if People = 0 then
         return 0;
      else
         return (People + Capacity - 1) / Capacity;
      end if;
   end Boats_Needed;
end Boats_To_Save_People;
