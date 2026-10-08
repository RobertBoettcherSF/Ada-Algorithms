pragma SPARK_Mode (On);

package Minimum_Number_Of_Moves_To_Seat is
   subtype Seat_Position is Natural range 0 .. 32;
   subtype Move_Count is Natural range 0 .. 32;

   function Distance
     (Seat, Student : Seat_Position) return Move_Count
     with Global => null,
          Post => Distance'Result <= Move_Count'Last;
end Minimum_Number_Of_Moves_To_Seat;
