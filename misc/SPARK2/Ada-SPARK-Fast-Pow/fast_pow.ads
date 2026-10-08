pragma SPARK_Mode (On);

package Fast_Pow is
   subtype Base is Natural range 0 .. 5;
   subtype Exponent is Natural range 0 .. 12;
   subtype Result is Natural range 0 .. 244_140_625;

   function Power (Value : Base; Exp : Exponent) return Result
     with Global => null;
end Fast_Pow;
