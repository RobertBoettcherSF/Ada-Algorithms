pragma Ada_2022;
package body XOR_Operation_In_An_Array with SPARK_Mode => On is
   use type Word;
   function Compute (Start : Word; N : Length) return Word is
      Result : Word := 0;
   begin
      for I in Length loop
         if I < N then
            Result := Result xor (Start + Word (2 * I));
         end if;
      end loop;
      return Result;
   end Compute;
end XOR_Operation_In_An_Array;
