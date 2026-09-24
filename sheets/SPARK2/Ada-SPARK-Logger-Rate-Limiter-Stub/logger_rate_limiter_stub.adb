pragma SPARK_Mode (On);

package body Logger_Rate_Limiter_Stub is
   function Allowed
     (Last_Message : Timestamp; Now : Timestamp; Interval : Cooldown)
      return Boolean is
   begin
      return Now - Last_Message >= Interval;
   end Allowed;
end Logger_Rate_Limiter_Stub;
