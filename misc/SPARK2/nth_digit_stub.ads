pragma Ada_2022;
package Nth_Digit_Stub with SPARK_Mode => On is
   subtype Position is Natural range 0 .. 9;
   subtype Digit is Natural range 0 .. 9;
   function Nth_Digit (P : Position) return Digit with Global => null;
end Nth_Digit_Stub;
