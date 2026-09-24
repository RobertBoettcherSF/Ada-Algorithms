pragma SPARK_Mode (On);

package Fizz_Buzz is
   subtype Input is Positive range 1 .. 100;
   type Result is (Number, Fizz, Buzz, FizzBuzz);

   function Classify (Value : Input) return Result
     with Global => null;
end Fizz_Buzz;
