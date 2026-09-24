pragma Ada_2022;
package body LZ77
  with SPARK_Mode => On
is
   function Literal_Length (Input : Char_Array) return Length is
      -- A safe baseline encoder: every character is a literal. A future lesson
      -- can replace this count with (distance, length, next) back-references.
      Count : Length := 0;
   begin
      for I in Input'Range loop
         if Count < Length'Last then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Literal_Length;
end LZ77;
