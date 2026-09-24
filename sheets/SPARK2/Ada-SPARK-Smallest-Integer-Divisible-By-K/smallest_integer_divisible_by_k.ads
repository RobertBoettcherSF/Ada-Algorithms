pragma SPARK_Mode (On);

package Smallest_Integer_Divisible_By_K is
   subtype Divisor is Positive range 1 .. 50;
   subtype Length is Natural range 0 .. 50;

   function Smallest_Length (K : Divisor) return Length
     with Global => null;
end Smallest_Integer_Divisible_By_K;
