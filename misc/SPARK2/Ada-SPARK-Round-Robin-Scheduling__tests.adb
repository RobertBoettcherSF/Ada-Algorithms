pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Round_Robin_Scheduling; use Round_Robin_Scheduling;

procedure Tests is
   Remaining : Remaining_Time := 5;
   Executed  : Remaining_Time;
begin
   Run_Quantum (Remaining, 2, Executed);
   if Remaining /= 3 or else Executed /= 2 then raise Program_Error; end if;
   Run_Quantum (Remaining, 10, Executed);
   if Remaining /= 0 or else Executed /= 3 then raise Program_Error; end if;
   Put_Line ("Round-robin: PASS");
end Tests;
