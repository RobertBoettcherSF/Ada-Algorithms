pragma Ada_2022;
with Interfaces;
package Bit_Reversal with SPARK_Mode => On is
   subtype Word is Interfaces.Unsigned_32;

   function Reverse_Bits (Value : Word) return Word with Global => null;
end Bit_Reversal;
