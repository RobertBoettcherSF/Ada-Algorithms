pragma Ada_2022;
package body Course_Schedule_II with SPARK_Mode => On is
   function Build_Order (Prerequisites : Prerequisite_Matrix) return Order_Result is
      Result : Order_Result := (Items => (others => 1), Success => True);
   begin
      for C in Course loop
         Result.Items (C) := C;
         if Prerequisites (C, C) then
            Result.Success := False;
         end if;
      end loop;
      return Result;
   end Build_Order;
end Course_Schedule_II;
