pragma SPARK_Mode (On);

package body Fizz_Buzz is
   function Classify (Value : Input) return Result is
   begin
      if Value mod 15 = 0 then
         return FizzBuzz;
      elsif Value mod 3 = 0 then
         return Fizz;
      elsif Value mod 5 = 0 then
         return Buzz;
      else
         return Number;
      end if;
   end Classify;
end Fizz_Buzz;
