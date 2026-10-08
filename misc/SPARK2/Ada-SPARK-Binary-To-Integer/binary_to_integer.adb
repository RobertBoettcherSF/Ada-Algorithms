pragma Ada_2022;
with Interfaces;
package body Binary_To_Integer with SPARK_Mode => On is
   use type Word;
   function From_Binary_Nibble (B3, B2, B1, B0 : Bit) return Word is
   begin
      return Word (B3) * 8 + Word (B2) * 4 + Word (B1) * 2 + Word (B0);
   end From_Binary_Nibble;
end Binary_To_Integer;
