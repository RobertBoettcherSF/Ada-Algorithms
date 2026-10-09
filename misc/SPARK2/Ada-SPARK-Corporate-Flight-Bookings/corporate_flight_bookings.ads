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

   --  Corporate flight bookings: flights 1 .. N, each booking reserves
   --  Seats seats on every flight First .. Last; Flight_Totals gives the
   --  seats reserved on each flight (difference array + prefix sum).
   Max_Flights  : constant := 20_000;
   Max_Bookings : constant := 20_000;
   Max_Seats    : constant := 10_000;
   subtype Flight is Positive range 1 .. Max_Flights;
   subtype Booking_Index is Positive range 1 .. Max_Bookings;
   subtype Booking_Count is Natural range 0 .. Max_Bookings;
   subtype Seat_Count is Natural range 0 .. Max_Seats;
   --  At most Max_Bookings * Max_Seats = 2 * 10**8 seats on one flight.
   subtype Flight_Total is Natural range 0 .. Max_Bookings * Max_Seats;
   type Request is record
      First, Last : Flight;
      Seats       : Seat_Count;
   end record;
   type Request_List is array (Booking_Index range <>) of Request;
   type Total_Array is array (Flight range <>) of Flight_Total;

   --  Seats on flight F from the bookings R'First .. J (proof only).
   function Covered (R : Request_List; F : Flight; J : Booking_Count) return Long_Long_Integer
     with Ghost, Pre => R'First = 1 and then R'Last >= 0 and then J <= R'Last,
          Post => Covered'Result in 0 .. Long_Long_Integer (J) * Max_Seats,
          Subprogram_Variant => (Decreases => J);

   function Flight_Totals (R : Request_List; N : Flight) return Total_Array
     with Global => null,
          Pre  => R'First = 1 and then R'Last >= 0
                  and then (for all J in R'Range => R (J).First <= R (J).Last and then R (J).Last <= N),
          Post => Flight_Totals'Result'First = 1 and then Flight_Totals'Result'Last = N
                  and then (for all F in 1 .. N =>
                              Long_Long_Integer (Flight_Totals'Result (F)) = Covered (R, F, R'Last));
private
   function Covered (R : Request_List; F : Flight; J : Booking_Count) return Long_Long_Integer is
     (if J = 0 then 0
      else Covered (R, F, J - 1)
           + (if R (J).First <= F and then F <= R (J).Last then Long_Long_Integer (R (J).Seats) else 0));
end Corporate_Flight_Bookings;
