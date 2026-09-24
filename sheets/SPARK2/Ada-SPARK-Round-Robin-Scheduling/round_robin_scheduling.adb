pragma SPARK_Mode (On);

package body Round_Robin_Scheduling is
   procedure Run_Quantum
     (Remaining : in out Remaining_Time;
      Q         : Quantum;
      Executed  : out Remaining_Time) is
   begin
      if Remaining < Q then
         Executed := Remaining;
         Remaining := 0;
      else
         Executed := Q;
         Remaining := Remaining - Q;
      end if;
   end Run_Quantum;
end Round_Robin_Scheduling;
