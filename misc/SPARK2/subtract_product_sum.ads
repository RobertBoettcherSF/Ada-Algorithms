pragma SPARK_Mode (On);

package Subtract_Product_Sum is
   --  This compact stub handles the two-digit bounded domain.
   subtype Number is Natural range 0 .. 99;
   subtype Result is Integer range -18 .. 81;

   function Difference (Value : Number) return Result
     with Global => null;
end Subtract_Product_Sum;
