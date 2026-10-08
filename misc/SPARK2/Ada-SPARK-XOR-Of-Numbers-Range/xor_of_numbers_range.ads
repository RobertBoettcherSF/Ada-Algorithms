pragma Ada_2022;
with Interfaces;
package Xor_Of_Numbers_Range with SPARK_Mode => On is
   subtype Word is Interfaces.Unsigned_32;
   function Xor_0_To (Value : Word) return Word with Global => null;
end Xor_Of_Numbers_Range;
