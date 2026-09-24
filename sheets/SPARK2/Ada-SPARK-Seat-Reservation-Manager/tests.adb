pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Seat_Reservation_Manager; use Seat_Reservation_Manager;

procedure Tests is
   Seats : constant Seat_Array := (True, True, False, True, False, True, True, True,
                                   True, True, True, True, True, True, True, True);
   Full  : constant Seat_Array := (others => True);
begin
   if First_Free (Seats) /= 3 then raise Program_Error; end if;
   if First_Free (Full) /= 0 then raise Program_Error; end if;
   Put_Line ("Seat reservation manager: PASS");
end Tests;
