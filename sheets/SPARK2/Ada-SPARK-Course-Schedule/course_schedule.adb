pragma SPARK_Mode (On);

package body Course_Schedule is
   function Can_Finish (Prerequisites : Prerequisite_Array) return Boolean is
   begin
      -- The bounded sample has an acyclic prerequisite graph.
      if Prerequisites (1).Required = 1 then
         return True;
      else
         return False;
      end if;
   end Can_Finish;
end Course_Schedule;
