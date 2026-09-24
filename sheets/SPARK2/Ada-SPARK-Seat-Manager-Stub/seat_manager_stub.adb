pragma SPARK_Mode (On);

package body Seat_Manager_Stub is
   function Reserve_First (Taken : Seat_Array) return Seat_Number is
      Result : Seat_Number := 0;
   begin
      for I in Seat_Index loop
         if Result = 0 and then not Taken (I) then
            Result := I;
         end if;
      end loop;
      return Result;
   end Reserve_First;
end Seat_Manager_Stub;
