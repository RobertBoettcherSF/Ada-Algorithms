pragma Ada_2022;
pragma SPARK_Mode (On);
package Broken_Calculator is
   subtype Value is Natural range 0 .. 32;
   --  The calculator only doubles (X -> 2X) or decrements (X -> X - 1); from 0 nothing but 0 is
   --  reachable, so start and target are at least 1 (the standard statement).
   subtype Operand is Value range 1 .. Value'Last;
   function Minimum_Operations (Start, Target : Operand) return Value
     with Global => null;
end Broken_Calculator;
