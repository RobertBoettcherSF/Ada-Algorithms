pragma SPARK_Mode (On);

package Median_Of_Three is
   subtype Value is Integer range -100 .. 100;
   function Median (A, B, C : Value) return Value;
end Median_Of_Three;
