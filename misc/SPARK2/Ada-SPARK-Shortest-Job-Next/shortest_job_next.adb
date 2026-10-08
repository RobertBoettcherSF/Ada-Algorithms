pragma SPARK_Mode (On);

package body Shortest_Job_Next is
   function Select_Shortest (Bursts : Burst_Array) return Job_Id is
      Best : Job_Id := Job_Id'First;
   begin
      for J in Job_Id loop
         if Bursts (J) < Bursts (Best) then
            Best := J;
         end if;
      end loop;
      return Best;
   end Select_Shortest;
end Shortest_Job_Next;
