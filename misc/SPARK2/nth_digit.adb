pragma SPARK_Mode (On);

package body Nth_Digit is
   function Digit_At (Index : Position) return Digit is
   begin
      if Index < 9 then
         return Index + 1;
      else
         return 1;
      end if;
   end Digit_At;
end Nth_Digit;
