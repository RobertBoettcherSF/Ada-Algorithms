pragma SPARK_Mode (On);

package body Clamp is
   function Value (Input, Lower, Upper : Integer) return Integer is
   begin
      if Input < Lower then
         return Lower;
      elsif Input > Upper then
         return Upper;
      else
         return Input;
      end if;
   end Value;
end Clamp;
