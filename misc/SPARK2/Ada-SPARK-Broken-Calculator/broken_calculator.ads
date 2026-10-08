pragma Ada_2022;
pragma SPARK_Mode (On);
package Broken_Calculator is
   subtype Value is Natural range 0 .. 32;
   function Minimum_Operations (Start, Target : Value) return Value
     with Global => null;
end Broken_Calculator;
