pragma SPARK_Mode (On);

package Seat_Reservation_Manager is
   Seat_Count : constant := 16;
   type Seat_Array is array (Positive range 1 .. Seat_Count) of Boolean;

   function First_Free (Seats : Seat_Array) return Natural;
end Seat_Reservation_Manager;
