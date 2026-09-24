pragma SPARK_Mode (On);

package Powx_N is
   subtype Base is Integer range -100 .. 100;
   subtype Exponent is Natural range 0 .. 2;
   subtype Power is Integer range -10_000 .. 10_000;

   function Power_Of (X : Base; N : Exponent) return Power
     with Global => null;
end Powx_N;
