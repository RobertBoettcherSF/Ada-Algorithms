pragma Ada_2022;
with Interfaces;
package Hamming_Code with SPARK_Mode => On is
   subtype Nibble is Interfaces.Unsigned_8 range 0 .. 15;
   subtype Codeword is Interfaces.Unsigned_8 range 0 .. 127;

   function Encode (Data : Nibble) return Codeword with Global => null;
   function Decode (Code : Codeword) return Nibble with Global => null;
end Hamming_Code;
