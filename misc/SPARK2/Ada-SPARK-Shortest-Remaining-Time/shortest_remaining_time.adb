pragma SPARK_Mode (On);

package body Shortest_Remaining_Time is
   function Select_Shortest (Remaining : Remaining_Array) return Job_Id is
      Best : Job_Id := Job_Id'First;
   begin
      for J in Job_Id loop
         if Remaining (J) < Remaining (Best) then
            Best := J;
         end if;
      end loop;
      return Best;
   end Select_Shortest;

   procedure Run_One_Tick (Remaining : in out Remaining_Time) is
   begin
      if Remaining > 0 then
         Remaining := Remaining - 1;
      end if;
   end Run_One_Tick;
end Shortest_Remaining_Time;
