pragma Ada_2022;

package Remove_K_Digits with SPARK_Mode => On is
   subtype Position is Positive range 1 .. 8;
   subtype Digit is Integer range 0 .. 9;
   subtype Count is Natural range 0 .. 8;
   type Digit_Array is array (Position) of Digit;

   function Remove_K (Value : Digit_Array; K : Count) return Digit_Array
     with Global => null;
end Remove_K_Digits;
