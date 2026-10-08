pragma SPARK_Mode (On);

package Subtract_Product_Sum_Digits is
   subtype Input is Natural range 0 .. 1_000_000_000;
   subtype Answer is Long_Long_Integer range -90 .. Long_Long_Integer'Last;

   function Difference (Value : Input) return Answer
     with Global => null;
end Subtract_Product_Sum_Digits;
