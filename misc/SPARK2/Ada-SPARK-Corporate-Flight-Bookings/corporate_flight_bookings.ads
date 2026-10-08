pragma Ada_2022;

package Corporate_Flight_Bookings with SPARK_Mode => On is
   Size : constant := 8;
   subtype Index is Positive range 1 .. Size;
   subtype Seats is Integer range 0 .. 4;
   subtype Total_Seats is Integer range 0 .. Size * Seats'Last;
   type Booking is record
      First : Index;
      Last  : Index;
      Count : Seats;
   end record;
   type Bookings is array (Index) of Booking;

   function Booked_Seats (B : Bookings) return Total_Seats
     with Global => null;
end Corporate_Flight_Bookings;
