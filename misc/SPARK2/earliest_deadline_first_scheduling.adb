pragma SPARK_Mode (On);

package body Earliest_Deadline_First_Scheduling is
   function Select_Earliest (Deadlines : Deadline_Array) return Job_Id is
      Best : Job_Id := Job_Id'First;
   begin
      for J in Job_Id loop
         if Deadlines (J) < Deadlines (Best) then
            Best := J;
         end if;
      end loop;
      return Best;
   end Select_Earliest;
end Earliest_Deadline_First_Scheduling;
