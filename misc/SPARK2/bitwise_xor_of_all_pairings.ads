pragma Ada_2022;
with Interfaces;
package Bitwise_XOR_Of_All_Pairings with SPARK_Mode => On is
   subtype Word is Interfaces.Unsigned_8;
   type Triple is array (1 .. 3) of Word;
   function Pairings_Xor (Left, Right : Triple) return Word
     with Global => null;
end Bitwise_XOR_Of_All_Pairings;
