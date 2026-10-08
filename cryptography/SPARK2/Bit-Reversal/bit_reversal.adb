pragma Ada_2022;
package body Bit_Reversal with SPARK_Mode => On is
   use type Interfaces.Unsigned_32;

   function Reverse_Bits (Value : Word) return Word is
      Input : Word := Value;
      Result : Word := 0;
   begin
      for I in 1 .. 32 loop
         Result := Interfaces.Shift_Left (Result, 1) or (Input and 1);
         Input := Interfaces.Shift_Right (Input, 1);
      end loop;
      return Result;
   end Reverse_Bits;
end Bit_Reversal;
