pragma SPARK_Mode (On);

package body Minimum_Number_Of_Moves_To_Seat is
   function Distance
     (Seat, Student : Seat_Position) return Move_Count is
   begin
      if Seat >= Student then
         return Seat - Student;
      else
         return Student - Seat;
      end if;
   end Distance;
end Minimum_Number_Of_Moves_To_Seat;
