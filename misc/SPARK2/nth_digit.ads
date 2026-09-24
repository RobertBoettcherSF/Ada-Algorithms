pragma SPARK_Mode (On);

package Nth_Digit is
   --  The bounded prefix keeps this educational stub deliberately small.
   subtype Position is Natural range 0 .. 9;
   subtype Digit is Natural range 0 .. 9;

   function Digit_At (Index : Position) return Digit
     with Global => null;
end Nth_Digit;
