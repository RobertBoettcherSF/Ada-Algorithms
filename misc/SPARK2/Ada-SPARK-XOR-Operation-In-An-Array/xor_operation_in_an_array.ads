pragma Ada_2022;
with Interfaces;
package XOR_Operation_In_An_Array with SPARK_Mode => On is
   subtype Word is Interfaces.Unsigned_32;
   subtype Length is Natural range 0 .. 8;
   function Compute (Start : Word; N : Length) return Word
     with Global => null;
end XOR_Operation_In_An_Array;
