pragma Ada_2022;

package Multiply_Strings_Lite with SPARK_Mode => On is
   subtype Digit is Natural range 0 .. 9;
   subtype Product is Natural range 0 .. 81;

   function Multiply (Left : Digit; Right : Digit) return Product
     with Global => null;
end Multiply_Strings_Lite;
