pragma SPARK_Mode (On);

package Fibonacci_Number is
   subtype Input is Natural range 0 .. 32;
   subtype Result is Natural range 0 .. 10_000_000;

   function Compute (N : Input) return Result;
end Fibonacci_Number;
