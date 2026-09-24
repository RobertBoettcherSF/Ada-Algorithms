pragma SPARK_Mode (On);

package body Seat_Reservation_Manager is
   function First_Free (Seats : Seat_Array) return Natural is
      Answer : Natural := 0;
   begin
      for I in Seats'Range loop
         if Answer = 0 and then not Seats (I) then
            Answer := I;
         end if;
      end loop;
      return Answer;
   end First_Free;
end Seat_Reservation_Manager;
