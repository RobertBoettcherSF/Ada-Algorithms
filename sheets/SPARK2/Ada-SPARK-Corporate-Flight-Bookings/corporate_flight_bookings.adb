pragma Ada_2022;

package body Corporate_Flight_Bookings with SPARK_Mode => On is
   function Booked_Seats (B : Bookings) return Total_Seats is
      Result : Total_Seats := 0;
   begin
      for I in Index loop
         pragma Loop_Invariant (Result <= Seats'Last * (I - Index'First));
         Result := Result + B (I).Count;
      end loop;
      return Result;
   end Booked_Seats;
end Corporate_Flight_Bookings;
