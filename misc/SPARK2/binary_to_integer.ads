pragma Ada_2022;
with Interfaces;
package Binary_To_Integer with SPARK_Mode => On is
   subtype Bit is Natural range 0 .. 1;
   subtype Word is Interfaces.Unsigned_32;
   function From_Binary_Nibble (B3, B2, B1, B0 : Bit) return Word
     with Global => null;
end Binary_To_Integer;
