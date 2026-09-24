pragma SPARK_Mode (On);

package Greatest_Common_Divisor is
   subtype Input is Positive range 1 .. 1_000;

   function GCD (A, B : Input) return Input
     with Global => null;
end Greatest_Common_Divisor;
