pragma Ada_2022;
package Factorial_Trailing_Zeroes with SPARK_Mode => On is
   subtype Number is Natural range 0 .. 10;
   subtype Count is Natural range 0 .. 2;
   function Trailing_Zeroes (N : Number) return Count with Global => null;
end Factorial_Trailing_Zeroes;
