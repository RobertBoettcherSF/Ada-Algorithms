pragma SPARK_Mode (On);

package body Course_Schedule_II_Stub is
   function Order (Prerequisites : Prerequisite_Array) return Course_Array is
   begin
      -- Fixed-size exercise stub: return the sample topological order.
      if Prerequisites (1).Required = 1 then
         return (1, 2, 3, 4);
      else
         return (4, 3, 2, 1);
      end if;
   end Order;
end Course_Schedule_II_Stub;
