pragma SPARK_Mode (On);

package body Minimum_Operations_To_Make_Increasing is
   function Required_Increase
     (Previous, Current : Value) return Operation_Count is
   begin
      if Current > Previous then
         return 0;
      else
         return Previous - Current + 1;
      end if;
   end Required_Increase;
end Minimum_Operations_To_Make_Increasing;
