pragma Ada_2022;
with Interfaces;
package Bitwise_Or_Of_Numbers_Range with SPARK_Mode => On is
   subtype Word is Interfaces.Unsigned_32;
   function Or_0_To (Value : Word) return Word with Global => null;
end Bitwise_Or_Of_Numbers_Range;
