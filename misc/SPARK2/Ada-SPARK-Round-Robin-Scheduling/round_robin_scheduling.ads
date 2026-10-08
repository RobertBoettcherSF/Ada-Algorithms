pragma SPARK_Mode (On);

package Round_Robin_Scheduling is
   subtype Remaining_Time is Natural range 0 .. 100;
   subtype Quantum is Positive range 1 .. 10;

   procedure Run_Quantum
     (Remaining : in out Remaining_Time;
      Q         : Quantum;
      Executed  : out Remaining_Time)
     with Post => Executed <= Q
       and then Executed <= Remaining'Old
       and then Remaining = Remaining'Old - Executed;
end Round_Robin_Scheduling;
