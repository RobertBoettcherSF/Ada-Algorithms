pragma SPARK_Mode (On);

package Elevator_Algorithm is
   subtype Floor is Natural range 0 .. 10;

   function Move_One_Step (Current : Floor; Target : Floor) return Floor
     with Post =>
       (if Current < Target then Move_One_Step'Result = Current + 1
        elsif Current > Target then Move_One_Step'Result = Current - 1
        else Move_One_Step'Result = Current);
end Elevator_Algorithm;
