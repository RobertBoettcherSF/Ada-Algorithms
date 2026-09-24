pragma SPARK_Mode (On);

package body Elevator_Algorithm is
   function Move_One_Step (Current : Floor; Target : Floor) return Floor is
   begin
      if Current < Target then
         return Current + 1;
      elsif Current > Target then
         return Current - 1;
      else
         return Current;
      end if;
   end Move_One_Step;
end Elevator_Algorithm;
