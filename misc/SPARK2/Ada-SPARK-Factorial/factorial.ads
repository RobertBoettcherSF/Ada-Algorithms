pragma SPARK_Mode (On);

package Factorial is
   subtype Input is Natural range 0 .. 12;
   subtype Result is Positive range 1 .. 479_001_600;

   function Compute (N : Input) return Result
     with Global => null;
end Factorial;
