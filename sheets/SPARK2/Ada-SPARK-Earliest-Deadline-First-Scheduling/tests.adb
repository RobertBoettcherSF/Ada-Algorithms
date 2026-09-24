pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Earliest_Deadline_First_Scheduling; use Earliest_Deadline_First_Scheduling;

procedure Tests is
   Deadlines : Deadline_Array := (20, 5, 12, 30);
   Selected  : Job_Id;
begin
   Selected := Select_Earliest (Deadlines);
   if Selected /= 2 then raise Program_Error; end if;
   Put_Line ("EDF: PASS");
end Tests;
