pragma SPARK_Mode (On);

package Fibonacci_DP is
   subtype Input is Natural range 0 .. 10;
   subtype Result is Integer range 0 .. 55;

   function Compute (N : Input) return Result;
end Fibonacci_DP;
