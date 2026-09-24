pragma Ada_2022;
package Largest_Number with SPARK_Mode => On is
   subtype Digit is Natural range 0 .. 9;
   subtype Two_Digit_Number is Natural range 0 .. 99;

   function Largest_Concatenation (Left, Right : Digit)
     return Two_Digit_Number
     with Global => null;
end Largest_Number;
