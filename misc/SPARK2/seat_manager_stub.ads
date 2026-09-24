pragma SPARK_Mode (On);

package Seat_Manager_Stub is
   Seat_Count : constant := 4;
   subtype Seat_Index is Positive range 1 .. Seat_Count;
   subtype Seat_Number is Natural range 0 .. Seat_Count;
   type Seat_Array is array (Seat_Index) of Boolean;

   function Reserve_First (Taken : Seat_Array) return Seat_Number;
end Seat_Manager_Stub;
