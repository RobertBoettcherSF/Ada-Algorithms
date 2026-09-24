pragma SPARK_Mode (On);

package body Rate_Monotonic_Scheduling is
   function Highest_Priority (Periods : Period_Array) return Task_Id is
      Best : Task_Id := Task_Id'First;
   begin
      for T in Task_Id loop
         if Periods (T) < Periods (Best) then
            Best := T;
         end if;
      end loop;
      return Best;
   end Highest_Priority;
end Rate_Monotonic_Scheduling;
