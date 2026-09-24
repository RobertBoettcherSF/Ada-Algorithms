with Ada.Assertions; use Ada.Assertions;
with Corporate_Flight_Bookings; use Corporate_Flight_Bookings;

procedure Tests is
   Empty : constant Booking := (First => 1, Last => 1, Count => 0);
   B : Bookings := [others => Empty];
begin
   B (1) := (First => 1, Last => 3, Count => 2);
   B (2) := (First => 2, Last => 4, Count => 1);
   Assert (Booked_Seats (B) = 3);
end Tests;
