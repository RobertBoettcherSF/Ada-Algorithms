pragma Ada_2022;
with Interfaces;
package Number_Of_1_Bits_In_Range with SPARK_Mode => On is
   subtype Word is Interfaces.Unsigned_32;
   function Count_One_Bits (Value : Word) return Word with Global => null;
end Number_Of_1_Bits_In_Range;
