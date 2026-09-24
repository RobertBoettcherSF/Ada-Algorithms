pragma SPARK_Mode (On);

package Modular_Exponentiation is
   subtype Base is Natural range 0 .. 100;
   subtype Exponent is Natural range 0 .. 16;
   subtype Modulus is Positive range 1 .. 101;
   subtype Result is Natural range 0 .. 100;

   function Power (Value : Base; Exp : Exponent; Modulo : Modulus) return Result
     with Global => null;
end Modular_Exponentiation;
