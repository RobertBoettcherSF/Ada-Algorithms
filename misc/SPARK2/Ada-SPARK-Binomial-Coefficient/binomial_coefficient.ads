pragma SPARK_Mode (On);

package Binomial_Coefficient is
   --  Failing-test scaffold: the range is widened to N <= 30 so the test
   --  compiles; the table below still stops at N = 10.
   subtype Input is Natural range 0 .. 30;
   subtype Result is Natural range 0 .. 155_117_520;

   function Choose (N, K : Input) return Result
     with Global => null;
end Binomial_Coefficient;
