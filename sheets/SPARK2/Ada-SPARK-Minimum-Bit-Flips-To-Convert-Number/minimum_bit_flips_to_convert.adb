pragma Ada_2022;
package body Minimum_Bit_Flips_To_Convert with SPARK_Mode => On is
   use type Byte;
   function Count (Left, Right : Byte) return Flip_Count is
      Difference : constant Byte := Left xor Right;
      Result : Flip_Count := 0;
   begin
      for I in Bit_Index loop
         pragma Loop_Invariant (Result <= I);
         if (Interfaces.Shift_Right (Difference, I) and 1) /= 0 then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count;
end Minimum_Bit_Flips_To_Convert;
