pragma Ada_2022;
with Interfaces;
package Parity_Bits with SPARK_Mode => On is
   subtype Word is Interfaces.Unsigned_32;

   function Even (Value : Word) return Boolean with Global => null;
   function Odd (Value : Word) return Boolean with Global => null;
end Parity_Bits;
