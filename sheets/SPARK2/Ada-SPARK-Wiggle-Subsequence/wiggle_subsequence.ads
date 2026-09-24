pragma Ada_2022;
pragma SPARK_Mode (On);
package Wiggle_Subsequence is
   subtype Value is Integer range -32 .. 32;
   subtype Length is Natural range 0 .. 3;
   function Wiggle_Length (First, Second, Third : Value) return Length
     with Global => null;
end Wiggle_Subsequence;
