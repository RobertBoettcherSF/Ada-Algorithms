pragma Ada_2022;
package body Total_Hamming_Distance with SPARK_Mode => On is
   use type Word;
   function Distance (Left, Right : Word) return Bit_Count is
      Difference : constant Word := Left xor Right;
      Result : Bit_Count := 0;
   begin
      for Position in 0 .. 31 loop
         pragma Loop_Invariant (Result <= Position);
         if (Interfaces.Shift_Right (Difference, Position) and 1) /= 0 then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Distance;
end Total_Hamming_Distance;
