pragma SPARK_Mode (On);

package Tribonacci is
   subtype Input is Natural range 0 .. 10;
   subtype Result is Integer range 0 .. 200;

   function Compute (N : Input) return Result;
end Tribonacci;
