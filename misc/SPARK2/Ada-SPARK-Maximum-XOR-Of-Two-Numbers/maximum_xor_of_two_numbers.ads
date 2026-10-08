pragma Ada_2022;
with Interfaces;
package Maximum_Xor_Of_Two_Numbers with SPARK_Mode => On is
   subtype Word is Interfaces.Unsigned_32;
   function Maximum_Xor (Left, Right : Word) return Word
     with Global => null;
   function Maximum_Xor (A, B, C : Word) return Word
     with Global => null;
end Maximum_Xor_Of_Two_Numbers;
