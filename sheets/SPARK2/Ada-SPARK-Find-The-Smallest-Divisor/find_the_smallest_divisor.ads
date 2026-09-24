pragma Ada_2022;

package Find_The_Smallest_Divisor with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Positive range 1 .. 1_000;
   subtype Divisor is Positive range 1 .. 1_000;
   subtype Threshold is Positive range 1 .. 8_000;
   type Value_Array is array (Index) of Value;

   function Smallest_Divisor
     (Values : Value_Array; Limit : Threshold) return Divisor
     with Global => null;
end Find_The_Smallest_Divisor;
