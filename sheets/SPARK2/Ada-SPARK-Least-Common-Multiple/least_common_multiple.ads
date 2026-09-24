pragma SPARK_Mode (On);

package Least_Common_Multiple is
   subtype Input is Positive range 1 .. 1_000;
   subtype Result is Natural range 0 .. 1_000_000;

   function LCM (A, B : Input) return Result
     with Global => null;
end Least_Common_Multiple;
