pragma Ada_2022;

package Plus_One with SPARK_Mode => On is
   Length : constant := 4;
   subtype Index is Positive range 1 .. Length;
   subtype Digit is Integer range 0 .. 9;
   type Digit_Array is array (Index) of Digit;

   function Increment (Input : Digit_Array) return Digit_Array
     with Global => null;
end Plus_One;
