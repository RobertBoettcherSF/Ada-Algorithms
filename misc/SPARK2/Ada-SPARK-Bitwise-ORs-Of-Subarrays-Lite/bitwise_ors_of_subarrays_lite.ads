pragma Ada_2022;
with Interfaces;
package Bitwise_Ors_Of_Subarrays_Lite with SPARK_Mode => On is
   subtype Word is Interfaces.Unsigned_32;
   function Or_Of_Two (Left, Right : Word) return Word
     with Global => null;
   function Or_Of_Three (A, B, C : Word) return Word
     with Global => null;
end Bitwise_Ors_Of_Subarrays_Lite;
