pragma SPARK_Mode (On);

package body Add_Digits is
   function Digital_Root (Value : Input) return Digit is
   begin
      if Value = 0 then
         return 0;
      else
         return Digit (1 + (Value - 1) mod 9);
      end if;
   end Digital_Root;
end Add_Digits;
