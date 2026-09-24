pragma Ada_2022;
with Interfaces;
package Sort_Integers_By_The_Number_Of_1_Bits with SPARK_Mode => On is
   subtype Word is Interfaces.Unsigned_32;
   function Bit_Count (Value : Word) return Word with Global => null;
end Sort_Integers_By_The_Number_Of_1_Bits;
