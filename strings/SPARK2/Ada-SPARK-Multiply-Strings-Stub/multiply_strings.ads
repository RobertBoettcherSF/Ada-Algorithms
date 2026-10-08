pragma SPARK_Mode (On);

package Multiply_Strings is
   subtype Number is Natural range 0 .. 9_999;
   subtype Product is Natural range 0 .. 100_000_000;

   function Multiply (Left, Right : Number) return Product
     with Global => null;
end Multiply_Strings;
