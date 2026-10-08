pragma Ada_2022;

package Guess_Number_Higher_Or_Lower with SPARK_Mode => On is
   Limit : constant := 32;
   subtype Number is Positive range 1 .. Limit;

   function Guess_Number (Secret : Number) return Number
     with Global => null;
end Guess_Number_Higher_Or_Lower;
