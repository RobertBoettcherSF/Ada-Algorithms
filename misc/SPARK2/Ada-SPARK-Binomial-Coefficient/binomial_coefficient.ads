pragma SPARK_Mode (On);

package Binomial_Coefficient is
   subtype Input is Natural range 0 .. 10;
   subtype Result is Natural range 0 .. 252;

   function Choose (N, K : Input) return Result
     with Global => null;
end Binomial_Coefficient;
